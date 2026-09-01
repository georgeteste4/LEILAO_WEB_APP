<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;
use DOMDocument;
use DOMXPath;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver de extração de alta fidelidade para o Portal Zuk (Zukerman Leilões).
 * URL Base: https://www.portalzuk.com.br
 */
class ZukermanSource implements SourceInterface
{
    private string $slug = 'zukerman';
    private string $nome = 'Portal Zuk (Zukerman)';
    private string $urlBase = 'https://www.portalzuk.com.br';

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
        $uf = strtolower($filtros['uf'] ?? 'sp');
        $pagina = (int)($filtros['pagina'] ?? 1);
        $termo = $filtros['s'] ?? null;
        $tipo = strtolower($filtros['tipo'] ?? '');

        $url = "{$this->urlBase}/leilao-de-imoveis/u/todos-imoveis/{$uf}";
        if ($pagina > 1) {
            $url .= "?pagina={$pagina}";
        }

        $html = $scraper->fetchHtml($url);
        if (!$html) {
            return [
                'success' => false,
                'error' => "Falha ao acessar leilões do Portal Zuk para o estado {$uf}.",
                'data' => [],
                'total' => 0,
                'pagina_atual' => $pagina,
                'total_paginas' => 1,
            ];
        }

        $imoveis = $this->parseZukHtml($html, strtoupper($uf), $filtros);

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
        $html = $scraper->fetchHtml($url);
        if (!$html) {
            return [
                'success' => false,
                'error' => 'Falha ao acessar detalhes do imóvel no Portal Zuk.',
            ];
        }

        $doc = new DOMDocument();
        @$doc->loadHTML('<?xml encoding="UTF-8">' . $html);
        $xpath = new DOMXPath($doc);

        // Procurar matrícula, edital e leiloeiro no HTML do Zuk
        $editalNode = $xpath->query("//a[contains(@href, 'edital') or contains(text(), 'Edital')]");
        $editalUrl = $editalNode->length > 0 ? $editalNode->item(0)->getAttribute('href') : $url;
        if ($editalUrl && !str_starts_with($editalUrl, 'http')) {
            $editalUrl = $this->urlBase . '/' . ltrim($editalUrl, '/');
        }

        $matriculaNode = $xpath->query("//a[contains(@href, 'matricula') or contains(text(), 'Matrícula')]");
        $matriculaUrl = $matriculaNode->length > 0 ? $matriculaNode->item(0)->getAttribute('href') : null;
        if ($matriculaUrl && !str_starts_with($matriculaUrl, 'http')) {
            $matriculaUrl = $this->urlBase . '/' . ltrim($matriculaUrl, '/');
        }

        return [
            'success' => true,
            'data_inclusao' => date('d/m/Y'),
            'edital' => $editalUrl,
            'link_matricula' => $matriculaUrl,
            'numero_matricula' => null,
            'nome_leiloeiro' => 'Zukerman Leilões',
            'link_leiloeiro' => $this->urlBase,
        ];
    }

    private function parseZukHtml(string $html, string $uf, array $filtros): array
    {
        $doc = new DOMDocument();
        @$doc->loadHTML('<?xml encoding="UTF-8">' . $html);
        $xpath = new DOMXPath($doc);

        $imoveis = [];
        $linksEncontrados = [];

        // Extrair todos os links para imóveis no Portal Zuk
        $allLinks = $xpath->query("//a[contains(@href, '/imovel/')]");

        foreach ($allLinks as $a) {
            $href = $a->getAttribute('href');
            if (isset($linksEncontrados[$href])) continue;
            $linksEncontrados[$href] = true;

            // Subir na árvore DOM para pegar o card pai
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

            $cardHtml = $parent ? $doc->saveHTML($parent) : '';
            $cardText = $parent ? trim($parent->textContent) : trim($a->textContent);

            // Título
            $titleNode = $xpath->query(".//h2 | .//h3 | .//h4 | .//p[contains(@class, 'title')]", $parent ?: $a);
            $titulo = $titleNode->length > 0 ? trim($titleNode->item(0)->textContent) : trim($a->textContent);
            if (empty($titulo) || strlen($titulo) < 5) {
                // Tentar extrair do slug da URL
                $parts = explode('/', trim($href, '/'));
                $titulo = ucwords(str_replace('-', ' ', end($parts)));
            }

            // Imagem
            $imgNode = $xpath->query(".//img[@src or @data-src]", $parent ?: $a);
            $imagem = null;
            if ($imgNode->length > 0) {
                $imgEl = $imgNode->item(0);
                $imagem = $imgEl->getAttribute('data-src') ?: $imgEl->getAttribute('src');
            }

            // Cidade / Endereço da URL
            // Ex: https://www.portalzuk.com.br/imovel/sp/piracicaba/vila-sonia/rua-corcovado-4081/36927-230256
            $cidade = 'São Paulo';
            $endereco = 'Consulte detalhes na página';
            if (preg_match('#/imovel/[a-z]{2}/([^/]+)/([^/]+)/([^/]+)/#i', $href, $urlMatches)) {
                $cidade = ucwords(str_replace('-', ' ', $urlMatches[1]));
                $bairro = ucwords(str_replace('-', ' ', $urlMatches[2]));
                $rua = ucwords(str_replace('-', ' ', $urlMatches[3]));
                $endereco = "{$rua} - {$bairro}, {$cidade}/{$uf}";
            }

            // Valores de Avaliação e Leilão (Regex no texto do card)
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

            // Data de Encerramento
            $dataEncerramento = null;
            if (preg_match('/(\d{2}\/\d{2}\/\d{4})/i', $cardText, $dateMatches)) {
                $dataEncerramento = $dateMatches[1];
            }

            // Tipo de Imóvel
            $tipoImovel = 'Imóvel';
            if (stripos($cardText, 'apartamento') !== false || stripos($href, 'apartamento') !== false) $tipoImovel = 'Apartamento';
            elseif (stripos($cardText, 'casa') !== false || stripos($href, 'casa') !== false) $tipoImovel = 'Casa';
            elseif (stripos($cardText, 'terreno') !== false || stripos($href, 'terreno') !== false) $tipoImovel = 'Terreno';
            elseif (stripos($cardText, 'comercial') !== false || stripos($href, 'comercial') !== false) $tipoImovel = 'Comercial';
            elseif (stripos($cardText, 'rural') !== false || stripos($href, 'rural') !== false) $tipoImovel = 'Rural';

            $imoveis[] = [
                'id' => md5($href),
                'hash_imovel' => md5($href),
                'titulo' => mb_substr($titulo, 0, 255),
                'tipo' => $tipoImovel,
                'cidade' => $cidade,
                'uf' => $uf,
                'endereco' => $endereco,
                'valor_avaliacao' => $valorAvaliacao,
                'valor_leilao' => $valorLeilao,
                'desconto' => $desconto,
                'modalidade' => 'Leilão Zukerman',
                'data_encerramento' => $dataEncerramento,
                'data_inclusao' => date('d/m/Y'),
                'edital' => $href,
                'link_matricula' => null,
                'numero_matricula' => null,
                'nome_leiloeiro' => 'Zukerman Leilões',
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
