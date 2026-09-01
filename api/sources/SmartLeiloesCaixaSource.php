<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver Especializado de Extração em Tempo Real para o Smart Leilões Caixa (smartleiloescaixa.com.br).
 * Consome a API estruturada de alta performance com dados geolocalizados e galeria de fotos.
 */
class SmartLeiloesCaixaSource implements SourceInterface
{
    private string $slug = 'smartleiloescaixa';
    private string $nome = 'Smart Leilões Caixa';
    private string $urlBase = 'https://smartleiloescaixa.com.br';
    private string $apiUrl = 'https://api-dot-site-smart-leiloes.rj.r.appspot.com/api/imovel/busca';

    public function getSlug(): string
    {
        return $this->slug;
    }

    public function getNome(): string
    {
        return $this->nome;
    }

    public function getUrlBase(): string
    {
        return $this->urlBase;
    }

    public function scrapeImoveis(Scraper $scraper, array $filtros): array
    {
        $uf = strtoupper($filtros['uf'] ?? 'MA');
        $municipio = $filtros['municipio'] ?? null;
        $tipo = strtolower($filtros['tipo'] ?? '');
        $pagina = (int)($filtros['pagina'] ?? 1);
        $termo = strtolower($filtros['s'] ?? '');
        $limit = 20;

        $payload = [
            'page' => $pagina,
            'limit' => $limit,
            'uf' => $uf,
        ];

        // Realizar request POST na API do Smart Leilões Caixa
        $ch = curl_init();
        
        // Obter URL do proxy Scrape.do se configurado
        $tokens = defined('SCRAPE_DO_TOKENS') ? SCRAPE_DO_TOKENS : [];
        $token = $tokens[0] ?? '';
        
        $target = !empty($token) 
            ? "http://api.scrape.do/?token={$token}&url=" . urlencode($this->apiUrl)
            : $this->apiUrl;

        curl_setopt_array($ch, [
            CURLOPT_URL => $target,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($payload),
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Accept: application/json'
            ],
            CURLOPT_TIMEOUT => 25,
        ]);

        $rawResponse = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if (!$rawResponse || !in_array($httpCode, [200, 201])) {
            return [
                'success' => false,
                'error' => "Falha ao consultar API do Smart Leilões Caixa (HTTP {$httpCode}).",
                'data' => [],
                'total' => 0,
                'pagina_atual' => $pagina,
                'total_paginas' => 1,
            ];
        }

        $json = json_decode($rawResponse, true);
        $records = $json['records'] ?? $json['data'] ?? [];

        // Parse e normalização com filtragem ESTRITA de UF
        $todosImoveis = [];
        foreach ($records as $r) {
            $estadoRegistro = strtoupper(trim($r['estado'] ?? ''));
            // Descartar registros que não sejam da UF solicitada
            if (!empty($uf) && $estadoRegistro !== $uf) {
                continue;
            }

            $imovel = $this->parseRecord($r, $uf);
            if ($imovel && strtoupper($imovel['uf']) === $uf) {
                $todosImoveis[] = $imovel;
            }
        }

        if (!empty($municipio)) {
            $munList = is_array($municipio) ? $municipio : explode(',', (string)$municipio);
            $munList = array_map(fn($m) => strtolower(trim(str_replace('-', ' ', $m))), $munList);
            $todosImoveis = array_values(array_filter($todosImoveis, function ($item) use ($munList) {
                $cidade = strtolower($item['cidade']);
                foreach ($munList as $m) {
                    if (str_contains($cidade, $m) || str_contains($m, $cidade)) return true;
                }
                return false;
            }));
        }

        if (!empty($tipo)) {
            $todosImoveis = array_values(array_filter($todosImoveis, function ($item) use ($tipo) {
                return stripos($item['tipo'], $tipo) !== false || stripos($item['titulo'], $tipo) !== false;
            }));
        }

        if (!empty($termo)) {
            $todosImoveis = array_values(array_filter($todosImoveis, function ($item) use ($termo) {
                return stripos($item['titulo'], $termo) !== false || 
                       stripos($item['endereco'], $termo) !== false || 
                       stripos($item['cidade'], $termo) !== false ||
                       stripos($item['numero_matricula'] ?? '', $termo) !== false;
            }));
        }

        $total = count($todosImoveis);
        $totalPages = max(1, (int)ceil($total / $limit));
        $offset = ($pagina - 1) * $limit;
        $paginated = array_slice($todosImoveis, $offset, $limit);

        return [
            'success' => true,
            'data' => $paginated,
            'total' => $total,
            'pagina_atual' => $pagina,
            'total_paginas' => $totalPages,
            'fonte_slug' => $this->slug,
            'fonte_nome' => $this->nome,
        ];
    }

    public function scrapeDetalhes(Scraper $scraper, string $url): array
    {
        return [
            'success' => true,
            'data_inclusao' => date('d/m/Y'),
            'edital' => $url,
            'link_matricula' => $url,
            'numero_matricula' => null,
            'nome_leiloeiro' => 'Smart Leilões Caixa',
            'link_leiloeiro' => $this->urlBase,
        ];
    }

    private function parseRecord(array $r, string $defaultUf): ?array
    {
        $idImovel = $r['_id'] ?? $r['hdnImovel'] ?? null;
        if (!$idImovel) return null;

        $cidade = trim($r['cidade'] ?? '');
        $uf = strtoupper(trim($r['estado'] ?? $defaultUf));
        $bairro = trim($r['bairro'] ?? '');
        $endereco = trim($r['endereco'] ?? '');
        $tipoImovel = trim($r['tipoImovel'] ?? 'Imóvel');
        $matricula = trim((string)($r['hdnImovel'] ?? ''));

        $valorAvaliacao = isset($r['precoAvaliacao']) ? (float)$r['precoAvaliacao'] : null;
        $valorLeilao = isset($r['precoVenda']) ? (float)$r['precoVenda'] : null;
        $desconto = isset($r['desconto']) ? (float)$r['desconto'] : null;

        if ($valorAvaliacao > $valorLeilao && $valorAvaliacao > 0 && ($desconto === null || $desconto <= 0)) {
            $desconto = round((($valorAvaliacao - $valorLeilao) / $valorAvaliacao) * 100, 2);
        }

        // Imagem principal do Google Cloud Storage
        $imagem = null;
        if (!empty($r['imagens']) && is_array($r['imagens'])) {
            $firstImg = $r['imagens'][0]['fileReference'] ?? $r['imagens'][0]['filename'] ?? null;
            if ($firstImg) {
                $imagem = "https://storage.googleapis.com/imagens-imoveis-smart-leiloes/{$firstImg}";
            }
        }

        $linkCaixa = $r['siteLeiloeiro'] ?? "https://venda-imoveis.caixa.gov.br/sistema/detalhe-imovel.asp?hdnOrigem=index&hdnimovel={$matricula}";
        $titulo = "{$tipoImovel} em {$cidade}/{$uf}" . ($bairro ? " - {$bairro}" : '') . ($matricula ? " (Matrícula {$matricula})" : '');

        // Formatação de data de encerramento
        $dataEncerramento = 'Consulte o leilão';
        if (!empty($r['datasConcorrencia']['leilao_unico']['data_fim'])) {
            $df = $r['datasConcorrencia']['leilao_unico']['data_fim'];
            $timestamp = strtotime($df);
            if ($timestamp) {
                $dataEncerramento = date('d/m/Y H:i', $timestamp);
            }
        }

        return [
            'id' => md5($linkCaixa . $idImovel),
            'hash_imovel' => md5($linkCaixa . $idImovel),
            'titulo' => mb_substr($titulo, 0, 255),
            'tipo' => $tipoImovel,
            'cidade' => mb_convert_case(mb_strtolower($cidade), MB_CASE_TITLE, 'UTF-8'),
            'uf' => $uf,
            'endereco' => $endereco,
            'valor_avaliacao' => $valorAvaliacao,
            'valor_leilao' => $valorLeilao,
            'desconto' => $desconto,
            'modalidade' => trim($r['modoVenda'] ?? 'Leilão Smart Caixa'),
            'data_encerramento' => $dataEncerramento,
            'data_inclusao' => !empty($r['dataInsercao']) ? date('d/m/Y', strtotime($r['dataInsercao'])) : date('d/m/Y'),
            'edital' => $linkCaixa,
            'link_matricula' => $linkCaixa,
            'numero_matricula' => $matricula ?: null,
            'nome_leiloeiro' => 'Smart Leilões Caixa',
            'link_leiloeiro' => $this->urlBase,
            'link' => $linkCaixa,
            'imagem' => $imagem,
            'fonte_slug' => $this->slug,
            'fonte_nome' => $this->nome,
        ];
    }
}
