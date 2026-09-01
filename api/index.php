<?php
declare(strict_types=1);

/**
 * Router principal da API de Leilão de Imóveis.
 * Retorna dados em JSON para o frontend.
 *
 * Endpoints:
 *   GET  ?action=estados             — Lista todos os estados com contagem
 *   GET  ?action=municipios&uf=XX    — Lista municípios de um estado
 *   GET  ?action=imoveis&uf=XX       — Lista imóveis (offline do banco ou online em tempo real)
 *   GET  ?action=detalhes&url=URL    — Ficha técnica completa do imóvel
 *   GET  ?action=filtros_listar      — Lista todos os filtros salvos (Admin)
 *   POST ?action=filtro_salvar       — Cria ou atualiza um filtro salvo (Admin)
 *   POST ?action=filtro_excluir      — Remove um filtro salvo (Admin)
 *   GET  ?action=filtro_executar     — Dispara download de todas as páginas do filtro (Admin)
 *   GET  ?action=dashboard_stats     — Estatísticas do banco leilao_app (Admin)
 *   GET  ?action=logs_cron           — Histórico de execuções do Cron (Admin)
 *   GET  ?action=tokens_status       — Status de saúde dos tokens
 *   GET  ?action=limpar_cache        — Limpa o cache local
 */

// Cabeçalhos CORS e JSON
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Scraper.php';
require_once __DIR__ . '/sources/SourceManager.php';

use App\Sources\SourceManager;

$scraper = new Scraper();
$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    $response = match ($action) {
        'estados' => handleEstados($scraper),
        'municipios' => handleMunicipios($scraper),
        'imoveis' => handleImoveis($scraper),
        'detalhes', 'imovel' => handleDetalhes($scraper),
        'filtros_listar' => handleFiltrosListar(),
        'filtro_salvar' => handleFiltroSalvar(),
        'filtro_excluir' => handleFiltroExcluir(),
        'filtro_executar' => handleFiltroExecutar(),
        'fontes_listar' => handleFontesListar(),
        'fonte_salvar' => handleFonteSalvar(),
        'fonte_toggle' => handleFonteToggle(),
        'fonte_excluir' => handleFonteExcluir(),
        'dashboard_stats' => handleDashboardStats(),
        'logs_cron' => handleLogsCron(),
        'tokens_status' => handleTokensStatus($scraper),
        'tokens_adicionar', 'token_salvar' => handleTokensAdicionar($scraper),
        'tokens_editar', 'token_editar' => handleTokensEditar($scraper),
        'tokens_remover', 'token_remover' => handleTokensRemover($scraper),
        'tokens_testar', 'token_testar' => handleTokensTestar($scraper),
        'tokens_alterar_status', 'token_alterar_status', 'token_toggle' => handleTokensAlterarStatus($scraper),
        'limpar_cache' => handleLimparCache($scraper),
        default => [
            'success' => false,
            'error' => 'Ação inválida. Ações disponíveis: estados, municipios, imoveis, detalhes, filtros_listar, filtro_salvar, filtro_excluir, filtro_executar, fontes_listar, fonte_salvar, fonte_toggle, fonte_excluir, dashboard_stats, logs_cron, tokens_status, tokens_adicionar, tokens_editar, tokens_remover, tokens_testar, tokens_alterar_status, limpar_cache',
        ],
    };
} catch (\Throwable $e) {
    http_response_code(500);
    $response = [
        'success' => false,
        'error' => 'Erro interno do servidor: ' . $e->getMessage(),
    ];
}

echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

// ==================== Handlers da API ====================

function handleEstados(Scraper $scraper): array
{
    $estados = $scraper->getEstados();
    return [
        'success' => true,
        'data' => $estados,
        'total' => count($estados),
    ];
}

function handleMunicipios(Scraper $scraper): array
{
    $uf = $_GET['uf'] ?? '';

    if (empty($uf)) {
        return [
            'success' => false,
            'error' => 'Parâmetro "uf" é obrigatório. Ex: ?action=municipios&uf=MA',
        ];
    }

    $municipios = $scraper->getMunicipios($uf);

    return [
        'success' => true,
        'data' => $municipios,
        'total' => count($municipios),
        'uf' => strtoupper($uf),
    ];
}

/**
 * Busca de Imóveis: Modo Offline (Banco leilao_app) ou Modo Online (Scraping com Auto-Save).
 */
function handleImoveis(Scraper $scraper): array
{
    $uf = $_GET['uf'] ?? '';
    if (empty($uf)) {
        return [
            'success' => false,
            'error' => 'Parâmetro "uf" é obrigatório. Ex: ?action=imoveis&uf=MA',
        ];
    }

    $municipio = $_GET['municipio'] ?? $_GET['municipios'] ?? $_GET['cidades'] ?? null;
    $tipo = $_GET['tipo'] ?? null;
    $pagina = max(1, (int)($_GET['pagina'] ?? $_GET['pag'] ?? 1));
    $dataFinalLeilao = $_GET['data_final_leilao'] ?? null;
    $termoBusca = $_GET['s'] ?? $_GET['busca'] ?? $_GET['q'] ?? null;
    $ordem = $_GET['ordem'] ?? $_GET['sort'] ?? $_GET['order_by'] ?? 'desconto_desc';
    $fonte = $_GET['fonte'] ?? $_GET['fonte_slug'] ?? null;

    // Modo: 'offline' (padrão) ou 'online'
    $origem = strtolower($_GET['origem'] ?? $_GET['modo'] ?? 'offline');

    if ($origem === 'online') {
        // Se uma fonte específica foi pedida, obter o driver
        $driver = (!empty($fonte) && $fonte !== 'todas') ? SourceManager::getDriver($fonte) : null;
        
        $filtros = [
            'uf' => $uf,
            'municipio' => is_string($municipio) && !str_contains($municipio, ',') ? $municipio : null,
            'tipo' => $tipo,
            'pagina' => $pagina,
            'data_final_leilao' => $dataFinalLeilao,
            's' => $termoBusca,
        ];

        if ($driver) {
            $res = $driver->scrapeImoveis($scraper, $filtros);
        } else {
            // Driver padrão do Leilão Imóvel
            $res = $scraper->getImoveis($uf, $filtros['municipio'], $tipo, $pagina, $dataFinalLeilao, $termoBusca);
        }

        if ($res['success'] && !empty($res['data'])) {
            // Upsert automático no banco
            foreach ($res['data'] as $imovel) {
                try {
                    Database::upsertImovel($imovel, null);
                } catch (\Throwable $e) {
                    // Ignora erro individual para não travar a resposta
                }
            }
        }

        $res['origem'] = 'tempo_real_online';
        $res['filtros']['ordem'] = $ordem;
        $res['filtros']['fonte'] = $fonte;
        return $res;
    }

    // Modo Offline: Consulta direta na base de dados leilao_app com multi-municípios, fonte e ordenação
    return Database::getImoveisOffline($uf, $municipio, $tipo, $pagina, $dataFinalLeilao, $termoBusca, $ordem, $fonte);
}

function handleDetalhes(Scraper $scraper): array
{
    $url = $_GET['url'] ?? '';

    if (empty($url)) {
        return [
            'success' => false,
            'error' => 'Parâmetro "url" é obrigatório para detalhes do imóvel.',
        ];
    }

    $hash = md5($url);

    // 1. Tentar obter direto do banco leilao_app se já possuir dados enriquecidos
    try {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM `imoveis` WHERE `hash_imovel` = :hash LIMIT 1");
        $stmt->execute([':hash' => $hash]);
        $imovelDb = $stmt->fetch();

        if ($imovelDb && (!empty($imovelDb['edital']) || !empty($imovelDb['link_matricula']) || !empty($imovelDb['data_inclusao']))) {
            return [
                'success' => true,
                'data_inclusao' => $imovelDb['data_inclusao'],
                'edital' => $imovelDb['edital'],
                'link_matricula' => $imovelDb['link_matricula'],
                'numero_matricula' => $imovelDb['numero_matricula'],
                'link_leiloeiro' => $imovelDb['link_leiloeiro'],
                'nome_leiloeiro' => $imovelDb['nome_leiloeiro'],
                'origem' => 'cache_db',
            ];
        }
    } catch (\Throwable $e) {
        // Prossegue para scraping
    }

    $detalhes = $scraper->getImovelDetalhes($url);

    // Se obteve com sucesso, atualizar na base de dados
    if ($detalhes['success']) {
        try {
            $pdo = Database::getConnection();
            $hash = md5($url);
            $stmt = $pdo->prepare("
                UPDATE `imoveis` SET
                    `data_inclusao` = COALESCE(:data_inclusao, `data_inclusao`),
                    `edital` = COALESCE(:edital, `edital`),
                    `link_matricula` = COALESCE(:link_matricula, `link_matricula`),
                    `numero_matricula` = COALESCE(:numero_matricula, `numero_matricula`),
                    `link_leiloeiro` = COALESCE(:link_leiloeiro, `link_leiloeiro`),
                    `nome_leiloeiro` = COALESCE(:nome_leiloeiro, `nome_leiloeiro`),
                    `atualizado_em` = NOW()
                WHERE `hash_imovel` = :hash
            ");
            $stmt->execute([
                ':data_inclusao' => $detalhes['data_inclusao'],
                ':edital' => $detalhes['edital'],
                ':link_matricula' => $detalhes['link_matricula'],
                ':numero_matricula' => $detalhes['numero_matricula'],
                ':link_leiloeiro' => $detalhes['link_leiloeiro'],
                ':nome_leiloeiro' => $detalhes['nome_leiloeiro'],
                ':hash' => $hash,
            ]);
        } catch (\Throwable $e) {
            // Silencioso
        }
    }

    return $detalhes;
}

// ==================== Handlers Administrativos ====================

function handleFiltrosListar(): array
{
    $pdo = Database::getConnection();
    $stmt = $pdo->query("
        SELECT 
            f.*,
            (SELECT COUNT(*) FROM `imoveis` i WHERE i.`filtro_id` = f.`id`) AS `total_imoveis_banco`
        FROM `filtros_salvos` f
        ORDER BY f.`id` DESC
    ");
    $filtros = $stmt->fetchAll();

    // Obter protocolo e host para gerar links do cron
    $scheme = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost:8000';
    $baseUrl = "{$scheme}://{$host}";

    $filtrosFormatados = array_map(function ($f) use ($baseUrl) {
        $cronUrl = "{$baseUrl}/api/cron.php?filter_id={$f['id']}&token={$f['cron_token']}";
        $cronCli = "php api/cron.php --filter_id={$f['id']}";
        return [
            'id' => (int)$f['id'],
            'nome' => $f['nome'],
            'uf' => strtoupper($f['uf']),
            'municipio' => $f['municipio'],
            'tipo' => $f['tipo'],
            'data_final_leilao' => $f['data_final_leilao'],
            'termo_busca' => $f['termo_busca'],
            'cron_token' => $f['cron_token'],
            'cron_url' => $cronUrl,
            'cron_cli' => $cronCli,
            'cron_exemplo_crontab' => "0 */6 * * * curl -s \"{$cronUrl}\" > /dev/null",
            'ativo' => (bool)$f['ativo'],
            'fontes' => !empty($f['fontes']) ? json_decode($f['fontes'], true) : ['leilaoimovel'],
            'total_execucoes' => (int)$f['total_execucoes'],
            'total_imoveis_salvos' => (int)$f['total_imoveis_banco'],
            'ultima_execucao_em' => $f['ultima_execucao_em'],
            'criado_em' => $f['criado_em'],
        ];
    }, $filtros);

    return [
        'success' => true,
        'data' => $filtrosFormatados,
        'total' => count($filtrosFormatados),
        'cron_all_url' => "{$baseUrl}/api/cron.php?all=1&token=" . CRON_MASTER_TOKEN,
    ];
}

function handleFiltroSalvar(): array
{
    $pdo = Database::getConnection();

    // Suporta input JSON ou POST form
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    $nome = trim($body['nome'] ?? '');
    $uf = strtolower(trim($body['uf'] ?? ''));
    $municipio = !empty($body['municipio']) ? trim($body['municipio']) : null;
    $tipo = !empty($body['tipo']) ? trim($body['tipo']) : null;
    $dataFinal = !empty($body['data_final_leilao']) ? trim($body['data_final_leilao']) : null;
    $termo = !empty($body['termo_busca']) ? trim($body['termo_busca']) : null;
    $fontes = !empty($body['fontes']) ? (is_array($body['fontes']) ? $body['fontes'] : explode(',', (string)$body['fontes'])) : ['leilaoimovel'];
    $fontesJson = json_encode(array_values(array_filter(array_map('trim', $fontes))), JSON_UNESCAPED_UNICODE);
    $id = isset($body['id']) ? (int)$body['id'] : null;

    if (empty($nome) || empty($uf) || strlen($uf) !== 2) {
        return [
            'success' => false,
            'error' => 'Nome do filtro e Estado (UF) são obrigatórios.',
        ];
    }

    $cronToken = bin2hex(random_bytes(16));

    if ($id) {
        $stmt = $pdo->prepare("
            UPDATE `filtros_salvos` SET
                `nome` = :nome,
                `uf` = :uf,
                `municipio` = :municipio,
                `tipo` = :tipo,
                `data_final_leilao` = :data_final,
                `termo_busca` = :termo,
                `fontes` = :fontes,
                `atualizado_em` = NOW()
            WHERE `id` = :id
        ");
        $stmt->execute([
            ':nome' => $nome,
            ':uf' => $uf,
            ':municipio' => $municipio,
            ':tipo' => $tipo,
            ':data_final' => $dataFinal,
            ':termo' => $termo,
            ':fontes' => $fontesJson,
            ':id' => $id,
        ]);
        $filterId = $id;
    } else {
        $stmt = $pdo->prepare("
            INSERT INTO `filtros_salvos` (
                `nome`, `uf`, `municipio`, `tipo`, `data_final_leilao`, `termo_busca`, `fontes`, `cron_token`, `ativo`, `criado_em`
            ) VALUES (
                :nome, :uf, :municipio, :tipo, :data_final, :termo, :fontes, :token, 1, NOW()
            )
        ");
        $stmt->execute([
            ':nome' => $nome,
            ':uf' => $uf,
            ':municipio' => $municipio,
            ':tipo' => $tipo,
            ':data_final' => $dataFinal,
            ':termo' => $termo,
            ':fontes' => $fontesJson,
            ':token' => $cronToken,
        ]);
        $filterId = (int)$pdo->lastInsertId();
    }

    return [
        'success' => true,
        'message' => 'Filtro salvo com sucesso! O link para agendamento em cron foi gerado.',
        'filter_id' => $filterId,
    ];
}

function handleFiltroExcluir(): array
{
    $pdo = Database::getConnection();
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;
    $id = (int)($body['id'] ?? $_GET['id'] ?? 0);

    if ($id <= 0) {
        return ['success' => false, 'error' => 'ID do filtro inválido.'];
    }

    $stmt = $pdo->prepare("DELETE FROM `filtros_salvos` WHERE `id` = :id");
    $stmt->execute([':id' => $id]);

    return [
        'success' => true,
        'message' => "Filtro #{$id} removido com sucesso.",
    ];
}

function handleFiltroExecutar(): array
{
    $filterId = (int)($_GET['filter_id'] ?? $_GET['id'] ?? 0);
    if ($filterId <= 0) {
        return ['success' => false, 'error' => 'ID do filtro inválido.'];
    }

    // Executar via cron interno
    $_GET['filter_id'] = $filterId;
    $_GET['token'] = CRON_MASTER_TOKEN;

    ob_start();
    require __DIR__ . '/cron.php';
    $resStr = ob_get_clean();
    $resJson = json_decode($resStr, true);

    return $resJson ?: ['success' => true, 'output' => $resStr];
}

function handleDashboardStats(): array
{
    $pdo = Database::getConnection();

    $totalImoveis = (int)$pdo->query("SELECT COUNT(*) FROM `imoveis` WHERE `status` = 'ativo'")->fetchColumn();
    $totalFiltros = (int)$pdo->query("SELECT COUNT(*) FROM `filtros_salvos` WHERE `ativo` = 1")->fetchColumn();
    $totalExecucoes = (int)$pdo->query("SELECT COUNT(*) FROM `logs_cron`")->fetchColumn();
    $ultimaExecucao = $pdo->query("SELECT MAX(executado_em) FROM `logs_cron`")->fetchColumn();

    // Contagem por estado
    $porEstado = $pdo->query("
        SELECT `uf`, COUNT(*) AS `total` 
        FROM `imoveis` 
        GROUP BY `uf` 
        ORDER BY `total` DESC 
        LIMIT 10
    ")->fetchAll();

    // Contagem por tipo
    $porTipo = $pdo->query("
        SELECT `tipo`, COUNT(*) AS `total` 
        FROM `imoveis` 
        GROUP BY `tipo` 
        ORDER BY `total` DESC 
        LIMIT 10
    ")->fetchAll();

    return [
        'success' => true,
        'data' => [
            'total_imoveis_banco' => $totalImoveis,
            'total_filtros_salvos' => $totalFiltros,
            'total_execucoes_cron' => $totalExecucoes,
            'ultima_execucao' => $ultimaExecucao ?: 'Nenhuma ainda',
            'imoveis_por_estado' => $porEstado,
            'imoveis_por_tipo' => $porTipo,
        ],
    ];
}

function handleLogsCron(): array
{
    $pdo = Database::getConnection();
    $stmt = $pdo->query("
        SELECT 
            l.*, 
            COALESCE(f.`nome`, 'Filtro Excluído') AS `filtro_nome`
        FROM `logs_cron` l
        LEFT JOIN `filtros_salvos` f ON f.`id` = l.`filtro_id`
        ORDER BY l.`id` DESC 
        LIMIT 50
    ");
    $logs = $stmt->fetchAll();

    return [
        'success' => true,
        'data' => $logs,
        'total' => count($logs),
    ];
}

function handleTokensStatus(Scraper $scraper): array
{
    return [
        'success' => true,
        'data' => $scraper->getTokensStatus(),
    ];
}

function handleTokensAdicionar(Scraper $scraper): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    $provider = $body['provider'] ?? $_GET['provider'] ?? '';
    $token = $body['token'] ?? $_GET['token'] ?? '';

    if (empty($provider) || empty($token)) {
        return [
            'success' => false,
            'error' => 'Parâmetros "provider" (scrape_do ou firecrawl) e "token" são obrigatórios.',
        ];
    }

    return $scraper->getService()->addToken($provider, $token);
}

function handleTokensEditar(Scraper $scraper): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    $provider = $body['provider'] ?? $_GET['provider'] ?? '';
    $oldToken = $body['old_token'] ?? $body['token'] ?? $_GET['old_token'] ?? '';
    $newToken = $body['new_token'] ?? $_GET['new_token'] ?? '';

    if (empty($provider) || empty($oldToken) || empty($newToken)) {
        return [
            'success' => false,
            'error' => 'Parâmetros "provider", "old_token" e "new_token" são obrigatórios.',
        ];
    }

    return $scraper->getService()->editToken($provider, $oldToken, $newToken);
}

function handleTokensRemover(Scraper $scraper): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    $provider = $body['provider'] ?? $_GET['provider'] ?? '';
    $token = $body['token'] ?? $_GET['token'] ?? $body['token_hash'] ?? '';

    if (empty($provider) || empty($token)) {
        return [
            'success' => false,
            'error' => 'Parâmetros "provider" e "token" são obrigatórios.',
        ];
    }

    return $scraper->getService()->removeToken($provider, $token);
}

function handleTokensTestar(Scraper $scraper): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    $provider = $body['provider'] ?? $_GET['provider'] ?? '';
    $token = $body['token'] ?? $_GET['token'] ?? '';

    if (empty($provider) || empty($token)) {
        return [
            'success' => false,
            'error' => 'Parâmetros "provider" e "token" são obrigatórios.',
        ];
    }

    return $scraper->getService()->testToken($provider, $token);
}

function handleTokensAlterarStatus(Scraper $scraper): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    $provider = $body['provider'] ?? $_GET['provider'] ?? '';
    $token = $body['token'] ?? $_GET['token'] ?? $body['token_hash'] ?? '';
    $status = $body['status'] ?? $_GET['status'] ?? 'ativo';

    if (empty($provider) || empty($token)) {
        return [
            'success' => false,
            'error' => 'Parâmetros "provider", "token" e "status" são obrigatórios.',
        ];
    }

    return $scraper->getService()->setTokenState($provider, $token, $status);
}

function handleLimparCache(Scraper $scraper): array
{
    $removidos = $scraper->limparCache();
    return [
        'success' => true,
        'message' => "Cache limpo com sucesso. {$removidos} arquivo(s) removido(s).",
    ];
}

// ==================== Handlers de Fontes de Dados (Multi-Site Hub) ====================

function handleFontesListar(): array
{
    $fontes = Database::getFontes();
    return [
        'success' => true,
        'data' => $fontes,
        'total' => count($fontes),
    ];
}

function handleFonteSalvar(): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;

    return Database::salvarFonte($body);
}

function handleFonteToggle(): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;
    $id = (int)($body['id'] ?? $_GET['id'] ?? 0);
    $ativo = (bool)($body['ativo'] ?? $_GET['ativo'] ?? false);

    if ($id <= 0) {
        return ['success' => false, 'error' => 'ID da fonte inválido.'];
    }

    return Database::toggleFonte($id, $ativo);
}

function handleFonteExcluir(): array
{
    $rawInput = file_get_contents('php://input');
    $body = json_decode($rawInput, true) ?: $_POST;
    $id = (int)($body['id'] ?? $_GET['id'] ?? 0);

    if ($id <= 0) {
        return ['success' => false, 'error' => 'ID da fonte inválido.'];
    }

    return Database::excluirFonte($id);
}
