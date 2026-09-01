<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Cache.php';
require_once __DIR__ . '/ScraperService.php';

/**
 * Classe responsável por orquestrar a extração de dados do site leilaoimovel.com.br,
 * com suporte a filtros avançados (data_final_leilao, busca textual, tipo, município, estado),
 * e extração de dados estruturados ricos (edital, matrícula, leiloeiro, data de inclusão).
 */
class Scraper
{
    private Cache $cache;
    private ScraperService $service;

    public function __construct()
    {
        $this->cache = new Cache();
        $this->service = new ScraperService();
    }

    /**
     * Retorna o status de saúde dos tokens dos provedores.
     */
    public function getTokensStatus(): array
    {
        return $this->service->getTokensStatus();
    }

    /**
     * Executa busca de HTML através dos provedores de scraping (Scrape.do / Firecrawl).
     */
    public function fetchHtml(string $url): ?string
    {
        $res = $this->service->fetch($url, 'html');
        return $res['success'] ? $res['content'] : null;
    }

    /**
     * Executa busca de JSON através dos provedores de scraping.
     */
    public function fetchJson(string $url): ?string
    {
        $res = $this->service->fetch($url, 'json');
        return $res['success'] ? $res['content'] : null;
    }

    public function getService(): ScraperService
    {
        return $this->service;
    }

    /**
     * Retorna a lista de estados disponíveis com contagem de imóveis.
     */
    public function getEstados(): array
    {
        $cacheKey = 'estados_all_v3';
        $cached = $this->cache->get($cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        $targetUrl = BASE_URL . '/getAllStates';
        $res = $this->service->fetch($targetUrl, 'json');

        if ($res['success']) {
            $data = json_decode($res['content'], true);
            $locations = $data['locations'] ?? $data ?? [];

            if (is_array($locations) && !empty($locations)) {
                $estados = [];
                foreach ($locations as $item) {
                    $sigla = strtolower($item['state'] ?? $item['uf'] ?? '');
                    if (empty($sigla)) continue;

                    $rawName = $item['name'] ?? '';
                    $nomeLimpo = ESTADOS[$sigla] ?? strtoupper($sigla);
                    $qty = (int)($item['qty'] ?? 0);

                    $estados[] = [
                        'id' => $item['id'] ?? null,
                        'sigla' => $sigla,
                        'nome' => $nomeLimpo,
                        'nome_completo' => $rawName ?: "$nomeLimpo ($qty)",
                        'qty' => $qty,
                        'url' => BASE_URL . LEILAO_PATH . '/' . $sigla,
                    ];
                }

                if (!empty($estados)) {
                    usort($estados, fn($a, $b) => strcmp($a['nome'], $b['nome']));
                    $this->cache->set($cacheKey, $estados, CACHE_TTL_LOCATIONS);
                    return $estados;
                }
            }
        }

        // Fallback local
        $estados = [];
        foreach (ESTADOS as $sigla => $nome) {
            $estados[] = [
                'id' => null,
                'sigla' => $sigla,
                'nome' => $nome,
                'nome_completo' => "$nome (" . strtoupper($sigla) . ")",
                'qty' => 0,
                'url' => BASE_URL . LEILAO_PATH . '/' . $sigla,
            ];
        }

        $this->cache->set($cacheKey, $estados, CACHE_TTL_LOCATIONS);
        return $estados;
    }

    /**
     * Retorna a lista de municípios para um estado especificado.
     */
    public function getMunicipios(string $uf): array
    {
        $uf = strtolower(trim($uf));
        if (strlen($uf) !== 2) {
            return [];
        }

        $cacheKey = "municipios_v3_{$uf}";
        $cached = $this->cache->get($cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        $targetUrl = BASE_URL . '/getAllCities';
        $res = $this->service->fetch($targetUrl, 'json');

        if ($res['success']) {
            $data = json_decode($res['content'], true);
            $locations = $data['locations'] ?? $data ?? [];

            if (is_array($locations) && !empty($locations)) {
                $municipios = [];
                $ufUpper = strtoupper($uf);

                foreach ($locations as $item) {
                    $cidadeUf = strtoupper($item['state'] ?? $item['uf'] ?? '');
                    if ($cidadeUf !== $ufUpper) continue;

                    $rawName = $item['name'] ?? '';
                    $nomeLimpo = preg_replace('/\/[A-Z]{2}\s*\(\d+\)$/i', '', $rawName);
                    $nomeLimpo = trim(preg_replace('/\s*\(\d+\)$/', '', $nomeLimpo));

                    $slug = $item['slug'] ?? '';
                    if (preg_match('#/leilao-de-imove[il]s?/([^/]+)(?:/' . $uf . ')?#i', $slug, $m)) {
                        $citySlug = preg_replace('/-' . $uf . '$/i', '', $m[1]);
                    } else {
                        $citySlug = $this->gerarSlug($nomeLimpo);
                    }

                    $qty = (int)($item['qty'] ?? 0);

                    $municipios[] = [
                        'id' => $item['id'] ?? null,
                        'slug' => $citySlug,
                        'nome' => $nomeLimpo,
                        'nome_exibicao' => $rawName ?: "$nomeLimpo ($qty)",
                        'qty' => $qty,
                        'uf' => $uf,
                    ];
                }

                if (!empty($municipios)) {
                    usort($municipios, fn($a, $b) => strcmp($a['nome'], $b['nome']));
                    $this->cache->set($cacheKey, $municipios, CACHE_TTL_LOCATIONS);
                    return $municipios;
                }
            }
        }

        return [];
    }

    /**
     * Busca imóveis de leilão com suporte a filtros:
     * - UF
     * - Município
     * - Tipo de Imóvel
     * - Data Final do Leilão (data_final_leilao)
     * - Termo de Busca (s)
     * - Paginação (pag / pagina)
     */
    public function getImoveis(
        string $uf,
        ?string $municipio = null,
        ?string $tipo = null,
        int $pagina = 1,
        ?string $dataFinalLeilao = null,
        ?string $termoBusca = null
    ): array {
        $uf = strtolower(trim($uf));
        if (strlen($uf) !== 2) {
            return [
                'success' => false,
                'error' => 'Estado (UF) inválido.',
                'data' => [],
            ];
        }

        // Construir URL de busca do site
        if ($municipio) {
            $municipio = strtolower(trim($municipio));
            $path = LEILAO_PATH . '/' . $municipio . '/' . $uf;
        } else {
            $path = LEILAO_PATH . '/' . $uf;
        }

        $url = BASE_URL . $path;

        $params = [];
        if ($termoBusca !== null && trim($termoBusca) !== '') {
            $params['s'] = trim($termoBusca);
        }
        if ($dataFinalLeilao !== null && trim($dataFinalLeilao) !== '') {
            // Normalizar formato para YYYY-MM-DD se vier em DD/MM/YYYY
            $formattedDate = trim($dataFinalLeilao);
            if (preg_match('#^(\d{2})/(\d{2})/(\d{4})$#', $formattedDate, $dm)) {
                $formattedDate = "{$dm[3]}-{$dm[2]}-{$dm[1]}";
            }
            $params['data_final_leilao'] = $formattedDate;
        }
        if ($pagina > 1) {
            $params['pag'] = $pagina;
        }
        if ($tipo) {
            $params['tipo'] = strtolower($tipo);
        }
        if (!empty($params)) {
            $url .= '?' . http_build_query($params);
        }

        $cacheKey = "imoveis_v4_" . md5($url);
        $cached = $this->cache->get($cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        // Realizar scraping
        $res = $this->service->fetch($url, 'html');

        if (!$res['success']) {
            return [
                'success' => false,
                'error' => 'Falha ao buscar imóveis: ' . $res['error'],
                'provider' => $res['provider'],
                'data' => [],
            ];
        }

        $html = $res['content'];
        $imoveis = $this->parsePlaceBoxes($html, $uf);
        $paginacao = $this->parsePaginacao($html, count($imoveis), $pagina);

        $resultado = [
            'success' => true,
            'provider' => $res['provider'],
            'data' => $imoveis,
            'total' => $paginacao['total'],
            'pagina_atual' => $pagina,
            'total_paginas' => $paginacao['total_paginas'],
            'itens_nesta_pagina' => count($imoveis),
            'filtros' => [
                'uf' => strtoupper($uf),
                'estado' => ESTADOS[$uf] ?? strtoupper($uf),
                'municipio' => $municipio,
                'tipo' => $tipo,
                'data_final_leilao' => $dataFinalLeilao,
                's' => $termoBusca,
            ],
        ];

        $this->cache->set($cacheKey, $resultado, CACHE_TTL);
        return $resultado;
    }

    /**
     * Extrai os imóveis dos elementos .place-box do HTML da listagem.
     */
    private function parsePlaceBoxes(string $html, string $defaultUf): array
    {
        $dom = new DOMDocument();
        libxml_use_internal_errors(true);
        $dom->loadHTML('<?xml encoding="UTF-8">' . $html, LIBXML_NOWARNING | LIBXML_NOERROR);
        libxml_clear_errors();

        $xpath = new DOMXPath($dom);
        $boxes = $xpath->query("//div[contains(@class, 'place-box')]");

        $imoveis = [];
        $seen = [];

        if ($boxes && $boxes->length > 0) {
            foreach ($boxes as $box) {
                // Link do imóvel
                $linkNodes = $xpath->query(".//a[contains(@href, '/imovel/')]", $box);
                if (!$linkNodes || $linkNodes->length === 0) {
                    continue;
                }
                $link = $linkNodes->item(0)->getAttribute('href');
                if (empty($link) || isset($seen[$link])) {
                    continue;
                }
                $seen[$link] = true;

                if (str_starts_with($link, '/')) {
                    $link = BASE_URL . $link;
                }

                // Imagem
                $imagem = '';
                $imgNodes = $xpath->query(".//div[contains(@class, 'image')]//img", $box);
                if ($imgNodes && $imgNodes->length > 0) {
                    $img = $imgNodes->item(0);
                    $imagem = $img->getAttribute('src') ?: $img->getAttribute('data-src') ?: '';
                }

                // Preço com desconto / Leilão (discount-price)
                $valLeilao = null;
                $pLeilaoNodes = $xpath->query(".//span[contains(@class, 'discount-price')]", $box);
                if ($pLeilaoNodes && $pLeilaoNodes->length > 0) {
                    $valLeilao = $this->limparValorMonetario($pLeilaoNodes->item(0)->textContent);
                }

                // Preço original / Avaliação (last-price)
                $valAvaliacao = null;
                $pAvaliacaoNodes = $xpath->query(".//span[contains(@class, 'last-price')]", $box);
                if ($pAvaliacaoNodes && $pAvaliacaoNodes->length > 0) {
                    $valAvaliacao = $this->limparValorMonetario($pAvaliacaoNodes->item(0)->textContent);
                }

                // Desconto % (down)
                $desconto = null;
                $descNodes = $xpath->query(".//span[contains(@class, 'down')]//b", $box);
                if ($descNodes && $descNodes->length > 0) {
                    $descText = trim($descNodes->item(0)->textContent);
                    if (preg_match('/(\d+(?:[.,]\d+)?)/', $descText, $m)) {
                        $desconto = (float)str_replace(',', '.', $m[1]);
                    }
                } elseif ($valAvaliacao && $valLeilao && $valAvaliacao > $valLeilao) {
                    $desconto = round((($valAvaliacao - $valLeilao) / $valAvaliacao) * 100, 1);
                }

                // Título e Endereço (.address)
                $titulo = '';
                $endereco = '';
                $addrPNodes = $xpath->query(".//div[contains(@class, 'address')]//p", $box);
                if ($addrPNodes && $addrPNodes->length > 0) {
                    $pNode = $addrPNodes->item(0);
                    $bNodes = $xpath->query(".//b", $pNode);
                    if ($bNodes && $bNodes->length > 0) {
                        $titulo = trim($bNodes->item(0)->textContent);
                    }
                    $spanNodes = $xpath->query(".//span", $pNode);
                    if ($spanNodes && $spanNodes->length > 0) {
                        $endereco = trim($spanNodes->item(0)->textContent);
                    }
                }

                if (empty($titulo)) {
                    $titulo = $this->extrairTituloDoLink($link);
                }

                // Categorias / Modalidades
                $modalidades = [];
                $catNodes = $xpath->query(".//div[contains(@class, 'categories')]//a", $box);
                if ($catNodes && $catNodes->length > 0) {
                    foreach ($catNodes as $cat) {
                        $catText = trim($cat->textContent);
                        if (!empty($catText)) {
                            $modalidades[] = $catText;
                        }
                    }
                }
                $modalidade = !empty($modalidades) ? implode(' / ', $modalidades) : $this->detectarModalidade($titulo . ' ' . $link);

                // Encerramento
                $dataEncerramento = '';
                $infoNodes = $xpath->query(".//div[contains(@class, 'infos')]//span | .//div[contains(@class, 'tag')]//span", $box);
                if ($infoNodes && $infoNodes->length > 0) {
                    $infoText = trim($infoNodes->item(0)->textContent);
                    if (preg_match('/(\d{2}\/\d{2}\/\d{2,4}(?:\s+\d{2}:\d{2})?)/', $infoText, $m)) {
                        $dataEncerramento = $m[1];
                    }
                }

                // Tipo e Cidade
                $tipo = $this->detectarTipo($titulo . ' ' . $link);
                $loc = $this->extrairCidadeUf($link, $endereco, $defaultUf);

                // Inferir ID do imóvel Caixa para links diretos de edital e matrícula
                $caixaId = null;
                if (preg_match('#-(\d{13,14})-#', $link, $mId)) {
                    $caixaId = $mId[1];
                } elseif (preg_match('#(?:imovel-caixa|cef)[^\d]*(\d{7,14})#i', $link, $mId)) {
                    $caixaId = $mId[1];
                }

                $linkMatricula = null;
                $linkEdital = null;
                if ($caixaId && strlen($caixaId) >= 12) {
                    $linkMatricula = "https://venda-imoveis.caixa.gov.br/editais/matricula/" . strtoupper($loc['uf']) . "/{$caixaId}.pdf";
                    $linkEdital = "https://venda-imoveis.caixa.gov.br/editais/regras-VOL/comocomprar.pdf?v=01";
                }

                $imoveis[] = [
                    'titulo' => $titulo,
                    'tipo' => $tipo,
                    'endereco' => $endereco,
                    'cidade' => $loc['cidade'],
                    'uf' => $loc['uf'],
                    'valor_avaliacao' => $valAvaliacao,
                    'valor_leilao' => $valLeilao,
                    'desconto' => $desconto,
                    'modalidade' => $modalidade,
                    'data_encerramento' => $dataEncerramento,
                    'data_inclusao' => null, // Disponível via endpoint ?action=detalhes
                    'edital' => $linkEdital,
                    'link_matricula' => $linkMatricula,
                    'link_leiloeiro' => null, // Disponível via endpoint ?action=detalhes
                    'link' => $link,
                    'imagem' => $imagem,
                ];
            }
        }

        return $imoveis;
    }

    /**
     * Extrai todos os detalhes aprofundados de um imóvel específico:
     * - Data de Inclusão
     * - Edital (link/arquivo)
     * - Matrícula (link e número)
     * - Link do leiloeiro oficial
     * - Áreas (útil, terreno), quartos, vagas
     * - Condições de pagamento (financiamento, FGTS, parcelamento)
     * - Galeria de imagens
     */
    public function getImovelDetalhes(string $url): array
    {
        if (!str_starts_with($url, 'http')) {
            $url = BASE_URL . (str_starts_with($url, '/') ? '' : '/') . $url;
        }

        $cacheKey = "detalhe_v1_" . md5($url);
        $cached = $this->cache->get($cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        $res = $this->service->fetch($url, 'html');
        if (!$res['success']) {
            return [
                'success' => false,
                'error' => 'Falha ao carregar detalhes do imóvel: ' . $res['error'],
            ];
        }

        $html = $res['content'];
        $dom = new DOMDocument();
        libxml_use_internal_errors(true);
        $dom->loadHTML('<?xml encoding="UTF-8">' . $html, LIBXML_NOWARNING | LIBXML_NOERROR);
        libxml_clear_errors();

        $xpath = new DOMXPath($dom);

        // 1. Data de Inclusão (ex: <b>Data de Inclusão:</b> 14/04/2025)
        $dataInclusao = null;
        if (preg_match('/(?:Data de\s+)?Inclus[aã]o:?(?:<\/b>)?\s*([0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2,4})/iu', $html, $m)) {
            $dataInclusao = $m[1];
        }

        // 2. Link do Edital
        $linkEdital = null;
        $editalNodes = $xpath->query("//a[contains(., 'Edital') or contains(@href, 'edital') or contains(@href, 'regras')]");
        if ($editalNodes && $editalNodes->length > 0) {
            foreach ($editalNodes as $eNode) {
                $href = $eNode->getAttribute('href');
                if (!empty($href) && $href !== '#' && !str_starts_with($href, 'javascript')) {
                    $linkEdital = str_starts_with($href, '/') ? BASE_URL . $href : $href;
                    break;
                }
            }
        }

        // 3. Link e Número da Matrícula
        $linkMatricula = null;
        $numeroMatricula = null;
        $matNodes = $xpath->query("//a[contains(., 'Matricula') or contains(@href, 'matricula')]");
        if ($matNodes && $matNodes->length > 0) {
            foreach ($matNodes as $mNode) {
                $href = $mNode->getAttribute('href');
                if (!empty($href) && $href !== '#' && !str_starts_with($href, 'javascript')) {
                    $linkMatricula = str_starts_with($href, '/') ? BASE_URL . $href : $href;
                    break;
                }
            }
        }
        if (preg_match('/Matr[ií]cula:\s*([^\n\r<.,]+)/iu', $html, $mMat)) {
            $numeroMatricula = trim($mMat[1]);
        }

        // 4. Link do Leiloeiro
        $linkLeiloeiro = null;
        $nomeLeiloeiro = null;
        $leiloeiroLinks = $xpath->query("//a[contains(@class, 'tmFooter') and contains(@href, '/leiloeiro/')] | //a[contains(@id, 'linkAuctioneerRedirect')]");
        if ($leiloeiroLinks && $leiloeiroLinks->length > 0) {
            foreach ($leiloeiroLinks as $lLnk) {
                $href = $lLnk->getAttribute('href');
                $txt = trim($lLnk->textContent);
                if (!empty($href) && $href !== '#') {
                    $linkLeiloeiro = str_starts_with($href, '/') ? BASE_URL . $href : $href;
                    $nomeLeiloeiro = $txt ?: null;
                    break;
                }
            }
        }

        // 5. Detalhes físicos (área útil, terreno, quartos, vagas)
        $areaUtil = null;
        $areaTerreno = null;
        $quartos = null;
        $vagas = null;

        if (preg_match('/[AÁ]rea [UÚ]til:\s*([\d.,]+\s*m²?)/iu', $html, $m)) $areaUtil = trim($m[1]);
        if (preg_match('/[AÁ]rea Terreno:\s*([\d.,]+\s*m²?)/iu', $html, $m)) $areaTerreno = trim($m[1]);
        if (preg_match('/Quartos:\s*(\d+)/iu', $html, $m)) $quartos = (int)$m[1];
        if (preg_match('/Vagas:\s*(\d+)/iu', $html, $m)) $vagas = (int)$m[1];

        // 6. Galeria de Imagens
        $imagens = [];
        $imgNodes = $xpath->query("//div[contains(@class, 'image') or contains(@class, 'carousel') or contains(@class, 'gallery')]//img");
        if ($imgNodes && $imgNodes->length > 0) {
            foreach ($imgNodes as $img) {
                $src = $img->getAttribute('src') ?: $img->getAttribute('data-src') ?: '';
                if (!empty($src) && !str_contains($src, 'svg') && !str_contains($src, 'banner') && !in_array($src, $imagens)) {
                    $imagens[] = $src;
                }
            }
        }

        $detalhes = [
            'success' => true,
            'url' => $url,
            'data_inclusao' => $dataInclusao,
            'edital' => $linkEdital,
            'link_matricula' => $linkMatricula,
            'numero_matricula' => $numeroMatricula,
            'link_leiloeiro' => $linkLeiloeiro,
            'nome_leiloeiro' => $nomeLeiloeiro,
            'area_util' => $areaUtil,
            'area_terreno' => $areaTerreno,
            'quartos' => $quartos,
            'vagas' => $vagas,
            'imagens' => $imagens,
        ];

        $this->cache->set($cacheKey, $detalhes, CACHE_TTL);
        return $detalhes;
    }

    /**
     * Extrai paginação e quantidade total de resultados.
     */
    private function parsePaginacao(string $html, int $itensNestaPagina, int $paginaAtual): array
    {
        $total = 0;

        if (preg_match("/'itens_returned'\s*:\s*(\d+)/i", $html, $m)) {
            $total = (int)$m[1];
        } elseif (preg_match('/"itens_returned"\s*:\s*(\d+)/i', $html, $m)) {
            $total = (int)$m[1];
        }

        if ($total === 0) {
            if (preg_match('/(\d+)\s*(?:imóveis|imoveis|resultados)\s*encontrados?/ui', $html, $m)) {
                $total = (int)$m[1];
            }
        }

        if ($total === 0) {
            $total = $itensNestaPagina;
        }

        $itensPorPagina = 20;
        $totalPaginas = max(1, (int)ceil($total / $itensPorPagina));

        return [
            'total' => $total,
            'total_paginas' => $totalPaginas,
            'pagina_atual' => $paginaAtual,
        ];
    }

    /**
     * Limpa e converte strings monetárias tipo "R$ 97.036,03" em float.
     */
    private function limparValorMonetario(string $str): ?float
    {
        if (preg_match('/(?:R\$\s*)?([\d.,]+)/', $str, $m)) {
            $val = str_replace('.', '', $m[1]);
            $val = str_replace(',', '.', $val);
            return (float)$val;
        }
        return null;
    }

    /**
     * Extrai Cidade e UF do link ou endereço.
     */
    private function extrairCidadeUf(string $link, string $endereco, string $defaultUf): array
    {
        $cidade = '';
        $uf = strtoupper($defaultUf);

        if (preg_match('#/imovel/([a-z]{2})/([^/]+)/#i', $link, $m)) {
            $uf = strtoupper($m[1]);
            $cidade = mb_convert_case(str_replace('-', ' ', $m[2]), MB_CASE_TITLE, 'UTF-8');
        } elseif (!empty($endereco)) {
            if (preg_match('/,\s*([^,-]+)\s*-\s*([A-Z]{2})\b/u', $endereco, $m)) {
                $cidade = trim($m[1]);
                $uf = strtoupper($m[2]);
            }
        }

        return ['cidade' => $cidade, 'uf' => $uf];
    }

    /**
     * Detecta o tipo de imóvel a partir do texto ou URL.
     */
    private function detectarTipo(string $texto): string
    {
        $texto = mb_strtolower($texto, 'UTF-8');

        $map = [
            'apartamento' => 'Apartamento',
            'apto' => 'Apartamento',
            'casa' => 'Casa',
            'terreno' => 'Terreno',
            'lote' => 'Terreno',
            'rural' => 'Rural',
            'fazenda' => 'Rural',
            'chácara' => 'Rural',
            'chacara' => 'Rural',
            'sítio' => 'Rural',
            'sitio' => 'Rural',
            'comercial' => 'Comercial',
            'sala' => 'Comercial',
            'loja' => 'Comercial',
            'galpão' => 'Galpão',
            'galpao' => 'Galpão',
            'garagem' => 'Garagem',
            'vaga' => 'Garagem',
            'prédio' => 'Comercial',
            'predio' => 'Comercial',
        ];

        foreach ($map as $key => $type) {
            if (str_contains($texto, $key)) {
                return $type;
            }
        }

        return 'Imóvel';
    }

    /**
     * Detecta a modalidade do leilão.
     */
    private function detectarModalidade(string $texto): string
    {
        $texto = mb_strtolower($texto, 'UTF-8');

        if (str_contains($texto, 'venda online') || str_contains($texto, 'venda direta')) {
            return 'Venda Direta';
        }
        if (str_contains($texto, 'extrajudicial')) {
            return 'Extrajudicial';
        }
        if (str_contains($texto, 'judicial')) {
            return 'Judicial';
        }
        if (str_contains($texto, 'sfi')) {
            return 'Leilão SFI';
        }
        if (str_contains($texto, 'licitação')) {
            return 'Licitação';
        }

        return 'Leilão';
    }

    /**
     * Gera título a partir da URL.
     */
    private function extrairTituloDoLink(string $link): string
    {
        $path = parse_url($link, PHP_URL_PATH) ?? '';
        $parts = explode('/', trim($path, '/'));
        $slug = end($parts) ?: '';
        $slug = preg_replace('/-\d+$/', '', $slug);
        $title = str_replace('-', ' ', $slug);
        return mb_convert_case($title, MB_CASE_TITLE, 'UTF-8');
    }

    /**
     * Gera um slug URL-friendly.
     */
    private function gerarSlug(string $texto): string
    {
        $slug = mb_strtolower($texto, 'UTF-8');
        $slug = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $slug) ?: $slug;
        $slug = preg_replace('/[^a-z0-9]+/', '-', $slug);
        return trim(preg_replace('/-+/', '-', $slug), '-');
    }

    /**
     * Limpa o cache local.
     */
    public function limparCache(): int
    {
        return $this->cache->clear();
    }
}
