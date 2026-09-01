<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver de extração de alta performance para a Caixa Econômica Federal.
 * Processa a base de dados oficial e enriquecida de leilões e vendas online da Caixa.
 * URL Base: https://venda-imoveis.caixa.gov.br
 */
class CaixaSource implements SourceInterface
{
    private string $slug = 'caixa';
    private string $nome = 'Caixa Econômica Federal';
    private string $urlBase = 'https://venda-imoveis.caixa.gov.br';

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

        $urlCsv = "{$this->urlBase}/listaweb/Lista_imoveis_{$uf}.csv";
        $csvContent = $scraper->fetchHtml($urlCsv);

        if (!$csvContent || strlen($csvContent) < 100) {
            return [
                'success' => false,
                'error' => "Não foi possível baixar os dados da Caixa para o estado {$uf}.",
                'data' => [],
                'total' => 0,
                'pagina_atual' => $pagina,
                'total_paginas' => 1,
            ];
        }

        $todosImoveis = $this->parseCaixaCsv($csvContent, $uf);

        // Aplicar filtros de município, tipo e busca
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
            'nome_leiloeiro' => 'Caixa Econômica Federal',
            'link_leiloeiro' => $this->urlBase,
        ];
    }

    private function parseCaixaCsv(string $csv, string $uf): array
    {
        // Converter de ISO-8859-1 para UTF-8 se necessário
        if (!mb_check_encoding($csv, 'UTF-8')) {
            $csv = mb_convert_encoding($csv, 'UTF-8', 'ISO-8859-1, WINDOWS-1252, ISO-8859-15');
        }

        $lines = explode("\n", $csv);
        $imoveis = [];
        $headerFound = false;

        foreach ($lines as $line) {
            $line = trim($line);
            if (empty($line)) continue;

            $cols = str_getcsv($line, ';', '"', '\\');
            if (count($cols) < 8) continue;

            // Detectar linha de cabeçalho
            if (stripos($cols[0], 'imóvel') !== false || stripos($cols[0], 'imovel') !== false || stripos($cols[1], 'UF') !== false) {
                $headerFound = true;
                continue;
            }

            if (!$headerFound && !is_numeric(trim($cols[0]))) {
                continue;
            }

            $numImovel = trim($cols[0] ?? '');
            $ufCol = trim($cols[1] ?? $uf);
            $cidade = trim($cols[2] ?? '');
            $bairro = trim($cols[3] ?? '');
            $endereco = trim($cols[4] ?? '');
            $precoRaw = trim($cols[5] ?? '0');
            $avaliacaoRaw = trim($cols[6] ?? '0');
            $descontoRaw = trim($cols[7] ?? '0');
            $descricao = trim($cols[9] ?? '');
            $modalidade = trim($cols[10] ?? 'Leilão Caixa');
            $linkOriginal = trim($cols[11] ?? '');

            if (empty($numImovel) || empty($cidade) || !is_numeric($numImovel)) continue;

            // Converter valores
            $valorLeilao = (float)str_replace(['.', ','], ['', '.'], $precoRaw);
            $valorAvaliacao = (float)str_replace(['.', ','], ['', '.'], $avaliacaoRaw);
            
            // Cálculo preciso de desconto
            $desconto = null;
            if ($valorAvaliacao > $valorLeilao && $valorAvaliacao > 0) {
                $desconto = round((($valorAvaliacao - $valorLeilao) / $valorAvaliacao) * 100, 2);
            } elseif (!empty($descontoRaw)) {
                $d = (float)str_replace(['.', ','], ['', '.'], $descontoRaw);
                $desconto = $d > 100 ? round($d / 100, 2) : $d;
            }

            // Detectar Tipo de Imóvel
            $tipoImovel = 'Imóvel';
            if (stripos($descricao, 'apartamento') !== false) $tipoImovel = 'Apartamento';
            elseif (stripos($descricao, 'casa') !== false) $tipoImovel = 'Casa';
            elseif (stripos($descricao, 'terreno') !== false) $tipoImovel = 'Terreno';
            elseif (stripos($descricao, 'comercial') !== false || stripos($descricao, 'sala') !== false) $tipoImovel = 'Comercial';
            elseif (stripos($descricao, 'galpão') !== false || stripos($descricao, 'galpao') !== false) $tipoImovel = 'Galpão';
            elseif (stripos($descricao, 'rural') !== false) $tipoImovel = 'Rural';

            $titulo = "{$tipoImovel} Caixa em {$cidade}/{$ufCol} - Matrícula {$numImovel}";
            if (!empty($descricao)) {
                $titulo = mb_substr($descricao . " - {$cidade}/{$ufCol}", 0, 255);
            }

            if (empty($linkOriginal)) {
                $linkOriginal = "{$this->urlBase}/sistema/detalhe-imovel.asp?hdnID={$numImovel}";
            }

            $imoveis[] = [
                'id' => md5($linkOriginal),
                'hash_imovel' => md5($linkOriginal),
                'titulo' => $titulo,
                'tipo' => $tipoImovel,
                'cidade' => mb_convert_case(mb_strtolower($cidade), MB_CASE_TITLE, 'UTF-8'),
                'uf' => strtoupper($ufCol),
                'endereco' => $endereco . ($bairro ? " - Bairro {$bairro}" : ''),
                'valor_avaliacao' => $valorAvaliacao > 0 ? $valorAvaliacao : null,
                'valor_leilao' => $valorLeilao > 0 ? $valorLeilao : null,
                'desconto' => $desconto > 0 ? $desconto : null,
                'modalidade' => $modalidade ?: 'Venda Direta / Leilão Caixa',
                'data_encerramento' => 'Consulte edital Caixa',
                'data_inclusao' => date('d/m/Y'),
                'edital' => $linkOriginal,
                'link_matricula' => $linkOriginal,
                'numero_matricula' => $numImovel,
                'nome_leiloeiro' => 'Caixa Econômica Federal',
                'link_leiloeiro' => $this->urlBase,
                'link' => $linkOriginal,
                'imagem' => null,
                'fonte_slug' => $this->slug,
                'fonte_nome' => $this->nome,
            ];
        }

        return $imoveis;
    }
}
