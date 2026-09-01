<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;

require_once __DIR__ . '/SourceInterface.php';

/**
 * Driver de extração para o portal Leilão Imóvel (https://www.leilaoimovel.com.br).
 */
class LeilaoImovelSource implements SourceInterface
{
    private string $slug = 'leilaoimovel';
    private string $nome = 'Leilão Imóvel';
    private string $urlBase = 'https://www.leilaoimovel.com.br';

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
        $uf = $filtros['uf'] ?? 'ma';
        $municipio = $filtros['municipio'] ?? null;
        $tipo = $filtros['tipo'] ?? null;
        $pagina = (int)($filtros['pagina'] ?? 1);
        $dataFinal = $filtros['data_final_leilao'] ?? null;
        $termo = $filtros['s'] ?? null;

        $resultado = $scraper->getImoveis($uf, $municipio, $tipo, $pagina, $dataFinal, $termo);

        // Garantir que todos os itens venham identificados com a fonte
        if (!empty($resultado['data']) && is_array($resultado['data'])) {
            foreach ($resultado['data'] as &$item) {
                $item['fonte_slug'] = $this->slug;
                $item['fonte_nome'] = $this->nome;
            }
        }

        return $resultado;
    }

    public function scrapeDetalhes(Scraper $scraper, string $url): array
    {
        return $scraper->getImovelDetalhes($url);
    }
}
