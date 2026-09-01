<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;
use DOMDocument;
use DOMXPath;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver Genérico para novas fontes de leilões.
 * Permite cadastrar qualquer portal de leilão fornecendo URL base, endpoints e seletores configuráveis.
 */
class GenericSource implements SourceInterface
{
    private string $slug;
    private string $nome;
    private string $urlBase;
    private array $config;

    public function __construct(string $slug, string $nome, string $urlBase, array $config = [])
    {
        $this->slug = $slug;
        $this->nome = $nome;
        $this->urlBase = rtrim($urlBase, '/');
        $this->config = $config;
    }

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
        $uf = strtolower($filtros['uf'] ?? 'ma');
        $pagina = (int)($filtros['pagina'] ?? 1);
        $termo = $filtros['s'] ?? '';

        // Montar URL da fonte genérica ou usar template configurado
        $urlTemplate = $this->config['url_listagem'] ?? ($this->urlBase . '/imoveis/{uf}?pagina={pagina}');
        $targetUrl = str_replace(
            ['{uf}', '{pagina}', '{busca}'],
            [urlencode($uf), $pagina, urlencode($termo)],
            $urlTemplate
        );

        $html = $scraper->fetchHtml($targetUrl);
        if (!$html) {
            return [
                'success' => false,
                'error' => "Não foi possível extrair dados da fonte {$this->nome}.",
                'data' => [],
                'total' => 0,
                'pagina_atual' => $pagina,
                'total_paginas' => 1,
            ];
        }

        // Fazer parse do HTML
        $imoveis = $this->parseHtml($html);

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
                'error' => "Falha ao acessar detalhes na fonte {$this->nome}.",
            ];
        }

        return [
            'success' => true,
            'data_inclusao' => date('d/m/Y'),
            'edital' => $url,
            'link_matricula' => null,
            'numero_matricula' => null,
            'nome_leiloeiro' => $this->nome,
            'link_leiloeiro' => $this->urlBase,
        ];
    }

    private function parseHtml(string $html): array
    {
        $doc = new DOMDocument();
        @$doc->loadHTML('<?xml encoding="UTF-8">' . $html);
        $xpath = new DOMXPath($doc);

        $imoveis = [];

        // Seletores configurados ou fallback padrão
        $cardQuery = $this->config['card_selector'] ?? "//div[contains(@class, 'card') or contains(@class, 'place-box') or contains(@class, 'item') or contains(@class, 'imovel')]";
        $nodes = $xpath->query($cardQuery);

        if ($nodes && $nodes->length > 0) {
            foreach ($nodes as $node) {
                $itemHtml = $doc->saveHTML($node);
                $titleNodes = $xpath->query(".//h2 | .//h3 | .//a[contains(@class, 'title')]", $node);
                $titulo = $titleNodes->length > 0 ? trim($titleNodes->item(0)->textContent) : 'Imóvel em Leilão';

                $linkNodes = $xpath->query(".//a[@href]", $node);
                $link = $linkNodes->length > 0 ? $linkNodes->item(0)->getAttribute('href') : $this->urlBase;
                if ($link && !str_starts_with($link, 'http')) {
                    $link = $this->urlBase . '/' . ltrim($link, '/');
                }

                $imgNodes = $xpath->query(".//img[@src or @data-src]", $node);
                $imagem = null;
                if ($imgNodes->length > 0) {
                    $imgEl = $imgNodes->item(0);
                    $imagem = $imgEl->getAttribute('src') ?: $imgEl->getAttribute('data-src');
                }

                $imoveis[] = [
                    'id' => md5($link),
                    'titulo' => $titulo,
                    'tipo' => 'Imóvel',
                    'cidade' => 'Maranhão',
                    'uf' => 'MA',
                    'endereco' => 'Consulte edital na fonte',
                    'valor_avaliacao' => null,
                    'valor_leilao' => null,
                    'desconto' => null,
                    'modalidade' => 'Leilão',
                    'data_encerramento' => null,
                    'data_inclusao' => null,
                    'edital' => null,
                    'link_matricula' => null,
                    'link' => $link,
                    'imagem' => $imagem,
                    'fonte_slug' => $this->slug,
                    'fonte_nome' => $this->nome,
                ];
            }
        }

        return $imoveis;
    }
}
