<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';

/**
 * Serviço de Scraping inteligente com suporte a múltiplos provedores (Scrape.do, Firecrawl),
 * pool de múltiplos tokens por provedor, controle de status manual (Ativar / Pausar / Desativar),
 * failover automático, desativação de tokens sem crédito e cadastro dinâmico de novas chaves de API.
 */
class ScraperService
{
    private string $healthFile;
    private string $customTokensFile;
    private string $tokenStatesFile;
    private array $healthData = [];
    private array $customTokens = [
        'scrape_do' => [],
        'firecrawl' => [],
    ];
    private array $tokenStates = [];

    public function __construct()
    {
        $this->healthFile = TOKEN_HEALTH_FILE;
        $this->customTokensFile = CACHE_DIR . '/custom_tokens.json';
        $this->tokenStatesFile = CACHE_DIR . '/token_states.json';
        $this->loadHealthData();
        $this->loadCustomTokens();
        $this->loadTokenStates();
    }

    /**
     * Carrega os dados de saúde dos tokens do arquivo JSON.
     */
    private function loadHealthData(): void
    {
        if (file_exists($this->healthFile)) {
            $content = file_get_contents($this->healthFile);
            if ($content !== false) {
                $this->healthData = json_decode($content, true) ?: [];
            }
        }
    }

    /**
     * Salva o estado de saúde dos tokens.
     */
    private function saveHealthData(): void
    {
        if (!is_dir(dirname($this->healthFile))) {
            mkdir(dirname($this->healthFile), 0755, true);
        }
        file_put_contents(
            $this->healthFile,
            json_encode($this->healthData, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );
    }

    /**
     * Carrega os estados manuais dos tokens (ativo, pausado, desativado).
     */
    private function loadTokenStates(): void
    {
        if (file_exists($this->tokenStatesFile)) {
            $content = file_get_contents($this->tokenStatesFile);
            if ($content !== false) {
                $this->tokenStates = json_decode($content, true) ?: [];
            }
        }
    }

    /**
     * Salva os estados manuais dos tokens.
     */
    private function saveTokenStates(): void
    {
        if (!is_dir(dirname($this->tokenStatesFile))) {
            mkdir(dirname($this->tokenStatesFile), 0755, true);
        }
        file_put_contents(
            $this->tokenStatesFile,
            json_encode($this->tokenStates, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );
    }

    /**
     * Retorna o estado manual de um token ('ativo', 'pausado', 'desativado').
     */
    public function getTokenState(string $provider, string $token): string
    {
        $key = strtolower($provider) . ':' . md5($token);
        return $this->tokenStates[$key] ?? 'ativo';
    }

    /**
     * Define o estado manual de um token ('ativo', 'pausado', 'desativado').
     */
    public function setTokenState(string $provider, string $tokenOrHash, string $newState): array
    {
        $provider = strtolower(trim($provider));
        $newState = strtolower(trim($newState));
        $realToken = $this->resolveToken($provider, $tokenOrHash);

        if (!in_array($provider, ['scrape_do', 'firecrawl'], true)) {
            return ['success' => false, 'error' => 'Provedor inválido.'];
        }

        if (!in_array($newState, ['ativo', 'pausado', 'desativado'], true)) {
            return ['success' => false, 'error' => 'Estado inválido. Use "ativo", "pausado" ou "desativado".'];
        }

        $key = $provider . ':' . md5($realToken);
        $this->tokenStates[$key] = $newState;
        $this->saveTokenStates();

        // Se o usuário ativou manualmente, limpa qualquer bloqueio temporário anterior
        if ($newState === 'ativo' && isset($this->healthData[$key])) {
            unset($this->healthData[$key]);
            $this->saveHealthData();
        }

        $statusLabels = [
            'ativo' => 'ativada',
            'pausado' => 'pausada',
            'desativado' => 'desativada',
        ];

        return [
            'success' => true,
            'message' => "Chave de {$provider} {$statusLabels[$newState]} com sucesso.",
            'new_state' => $newState,
        ];
    }

    /**
     * Carrega os tokens customizados adicionados pelo usuário via painel.
     */
    private function loadCustomTokens(): void
    {
        if (file_exists($this->customTokensFile)) {
            $content = file_get_contents($this->customTokensFile);
            if ($content !== false) {
                $decoded = json_decode($content, true);
                if (is_array($decoded)) {
                    $this->customTokens['scrape_do'] = $decoded['scrape_do'] ?? [];
                    $this->customTokens['firecrawl'] = $decoded['firecrawl'] ?? [];
                }
            }
        }
    }

    /**
     * Salva os tokens customizados no arquivo JSON persistente.
     */
    private function saveCustomTokens(): void
    {
        if (!is_dir(dirname($this->customTokensFile))) {
            mkdir(dirname($this->customTokensFile), 0755, true);
        }
        file_put_contents(
            $this->customTokensFile,
            json_encode($this->customTokens, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );
    }

    /**
     * Retorna todos os tokens combinados (config.php + custom_tokens.json).
     */
    public function getAllTokens(string $provider): array
    {
        $provider = strtolower($provider);
        $baseTokens = match ($provider) {
            'scrape_do' => SCRAPE_DO_TOKENS,
            'firecrawl' => FIRECRAWL_TOKENS,
            default => [],
        };

        $custom = $this->customTokens[$provider] ?? [];
        $combined = array_unique(array_merge($baseTokens, $custom));
        return array_values(array_filter($combined, fn($t) => !empty(trim((string)$t))));
    }

    /**
     * Resolve um token a partir de seu valor real, hash MD5 ou valor mascarado.
     */
    public function resolveToken(string $provider, string $tokenOrHash): string
    {
        $provider = strtolower(trim($provider));
        $tokenOrHash = trim($tokenOrHash);

        $tokens = $this->getAllTokens($provider);
        foreach ($tokens as $t) {
            if ($t === $tokenOrHash || md5($t) === $tokenOrHash || $this->maskToken($t) === $tokenOrHash) {
                return $t;
            }
        }

        return $tokenOrHash;
    }

    /**
     * Adiciona uma nova chave de API para o provedor especificado.
     */
    public function addToken(string $provider, string $token): array
    {
        $provider = strtolower(trim($provider));
        $token = trim($token);

        if (!in_array($provider, ['scrape_do', 'firecrawl'], true)) {
            return ['success' => false, 'error' => 'Provedor inválido. Escolha "scrape_do" ou "firecrawl".'];
        }

        if (strlen($token) < 10) {
            return ['success' => false, 'error' => 'A chave informada é muito curta ou inválida.'];
        }

        $all = $this->getAllTokens($provider);
        if (in_array($token, $all, true)) {
            return ['success' => false, 'error' => 'Esta chave já está cadastrada no sistema.'];
        }

        $this->customTokens[$provider][] = $token;
        $this->customTokens[$provider] = array_values(array_unique($this->customTokens[$provider]));
        $this->saveCustomTokens();

        // Estado inicial: ativo
        $key = $provider . ':' . md5($token);
        $this->tokenStates[$key] = 'ativo';
        $this->saveTokenStates();

        if (isset($this->healthData[$key])) {
            unset($this->healthData[$key]);
            $this->saveHealthData();
        }

        return [
            'success' => true,
            'message' => "Chave para {$provider} cadastrada e ativada com sucesso.",
            'token_masked' => $this->maskToken($token),
        ];
    }

    /**
     * Edita o valor de uma chave de API existente.
     */
    public function editToken(string $provider, string $oldTokenOrHash, string $newToken): array
    {
        $provider = strtolower(trim($provider));
        $oldTokenOrHash = trim($oldTokenOrHash);
        $newToken = trim($newToken);

        if (!in_array($provider, ['scrape_do', 'firecrawl'], true)) {
            return ['success' => false, 'error' => 'Provedor inválido.'];
        }

        if (strlen($newToken) < 10) {
            return ['success' => false, 'error' => 'A nova chave informada é muito curta ou inválida.'];
        }

        $realOldToken = $this->resolveToken($provider, $oldTokenOrHash);

        // Remover chave antiga de customTokens se existir
        if (isset($this->customTokens[$provider])) {
            $this->customTokens[$provider] = array_values(array_filter(
                $this->customTokens[$provider],
                fn($t) => $t !== $realOldToken && md5($t) !== $oldTokenOrHash
            ));
        }

        // Adicionar nova chave aos customizados
        if (!in_array($newToken, $this->customTokens[$provider] ?? [], true)) {
            $this->customTokens[$provider][] = $newToken;
            $this->customTokens[$provider] = array_values(array_unique($this->customTokens[$provider]));
        }
        $this->saveCustomTokens();

        // Migrar estado
        $oldKey = $provider . ':' . md5($realOldToken);
        $newKey = $provider . ':' . md5($newToken);
        $prevState = $this->tokenStates[$oldKey] ?? 'ativo';
        $this->tokenStates[$newKey] = $prevState;
        if ($oldKey !== $newKey && isset($this->tokenStates[$oldKey])) {
            unset($this->tokenStates[$oldKey]);
        }
        $this->saveTokenStates();

        // Limpar dados de saúde antigos
        if (isset($this->healthData[$oldKey])) {
            unset($this->healthData[$oldKey]);
        }
        if (isset($this->healthData[$newKey])) {
            unset($this->healthData[$newKey]);
        }
        $this->saveHealthData();

        return [
            'success' => true,
            'message' => "Chave de {$provider} atualizada com sucesso.",
            'token_masked' => $this->maskToken($newToken),
        ];
    }

    /**
     * Remove uma chave de API cadastrada.
     */
    public function removeToken(string $provider, string $tokenOrHash): array
    {
        $provider = strtolower(trim($provider));
        $tokenOrHash = trim($tokenOrHash);
        $realToken = $this->resolveToken($provider, $tokenOrHash);

        if (!in_array($provider, ['scrape_do', 'firecrawl'], true)) {
            return ['success' => false, 'error' => 'Provedor inválido.'];
        }

        // Remover dos customizados
        if (isset($this->customTokens[$provider])) {
            $this->customTokens[$provider] = array_values(array_filter(
                $this->customTokens[$provider],
                fn($t) => $t !== $realToken && $t !== $tokenOrHash && md5($t) !== $tokenOrHash
            ));
            $this->saveCustomTokens();
        }

        // Limpar dados de saúde e estados
        $key = $provider . ':' . md5($realToken);
        if (isset($this->healthData[$key])) {
            unset($this->healthData[$key]);
            $this->saveHealthData();
        }
        if (isset($this->tokenStates[$key])) {
            unset($this->tokenStates[$key]);
            $this->saveTokenStates();
        }

        return [
            'success' => true,
            'message' => "Chave de {$provider} removida com sucesso.",
        ];
    }

    /**
     * Testa a validade e saldo de uma chave em tempo real.
     */
    public function testToken(string $provider, string $tokenOrHash): array
    {
        $provider = strtolower(trim($provider));
        $tokenOrHash = trim($tokenOrHash);
        $realToken = $this->resolveToken($provider, $tokenOrHash);
        $testUrl = 'https://httpbin.org/ip';

        $startTime = microtime(true);

        if ($provider === 'scrape_do') {
            $res = $this->fetchWithScrapeDo($testUrl, $realToken);
        } elseif ($provider === 'firecrawl') {
            $res = $this->fetchWithFirecrawl($testUrl, $realToken, 'html');
        } else {
            return ['success' => false, 'error' => 'Provedor inválido.'];
        }

        $latency = round((microtime(true) - $startTime) * 1000, 1);

        if ($res['success']) {
            return [
                'success' => true,
                'message' => "Chave válida e funcional! Conexão realizada em {$latency}ms.",
                'latency_ms' => $latency,
                'http_code' => $res['http_code'] ?? 200,
            ];
        }

        return [
            'success' => false,
            'error' => "Falha na validação da chave ({$res['error']}). HTTP " . ($res['http_code'] ?? 'N/A'),
            'http_code' => $res['http_code'] ?? 0,
            'latency_ms' => $latency,
        ];
    }

    /**
     * Verifica se um token específico está desativado (ex: sem créditos).
     */
    private function isTokenDisabled(string $provider, string $token): bool
    {
        $key = $provider . ':' . md5($token);
        if (isset($this->healthData[$key])) {
            $disabledUntil = $this->healthData[$key]['disabled_until'] ?? 0;
            if (time() < $disabledUntil) {
                return true;
            }
            unset($this->healthData[$key]);
            $this->saveHealthData();
        }
        return false;
    }

    /**
     * Desativa um token por um período determinado quando ele fica sem crédito ou falha.
     */
    private function disableToken(string $provider, string $token, string $reason, int $httpCode): void
    {
        $key = $provider . ':' . md5($token);
        $maskedToken = $this->maskToken($token);
        
        $this->healthData[$key] = [
            'provider' => $provider,
            'token_masked' => $maskedToken,
            'disabled_at' => date('Y-m-d H:i:s'),
            'disabled_until' => time() + TOKEN_DISABLE_TIME,
            'reason' => $reason,
            'http_code' => $httpCode,
        ];
        
        $this->saveHealthData();
        error_log("ScraperService: Token [{$maskedToken}] do provedor [{$provider}] desativado. Motivo: {$reason} (HTTP {$httpCode})");
    }

    /**
     * Mascara o token para exibição segura.
     */
    private function maskToken(string $token): string
    {
        if (strlen($token) <= 10) {
            return substr($token, 0, 3) . '***';
        }
        return substr($token, 0, 6) . '...' . substr($token, -4);
    }

    /**
     * Retorna o status de todos os tokens cadastrados.
     */
    public function getTokensStatus(): array
    {
        $status = [
            'scrape_do' => [],
            'firecrawl' => [],
        ];

        foreach (['scrape_do', 'firecrawl'] as $provider) {
            $tokens = $this->getAllTokens($provider);
            $customTokens = $this->customTokens[$provider] ?? [];

            foreach ($tokens as $token) {
                $key = $provider . ':' . md5($token);
                $state = $this->getTokenState($provider, $token);
                $isTempDisabled = $this->isTokenDisabled($provider, $token);
                $isCustom = in_array($token, $customTokens, true);

                $details = match ($state) {
                    'pausado' => 'Pausado pelo usuário',
                    'desativado' => 'Desativado pelo usuário',
                    default => $isTempDisabled ? ($this->healthData[$key]['reason'] ?? 'Bloqueado temporariamente') : 'Operacional',
                };

                $status[$provider][] = [
                    'token' => $this->maskToken($token),
                    'token_full' => $token,
                    'token_hash' => md5($token),
                    'status' => $state,
                    'active' => ($state === 'ativo' && !$isTempDisabled),
                    'is_custom' => $isCustom,
                    'details' => $details,
                ];
            }
        }

        return $status;
    }

    /**
     * Executa a requisição buscando a página através da cascata de provedores e tokens.
     */
    public function fetch(string $url, string $format = 'html'): array
    {
        $errors = [];

        foreach (PROVIDER_PRIORITY as $provider) {
            $tokens = $this->getAllTokens($provider);

            if ($provider === 'scrape_do') {
                foreach ($tokens as $token) {
                    $state = $this->getTokenState('scrape_do', $token);
                    // Ignorar se estiver pausado, desativado ou sem créditos
                    if ($state !== 'ativo' || $this->isTokenDisabled('scrape_do', $token)) {
                        continue;
                    }

                    $res = $this->fetchWithScrapeDo($url, $token);
                    if ($res['success']) {
                        return [
                            'success' => true,
                            'content' => $res['content'],
                            'provider' => 'scrape_do',
                            'error' => null,
                        ];
                    }

                    $errors[] = "Scrape.do (token " . $this->maskToken($token) . "): " . $res['error'];

                    if (in_array($res['http_code'], [401, 402, 429, 403])) {
                        $this->disableToken('scrape_do', $token, $res['error'], $res['http_code']);
                    }
                }
            } elseif ($provider === 'firecrawl') {
                foreach ($tokens as $token) {
                    $state = $this->getTokenState('firecrawl', $token);
                    // Ignorar se estiver pausado, desativado ou sem créditos
                    if ($state !== 'ativo' || $this->isTokenDisabled('firecrawl', $token)) {
                        continue;
                    }

                    $res = $this->fetchWithFirecrawl($url, $token, $format);
                    if ($res['success']) {
                        return [
                            'success' => true,
                            'content' => $res['content'],
                            'provider' => 'firecrawl',
                            'error' => null,
                        ];
                    }

                    $errors[] = "Firecrawl (token " . $this->maskToken($token) . "): " . $res['error'];

                    if (in_array($res['http_code'], [401, 402, 429, 403])) {
                        $this->disableToken('firecrawl', $token, $res['error'], $res['http_code']);
                    }
                }
            }
        }

        return [
            'success' => false,
            'content' => '',
            'provider' => null,
            'error' => 'Todos os provedores e tokens falharam. Detalhes: ' . implode(' | ', $errors),
        ];
    }

    /**
     * Requisição via Scrape.do API.
     */
    private function fetchWithScrapeDo(string $url, string $token): array
    {
        $apiUrl = 'https://api.scrape.do?token=' . urlencode($token) . '&url=' . urlencode($url);

        $ch = curl_init($apiUrl);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => SCRAPER_TIMEOUT,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_ENCODING => '',
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($response === false || $httpCode !== 200) {
            $msg = $error ?: "HTTP $httpCode";
            if ($httpCode === 401 || $httpCode === 402) {
                $msg = "Sem créditos ou token inválido ($httpCode)";
            } elseif ($httpCode === 429) {
                $msg = "Limite de requisições excedido ($httpCode)";
            }
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => $msg,
                'content' => '',
            ];
        }

        return [
            'success' => true,
            'http_code' => $httpCode,
            'error' => '',
            'content' => (string)$response,
        ];
    }

    /**
     * Requisição via Firecrawl API.
     */
    private function fetchWithFirecrawl(string $url, string $token, string $format = 'html'): array
    {
        $apiUrl = 'https://api.firecrawl.dev/v1/scrape';

        $payload = json_encode([
            'url' => $url,
            'formats' => [$format === 'json' ? 'html' : $format],
            'onlyMainContent' => false,
        ]);

        $ch = curl_init($apiUrl);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $token,
            ],
            CURLOPT_TIMEOUT => SCRAPER_TIMEOUT,
            CURLOPT_CONNECTTIMEOUT => 15,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_ENCODING => '',
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($response === false || $httpCode !== 200) {
            $msg = $error ?: "HTTP $httpCode";
            if ($httpCode === 401 || $httpCode === 402) {
                $msg = "Sem créditos ou token inválido ($httpCode)";
            } elseif ($httpCode === 429) {
                $msg = "Limite de requisições excedido ($httpCode)";
            }
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => $msg,
                'content' => '',
            ];
        }

        $json = json_decode((string)$response, true);
        if (!$json || !isset($json['success']) || !$json['success']) {
            return [
                'success' => false,
                'http_code' => $httpCode,
                'error' => $json['error'] ?? 'Resposta inválida do Firecrawl',
                'content' => '',
            ];
        }

        $content = $json['data']['html'] ?? $json['data']['markdown'] ?? '';

        return [
            'success' => true,
            'http_code' => $httpCode,
            'error' => '',
            'content' => $content,
        ];
    }
}
