<?php
declare(strict_types=1);

namespace App\Sources;

use Scraper;

/**
 * Interface padronizada para qualquer fonte de dados de leilões imobiliários.
 */
interface SourceInterface
{
    /**
     * Retorna o identificador único da fonte (slug).
     */
    public function getSlug(): string;

    /**
     * Retorna o nome amigável da fonte.
     */
    public function getNome(): string;

    /**
     * Retorna a URL base da fonte.
     */
    public function getUrlBase(): string;

    /**
     * Executa a extração da listagem de imóveis com base nos filtros informados.
     * Retorna um array padronizado contendo itens com o schema único do sistema.
     *
     * @param Scraper $scraper Instância do motor Scraper (Scrape.do + Firecrawl)
     * @param array $filtros [uf, municipio, tipo, pagina, data_final_leilao, s]
     * @return array [success => bool, total => int, pagina_atual => int, total_paginas => int, data => array, error => ?string]
     */
    public function scrapeImoveis(Scraper $scraper, array $filtros): array;

    /**
     * Executa a extração de detalhes enriquecidos de um imóvel específico (Edital, Matrícula, Leiloeiro).
     *
     * @param Scraper $scraper Instância do motor Scraper
     * @param string $url URL do imóvel na fonte
     * @return array [success => bool, data_inclusao => ?, edital => ?, link_matricula => ?, numero_matricula => ?, nome_leiloeiro => ?, link_leiloeiro => ?]
     */
    public function scrapeDetalhes(Scraper $scraper, string $url): array;
}
