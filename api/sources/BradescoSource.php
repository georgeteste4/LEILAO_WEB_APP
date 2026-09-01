<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;
use DOMDocument;
use DOMXPath;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver Especializado de Extração para o Banco Bradesco (Leilões e Imóveis Retomados).
 * URL Base: https://www.bradescoimoveis.com.br
 */
class BradescoSource implements SourceInterface
{
    private string $slug = 'bradesco';
    private string $nome = 'Banco Bradesco (Imóveis & Leilões)';
    private string $urlBase = 'https://www.bradescoimoveis.com.br';
    private string $channelUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-bradesco';

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
        $pagina = (int)($filtros['pagina'] ?? 1);
        $termo = strtolower($filtros['s'] ?? '');
        $tipo = strtolower($filtros['tipo'] ?? '');

        // 1. Tentar buscar no canal do vendedor Bradesco
        $targetUrl = $this->channelUrl;
        if ($pagina > 1) {
            $targetUrl .= "?pagina={$pagina}";
        }

        $html = $scraper->fetchHtml($targetUrl);
        $imoveis = [];

        if ($html && strlen($html) > 200) {
            $imoveis = $this->parseBradescoHtml($html, $uf, $filtros);
        }

        // 2. Se a busca por canal não tiver imóveis na UF solicitada, consultar também a listagem de leilões do estado
        if (empty($imoveis) && !empty($uf)) {
            $ufLower = strtolower($uf);
            $urlEstado = "https://www.portalzuk.com.br/leilao-de-imoveis/u/todos-imoveis/{$ufLower}";
            if ($pagina > 1) $urlEstado .= "?pagina={$pagina}";
            
            $htmlEstado = $scraper->fetchHtml($urlEstado);
            if ($htmlEstado && strlen($htmlEstado) > 200) {
                $imoveisEstado = $this->parseBradescoHtml($htmlEstado, $uf, $filtros, true);
                $imoveis = array_merge($imoveis, $imoveisEstado);
            }
        }

        return [
            'success' => true,
            'data' => $imoveis,
            'total' => count($imoveis),
            'pagina_atual' => $pagina,
            'total_paginas' => 1,
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
            'nome_leiloeiro' => 'Banco Bradesco',
            'link_leiloeiro' => $this->urlBase,
        ];
    }

    private function parseBradescoHtml(string $html, string $targetUf, array $filtros, bool $filterByBankInText = false): array
    {
        $doc = new DOMDocument();
        @$doc->loadHTML('<?xml encoding="UTF-8">' . $html);
        $xpath = new DOMXPath($doc);

        $imoveis = [];
        $linksEncontrados = [];

        $allLinks = $xpath->query("//a[contains(@href, '/imovel/')]");

        foreach ($allLinks as $a) {
            $href = $a->getAttribute('href');
            if (empty($href) || isset($linksEncontrados[$href])) continue;
            if (!str_starts_with($href, 'http')) {
                $href = 'https://www.portalzuk.com.br/' . ltrim($href, '/');
            }
            $linksEncontrados[$href] = true;

            // Extrair UF do link
            $cardUf = '';
            $cidade = 'São Luís';
            $endereco = 'Consulte o edital Bradesco';

            if (preg_match('#/imovel/([a-z]{2})/([^/]+)/([^/]+)/([^/]+)/#i', $href, $urlMatches)) {
                $cardUf = strtoupper($urlMatches[1]);
                $cidade = ucwords(str_replace('-', ' ', $urlMatches[2]));
                $bairro = ucwords(str_replace('-', ' ', $urlMatches[3]));
                $rua = ucwords(str_replace('-', ' ', $urlMatches[4]));
                $endereco = "{$rua} - {$bairro}, {$cidade}/{$cardUf}";
            }

            // FILTRAGEM RIGOROSA DE UF: Descartar se não pertencer ao estado pesquisado
            if (!empty($targetUf) && $cardUf !== $targetUf) {
                continue;
            }

            $parent = $a;
            for ($k = 0; $k < 6; $k++) {
                if (!$parent->parentNode) break;
                $parent = $parent->parentNode;
                if ($parent->nodeType === XML_ELEMENT_NODE) {
                    $class = $parent->getAttribute('class');
                    if (str_contains($class, 'card') || str_contains($class, 'item') || str_contains($class, 'col-')) {
                        break;
                    }
                }
            }

            $cardText = $parent ? trim($parent->textContent) : trim($a->textContent);

            // Se for busca na listagem do estado, verificar se pertence ao Bradesco
            if ($filterByBankInText) {
                if (stripos($cardText, 'bradesco') === false && stripos($href, 'bradesco') === false) {
                    continue;
                }
            }

            // Imagem
            $imgNode = $xpath->query(".//img[@src or @data-src]", $parent ?: $a);
            $imagem = null;
            if ($imgNode->length > 0) {
                $imgEl = $imgNode->item(0);
                $imagem = $imgEl->getAttribute('data-src') ?: $imgEl->getAttribute('src');
            }

            // Tipo de Imóvel
            $tipoImovel = 'Imóvel';
            if (stripos($cardText, 'apartamento') !== false || stripos($href, 'apartamento') !== false) $tipoImovel = 'Apartamento';
            elseif (stripos($cardText, 'casa') !== false || stripos($href, 'casa') !== false) $tipoImovel = 'Casa';
            elseif (stripos($cardText, 'terreno') !== false || stripos($href, 'terreno') !== false) $tipoImovel = 'Terreno';
            elseif (stripos($cardText, 'comercial') !== false || stripos($href, 'comercial') !== false) $tipoImovel = 'Comercial';
            elseif (stripos($cardText, 'rural') !== false || stripos($href, 'rural') !== false) $tipoImovel = 'Rural';

            $titulo = "{$tipoImovel} Banco Bradesco em {$cidade}/{$cardUf}";
            $titleNode = $xpath->query(".//h2 | .//h3 | .//h4 | .//p[contains(@class, 'title')]", $parent ?: $a);
            if ($titleNode->length > 0 && strlen(trim($titleNode->item(0)->textContent)) > 5) {
                $titulo = trim($titleNode->item(0)->textContent);
            }

            // Valores de Avaliação e Lance
            $valorAvaliacao = null;
            $valorLeilao = null;
            $desconto = null;

            if (preg_match_all('/R\$\s*([\d\.,]+)/i', $cardText, $priceMatches)) {
                $prices = [];
                foreach ($priceMatches[1] as $pStr) {
                    $pClean = (float)str_replace(['.', ','], ['', '.'], $pStr);
                    if ($pClean > 1000) {
                        $prices[] = $pClean;
                    }
                }
                if (!empty($prices)) {
                    sort($prices);
                    $valorLeilao = $prices[0];
                    if (count($prices) > 1) {
                        $valorAvaliacao = end($prices);
                        if ($valorAvaliacao > $valorLeilao) {
                            $desconto = round((($valorAvaliacao - $valorLeilao) / $valorAvaliacao) * 100, 2);
                        }
                    }
                }
            }

            $imoveis[] = [
                'id' => md5($href),
                'hash_imovel' => md5($href),
                'titulo' => mb_substr($titulo, 0, 255),
                'tipo' => $tipoImovel,
                'cidade' => $cidade,
                'uf' => $cardUf,
                'endereco' => $endereco,
                'valor_avaliacao' => $valorAvaliacao,
                'valor_leilao' => $valorLeilao,
                'desconto' => $desconto,
                'modalidade' => 'Leilão Oficial Bradesco',
                'data_encerramento' => 'Consulte edital Bradesco',
                'data_inclusao' => date('d/m/Y'),
                'edital' => $href,
                'link_matricula' => $href,
                'numero_matricula' => null,
                'nome_leiloeiro' => 'Banco Bradesco',
                'link_leiloeiro' => $this->urlBase,
                'link' => $href,
                'imagem' => $imagem,
                'fonte_slug' => $this->slug,
                'fonte_nome' => $this->nome,
            ];
        }

        return $imoveis;
    }
}
