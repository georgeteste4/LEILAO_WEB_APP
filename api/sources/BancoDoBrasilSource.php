<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;
use DOMDocument;
use DOMXPath;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver Especializado de Extração para o Banco do Brasil (Seu Imóvel BB).
 * URL Base: https://seuimovelbb.com.br
 */
class BancoDoBrasilSource implements SourceInterface
{
    private string $slug = 'bancodobrasil';
    private string $nome = 'Banco do Brasil (Seu Imóvel BB)';
    private string $urlBase = 'https://seuimovelbb.com.br';
    private string $apiUrl = 'https://seuimovelbb.com.br/catalogo';

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

        $params = [
            'pagina' => $pagina,
            'contento' => 50,
            'ordem' => '1',
            'categorias' => 'todas',
            'tipoVenda' => 'todas',
            'localidade' => $uf,
            'texto' => $termo,
        ];

        // Se Scrape.do estiver ativo, fazer request via proxy
        $tokens = defined('SCRAPE_DO_TOKENS') ? SCRAPE_DO_TOKENS : [];
        $token = $tokens[0] ?? '';
        $targetUrl = !empty($token) 
            ? "http://api.scrape.do/?token={$token}&url=" . urlencode($this->apiUrl)
            : $this->apiUrl;

        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $targetUrl,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query($params),
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/x-www-form-urlencoded; charset=UTF-8',
                'X-Requested-With: XMLHttpRequest',
                'Referer: https://seuimovelbb.com.br/imoveis',
                'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            ],
            CURLOPT_TIMEOUT => 25,
        ]);

        $rawResponse = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if (!$rawResponse || $httpCode !== 200) {
            return [
                'success' => false,
                'error' => "Falha ao consultar catálogo do Banco do Brasil (HTTP {$httpCode}).",
                'data' => [],
                'total' => 0,
                'pagina_atual' => $pagina,
                'total_paginas' => 1,
            ];
        }

        $json = json_decode($rawResponse, true);
        $htmlLista = $json['lista'] ?? '';

        if (empty($htmlLista)) {
            return [
                'success' => true,
                'data' => [],
                'total' => 0,
                'pagina_atual' => $pagina,
                'total_paginas' => 1,
                'fonte_slug' => $this->slug,
                'fonte_nome' => $this->nome,
            ];
        }

        $imoveis = $this->parseBBCards($htmlLista, $uf, $filtros);

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
            'nome_leiloeiro' => 'Banco do Brasil',
            'link_leiloeiro' => $this->urlBase,
        ];
    }

    private function parseBBCards(string $html, string $targetUf, array $filtros): array
    {
        $validUfs = [
            'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
            'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
            'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
        ];

        $doc = new DOMDocument();
        @$doc->loadHTML('<?xml encoding="UTF-8">' . $html);
        $xpath = new DOMXPath($doc);

        $imoveis = [];
        $cards = $xpath->query("//div[contains(@class, 'card') or contains(@class, 'carta')]");

        foreach ($cards as $card) {
            $linkNode = $xpath->query(".//a[@href]", $card);
            if ($linkNode->length === 0) continue;

            $href = $linkNode->item(0)->getAttribute('href');
            $fullLink = str_starts_with($href, 'http') ? $href : "{$this->urlBase}/" . ltrim($href, '/');

            // ID / Matrícula
            $idBB = null;
            if (preg_match('#/imovel/id/(\d+)#i', $href, $mId)) {
                $idBB = $mId[1];
            }

            // Imagem
            $imgNode = $xpath->query(".//img[@src]", $card);
            $imagem = null;
            if ($imgNode->length > 0) {
                $src = $imgNode->item(0)->getAttribute('src');
                $imagem = str_starts_with($src, 'http') ? $src : "{$this->urlBase}/" . ltrim($src, '/');
            }

            $cardText = preg_replace('/\s+/', ' ', trim($card->textContent));

            // Cidade e UF do card
            $cardUf = $targetUf;
            $cardCidade = 'São Luís';

            if (preg_match('/([A-ZÀ-Úa-z\s]+)\s*-\s*([A-Z]{2})/u', $cardText, $locMatch)) {
                $candidateUf = strtoupper(trim($locMatch[2]));
                if (in_array($candidateUf, $validUfs)) {
                    $cardUf = $candidateUf;
                    $candidateCidade = trim($locMatch[1]);
                    // Limpar palavras soltas
                    $candidateCidade = preg_replace('/^(imóvel|imovel|apartamento|casa|terreno|rural|venda|novidade|destaque|leilão|leilao)\s+/i', '', $candidateCidade);
                    $cardCidade = mb_convert_case(trim($candidateCidade), MB_CASE_TITLE, 'UTF-8');
                }
            }

            // Se filtrou por UF, garantir que bate exatamente
            if (!empty($targetUf) && $cardUf !== $targetUf) {
                continue;
            }

            // Tipo
            $tipoImovel = 'Imóvel';
            if (stripos($cardText, 'apartamento') !== false) $tipoImovel = 'Apartamento';
            elseif (stripos($cardText, 'casa') !== false) $tipoImovel = 'Casa';
            elseif (stripos($cardText, 'terreno') !== false) $tipoImovel = 'Terreno';
            elseif (stripos($cardText, 'rural') !== false || stripos($cardText, 'fazenda') !== false) $tipoImovel = 'Rural';
            elseif (stripos($cardText, 'comercial') !== false || stripos($cardText, 'sala') !== false) $tipoImovel = 'Comercial';

            // Valores de Avaliação e Lance/Venda
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

            // Modalidade
            $modalidade = 'Venda Direta / Leilão BB';
            if (stripos($cardText, 'leilão') !== false || stripos($cardText, 'leilao') !== false) {
                $modalidade = 'Leilão Banco do Brasil';
            } elseif (stripos($cardText, 'direta') !== false) {
                $modalidade = 'Venda Direta BB';
            }

            $titulo = "{$tipoImovel} Banco do Brasil em {$cardCidade}/{$cardUf}" . ($idBB ? " (ID {$idBB})" : '');

            $imoveis[] = [
                'id' => md5($fullLink),
                'hash_imovel' => md5($fullLink),
                'titulo' => mb_substr($titulo, 0, 255),
                'tipo' => $tipoImovel,
                'cidade' => $cardCidade,
                'uf' => $cardUf,
                'endereco' => "Consulte a ficha oficial do BB ({$cardCidade}/{$cardUf})",
                'valor_avaliacao' => $valorAvaliacao,
                'valor_leilao' => $valorLeilao,
                'desconto' => $desconto,
                'modalidade' => $modalidade,
                'data_encerramento' => 'Consulte edital BB',
                'data_inclusao' => date('d/m/Y'),
                'edital' => $fullLink,
                'link_matricula' => $fullLink,
                'numero_matricula' => $idBB ?: null,
                'nome_leiloeiro' => 'Banco do Brasil',
                'link_leiloeiro' => $this->urlBase,
                'link' => $fullLink,
                'imagem' => $imagem,
                'fonte_slug' => $this->slug,
                'fonte_nome' => $this->nome,
            ];
        }

        return $imoveis;
    }
}
