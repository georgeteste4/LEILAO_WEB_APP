<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';

/**
 * Gerenciador de Conexão com o Banco de Dados MySQL (leilao_app).
 * Inclui auto-inicialização de schema, tabelas e índices.
 */
class Database
{
    private static ?PDO $instance = null;

    public static function getConnection(): PDO
    {
        if (self::$instance === null) {
            $host = defined('DB_HOST') ? DB_HOST : '127.0.0.1';
            $port = defined('DB_PORT') ? DB_PORT : 3306;
            $dbName = defined('DB_NAME') ? DB_NAME : 'leilao_app';
            $user = defined('DB_USER') ? DB_USER : 'root';
            $pass = defined('DB_PASS') ? DB_PASS : '';

            try {
                // 1. Conectar ao servidor MySQL para garantir que o banco existe
                $rootPdo = new PDO(
                    "mysql:host={$host};port={$port};charset=utf8mb4",
                    $user,
                    $pass,
                    [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_TIMEOUT => 5,
                    ]
                );
                $rootPdo->exec("CREATE DATABASE IF NOT EXISTS `{$dbName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");

                // 2. Conectar diretamente ao banco leilao_app
                self::$instance = new PDO(
                    "mysql:host={$host};port={$port};dbname={$dbName};charset=utf8mb4",
                    $user,
                    $pass,
                    [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES => true,
                    ]
                );

                // 3. Auto-inicializar schema das tabelas
                self::initSchema(self::$instance);

            } catch (PDOException $e) {
                error_log("Database Connection Error: " . $e->getMessage());
                throw new Exception("Erro ao conectar no banco de dados MySQL `{$dbName}`: " . $e->getMessage());
            }
        }

        return self::$instance;
    }

    /**
     * Cria e atualiza as tabelas do banco de dados automaticamente.
     */
    private static function initSchema(PDO $pdo): void
    {
        // 1. Tabela de Filtros Salvos (Configurações de Cron)
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `filtros_salvos` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `nome` VARCHAR(255) NOT NULL,
                `uf` VARCHAR(2) NOT NULL,
                `municipio` VARCHAR(100) NULL,
                `tipo` VARCHAR(50) NULL,
                `data_final_leilao` DATE NULL,
                `termo_busca` VARCHAR(255) NULL,
                `cron_token` VARCHAR(64) NOT NULL,
                `ativo` TINYINT(1) DEFAULT 1,
                `total_execucoes` INT DEFAULT 0,
                `total_imoveis_salvos` INT DEFAULT 0,
                `ultima_execucao_em` DATETIME NULL,
                `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX `idx_uf_municipio` (`uf`, `municipio`),
                INDEX `idx_ativo` (`ativo`),
                INDEX `idx_cron_token` (`cron_token`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");

        // 2. Tabela de Imóveis Estruturados
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `imoveis` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `hash_imovel` VARCHAR(64) NOT NULL UNIQUE,
                `filtro_id` INT NULL,
                `titulo` VARCHAR(500) NOT NULL,
                `tipo` VARCHAR(50) NOT NULL,
                `endereco` TEXT NULL,
                `cidade` VARCHAR(100) NULL,
                `uf` VARCHAR(2) NOT NULL,
                `valor_avaliacao` DECIMAL(15,2) NULL,
                `valor_leilao` DECIMAL(15,2) NULL,
                `desconto` DECIMAL(5,2) NULL,
                `modalidade` VARCHAR(255) NULL,
                `data_encerramento` VARCHAR(100) NULL,
                `data_inclusao` VARCHAR(50) NULL,
                `edital` TEXT NULL,
                `link_matricula` TEXT NULL,
                `numero_matricula` VARCHAR(100) NULL,
                `link_leiloeiro` TEXT NULL,
                `nome_leiloeiro` VARCHAR(255) NULL,
                `link_original` TEXT NOT NULL,
                `imagem` TEXT NULL,
                `dados_json` LONGTEXT NULL,
                `status` VARCHAR(50) DEFAULT 'ativo',
                `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX `idx_uf` (`uf`),
                INDEX `idx_cidade` (`cidade`),
                INDEX `idx_tipo` (`tipo`),
                INDEX `idx_desconto` (`desconto`),
                INDEX `idx_valor_leilao` (`valor_leilao`),
                INDEX `idx_status` (`status`),
                INDEX `idx_criado_em` (`criado_em`),
                FOREIGN KEY (`filtro_id`) REFERENCES `filtros_salvos` (`id`) ON DELETE SET NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");

        // 3. Tabela de Logs de Execução do Cron
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `logs_cron` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `filtro_id` INT NULL,
                `status` VARCHAR(50) NOT NULL,
                `total_paginas` INT DEFAULT 0,
                `total_imoveis` INT DEFAULT 0,
                `novos` INT DEFAULT 0,
                `atualizados` INT DEFAULT 0,
                `tempo_segundos` DECIMAL(8,2) DEFAULT 0,
                `detalhes` TEXT NULL,
                `executado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_filtro_id` (`filtro_id`),
                INDEX `idx_executado_em` (`executado_em`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");

        // 4. Tabela de Fontes de Dados (Multi-Site Hub)
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS `fontes_dados` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `slug` VARCHAR(64) NOT NULL UNIQUE,
                `nome` VARCHAR(150) NOT NULL,
                `url_base` VARCHAR(255) NOT NULL,
                `descricao` TEXT NULL,
                `ativo` TINYINT(1) DEFAULT 1,
                `driver_class` VARCHAR(100) NOT NULL DEFAULT 'LeilaoImovelSource',
                `config_json` TEXT NULL,
                `total_imoveis_coletados` INT DEFAULT 0,
                `ultima_coleta_em` DATETIME NULL,
                `criado_em` DATETIME DEFAULT CURRENT_TIMESTAMP,
                `atualizado_em` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX `idx_slug` (`slug`),
                INDEX `idx_ativo` (`ativo`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ");

        // Migração suave: Adicionar coluna fonte_slug na tabela de imóveis se não existir
        try {
            $colCheck = $pdo->query("SHOW COLUMNS FROM `imoveis` LIKE 'fonte_slug'")->fetch();
            if (!$colCheck) {
                $pdo->exec("ALTER TABLE `imoveis` ADD COLUMN `fonte_slug` VARCHAR(64) NOT NULL DEFAULT 'leilaoimovel' AFTER `hash_imovel`");
                $pdo->exec("ALTER TABLE `imoveis` ADD INDEX `idx_fonte_slug` (`fonte_slug`)");
            }
        } catch (\Throwable $e) {
            // Silencioso
        }

        // Migração suave: Adicionar coluna fontes na tabela de filtros_salvos se não existir
        try {
            $colCheckFiltro = $pdo->query("SHOW COLUMNS FROM `filtros_salvos` LIKE 'fontes'")->fetch();
            if (!$colCheckFiltro) {
                $pdo->exec("ALTER TABLE `filtros_salvos` ADD COLUMN `fontes` TEXT NULL AFTER `termo_busca`");
            }
        } catch (\Throwable $e) {
            // Silencioso
        }

        // Lista de todas as fontes padrão do sistema
        $fontesPadrao = [
            ['leilaoimovel', 'Leilão Imóvel', 'https://www.leilaoimovel.com.br', 'Portal agregador de leilões judiciais e extrajudiciais com dados enriquecidos.', 1, 'LeilaoImovelSource', '{"url_listagem":"https://www.leilaoimovel.com.br/leilao-de-imoveis/{uf}?pagina={pagina}"}'],
            ['caixa', 'Caixa Econômica Federal', 'https://venda-imoveis.caixa.gov.br', 'Imóveis adjudicados e leilões diretos da Caixa Econômica com matrículas oficiais.', 1, 'CaixaSource', '{"url_listagem":"https://venda-imoveis.caixa.gov.br/listaweb/Lista_imoveis_{uf}.csv"}'],
            ['zukerman', 'Portal Zuk (Zukerman)', 'https://www.portalzuk.com.br', 'Leilões de imóveis residenciais, comerciais e rurais em todo o Brasil.', 1, 'ZukermanSource', '{"url_listagem":"https://www.portalzuk.com.br/leilao-de-imoveis/u/todos-imoveis/{uf}"}'],
            ['santander', 'Banco Santander (Imóveis & Leilões)', 'https://www.santanderimoveis.com.br', 'Oportunidades de leilões e venda direta de imóveis do Banco Santander.', 1, 'SantanderSource', '{"url_listagem":"https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-santander"}'],
            ['bradesco', 'Banco Bradesco (Imóveis & Leilões)', 'https://www.bradescoimoveis.com.br', 'Imóveis desocupados e leilões oficiais do Banco Bradesco.', 1, 'BradescoSource', '{"url_listagem":"https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-bradesco"}'],
            ['itau', 'Banco Itaú (Imóveis & Leilões)', 'https://www.itau.com.br/imoveis-leilao', 'Leilões oficiais e imóveis retomados do Banco Itaú Unibanco.', 1, 'BankSource', '{"url_listagem":"https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-itau"}'],
            ['bancodobrasil', 'Banco do Brasil (Seu Imóvel BB)', 'https://seuimovelbb.com.br', 'Catálogo oficial de imóveis e leilões do Banco do Brasil.', 1, 'BancoDoBrasilSource', '{"url_listagem":"https://seuimovelbb.com.br"}'],
            ['bancointer', 'Banco Inter (Imóveis & Leilões)', 'https://inter.co', 'Leilões e oportunidades imobiliárias com financiamento Banco Inter.', 1, 'BankSource', '{"url_listagem":"https://inter.co/pra-voce/investimentos/imoveis-leilao/"}'],
            ['sicredi', 'Sicredi (Imóveis & Leilões)', 'https://www.sicredi.com.br', 'Imóveis recuperados e leilões cooperativos do Sicredi.', 1, 'BankSource', '{"url_listagem":"https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-sicoob"}'],
            ['smartleiloescaixa', 'Smart Leilões Caixa', 'https://smartleiloescaixa.com.br', 'Portal especializado em leilões e oportunidades da Caixa Econômica Federal.', 1, 'SmartLeiloesCaixaSource', '{"url_api":"https://api-dot-site-smart-leiloes.rj.r.appspot.com/api/imovel/busca"}'],
            ['megaleiloes', 'Mega Leilões', 'https://www.megaleiloes.com.br', 'Um dos maiores portais de leilões judiciais e de bancos do Brasil.', 1, 'GenericSource', '{"url_listagem":"https://www.megaleiloes.com.br/imoveis/{uf}?pagina={pagina}"}'],
            ['sodresantoro', 'Sodré Santoro', 'https://www.sodresantoro.com.br', 'Tradicional leiloeiro oficial com oportunidades judiciais e financeiras.', 1, 'GenericSource', '{"url_listagem":"https://www.sodresantoro.com.br/imoveis/{uf}"}']
        ];

        $stmtInsFonte = $pdo->prepare("
            INSERT INTO `fontes_dados` (`slug`, `nome`, `url_base`, `descricao`, `ativo`, `driver_class`, `config_json`)
            VALUES (:slug, :nome, :url_base, :descricao, :ativo, :driver_class, :config_json)
            ON DUPLICATE KEY UPDATE
                `nome` = VALUES(`nome`),
                `url_base` = VALUES(`url_base`),
                `descricao` = VALUES(`descricao`),
                `driver_class` = VALUES(`driver_class`),
                `config_json` = VALUES(`config_json`)
        ");

        foreach ($fontesPadrao as $fp) {
            $stmtInsFonte->execute([
                ':slug' => $fp[0],
                ':nome' => $fp[1],
                ':url_base' => $fp[2],
                ':descricao' => $fp[3],
                ':ativo' => $fp[4],
                ':driver_class' => $fp[5],
                ':config_json' => $fp[6],
            ]);
        }
    }

    /**
     * Insere ou atualiza um imóvel no banco de dados (Upsert).
     */
    public static function upsertImovel(array $imovel, ?int $filtroId = null): array
    {
        $pdo = self::getConnection();

        $linkOriginal = $imovel['link'] ?? '';
        if (empty($linkOriginal)) {
            return ['action' => 'skip', 'id' => null];
        }

        $hash = md5($linkOriginal);
        $fonteSlug = $imovel['fonte_slug'] ?? 'leilaoimovel';
        $titulo = mb_substr($imovel['titulo'] ?? 'Imóvel', 0, 500);
        $tipo = mb_substr($imovel['tipo'] ?? 'Imóvel', 0, 50);
        $endereco = $imovel['endereco'] ?? null;
        $cidade = mb_substr($imovel['cidade'] ?? '', 0, 100);
        $uf = strtoupper(mb_substr($imovel['uf'] ?? 'MA', 0, 2));
        $valorAvaliacao = $imovel['valor_avaliacao'] ?? null;
        $valorLeilao = $imovel['valor_leilao'] ?? null;
        $desconto = $imovel['desconto'] ?? null;
        $modalidade = mb_substr($imovel['modalidade'] ?? '', 0, 255);
        $dataEncerramento = $imovel['data_encerramento'] ?? null;
        $dataInclusao = $imovel['data_inclusao'] ?? null;
        $edital = $imovel['edital'] ?? null;
        $linkMatricula = $imovel['link_matricula'] ?? null;
        $numeroMatricula = $imovel['numero_matricula'] ?? null;
        $linkLeiloeiro = $imovel['link_leiloeiro'] ?? null;
        $nomeLeiloeiro = $imovel['nome_leiloeiro'] ?? null;
        $imagem = $imovel['imagem'] ?? null;
        $dadosJson = json_encode($imovel, JSON_UNESCAPED_UNICODE);

        // Verificar se já existe
        $stmtCheck = $pdo->prepare("SELECT id FROM `imoveis` WHERE `hash_imovel` = :hash LIMIT 1");
        $stmtCheck->execute([':hash' => $hash]);
        $existing = $stmtCheck->fetch();

        if ($existing) {
            // Update
            $stmtUpdate = $pdo->prepare("
                UPDATE `imoveis` SET
                    `fonte_slug` = :fonte_slug,
                    `titulo` = :titulo,
                    `tipo` = :tipo,
                    `endereco` = :endereco,
                    `cidade` = :cidade,
                    `uf` = :uf,
                    `valor_avaliacao` = :valor_avaliacao,
                    `valor_leilao` = :valor_leilao,
                    `desconto` = :desconto,
                    `modalidade` = :modalidade,
                    `data_encerramento` = :data_encerramento,
                    `data_inclusao` = COALESCE(:data_inclusao, `data_inclusao`),
                    `edital` = COALESCE(:edital, `edital`),
                    `link_matricula` = COALESCE(:link_matricula, `link_matricula`),
                    `numero_matricula` = COALESCE(:numero_matricula, `numero_matricula`),
                    `link_leiloeiro` = COALESCE(:link_leiloeiro, `link_leiloeiro`),
                    `nome_leiloeiro` = COALESCE(:nome_leiloeiro, `nome_leiloeiro`),
                    `imagem` = COALESCE(:imagem, `imagem`),
                    `dados_json` = :dados_json,
                    `status` = 'ativo',
                    `atualizado_em` = NOW()
                WHERE `id` = :id
            ");

            $stmtUpdate->execute([
                ':fonte_slug' => $fonteSlug,
                ':titulo' => $titulo,
                ':tipo' => $tipo,
                ':endereco' => $endereco,
                ':cidade' => $cidade,
                ':uf' => $uf,
                ':valor_avaliacao' => $valorAvaliacao,
                ':valor_leilao' => $valorLeilao,
                ':desconto' => $desconto,
                ':modalidade' => $modalidade,
                ':data_encerramento' => $dataEncerramento,
                ':data_inclusao' => $dataInclusao,
                ':edital' => $edital,
                ':link_matricula' => $linkMatricula,
                ':numero_matricula' => $numeroMatricula,
                ':link_leiloeiro' => $linkLeiloeiro,
                ':nome_leiloeiro' => $nomeLeiloeiro,
                ':imagem' => $imagem,
                ':dados_json' => $dadosJson,
                ':id' => $existing['id'],
            ]);

            return ['action' => 'updated', 'id' => (int)$existing['id']];
        } else {
            // Insert
            $stmtInsert = $pdo->prepare("
                INSERT INTO `imoveis` (
                    `hash_imovel`, `fonte_slug`, `filtro_id`, `titulo`, `tipo`, `endereco`, `cidade`, `uf`,
                    `valor_avaliacao`, `valor_leilao`, `desconto`, `modalidade`, `data_encerramento`,
                    `data_inclusao`, `edital`, `link_matricula`, `numero_matricula`, `link_leiloeiro`,
                    `nome_leiloeiro`, `link_original`, `imagem`, `dados_json`, `status`, `criado_em`
                ) VALUES (
                    :hash, :fonte_slug, :filtro_id, :titulo, :tipo, :endereco, :cidade, :uf,
                    :valor_avaliacao, :valor_leilao, :desconto, :modalidade, :data_encerramento,
                    :data_inclusao, :edital, :link_matricula, :numero_matricula, :link_leiloeiro,
                    :nome_leiloeiro, :link_original, :imagem, :dados_json, 'ativo', NOW()
                )
            ");

            $stmtInsert->execute([
                ':hash' => $hash,
                ':fonte_slug' => $fonteSlug,
                ':filtro_id' => $filtroId,
                ':titulo' => $titulo,
                ':tipo' => $tipo,
                ':endereco' => $endereco,
                ':cidade' => $cidade,
                ':uf' => $uf,
                ':valor_avaliacao' => $valorAvaliacao,
                ':valor_leilao' => $valorLeilao,
                ':desconto' => $desconto,
                ':modalidade' => $modalidade,
                ':data_encerramento' => $dataEncerramento,
                ':data_inclusao' => $dataInclusao,
                ':edital' => $edital,
                ':link_matricula' => $linkMatricula,
                ':numero_matricula' => $numeroMatricula,
                ':link_leiloeiro' => $linkLeiloeiro,
                ':nome_leiloeiro' => $nomeLeiloeiro,
                ':link_original' => $linkOriginal,
                ':imagem' => $imagem,
                ':dados_json' => $dadosJson,
            ]);

            return ['action' => 'inserted', 'id' => (int)$pdo->lastInsertId()];
        }
    }

    /**
     * Busca imóveis salvos no banco local com paginação, multi-municípios, filtro por fonte e ordenação.
     */
    public static function getImoveisOffline(
        string $uf,
        string|array|null $municipios = null,
        ?string $tipo = null,
        int $pagina = 1,
        ?string $dataFinalLeilao = null,
        ?string $termoBusca = null,
        ?string $ordem = 'desconto_desc',
        ?string $fonte = null,
        int $limit = 20
    ): array {
        $pdo = self::getConnection();
        $offset = ($pagina - 1) * $limit;

        $where = ["`uf` = :uf", "`status` = 'ativo'"];
        $params = [':uf' => strtoupper($uf)];

        // Filtro por Fonte de Dados
        if (!empty($fonte) && $fonte !== 'todas') {
            $where[] = "`fonte_slug` = :fonte_slug";
            $params[':fonte_slug'] = strtolower(trim($fonte));
        }

        // Suporte a múltiplos municípios (array ou string separada por vírgula)
        if (!empty($municipios)) {
            $munList = is_array($municipios) ? $municipios : explode(',', (string)$municipios);
            $munList = array_values(array_filter(array_map('trim', $munList)));

            if (!empty($munList)) {
                $munClauses = [];
                foreach ($munList as $idx => $mun) {
                    $p1 = ":mun_name_{$idx}";
                    $p2 = ":mun_slug_{$idx}";
                    $munClauses[] = "(`cidade` LIKE {$p1} OR LOWER(REPLACE(`cidade`, ' ', '-')) = {$p2})";
                    $params[$p1] = '%' . str_replace('-', ' ', $mun) . '%';
                    $params[$p2] = strtolower($mun);
                }
                $where[] = '(' . implode(' OR ', $munClauses) . ')';
            }
        }

        if (!empty($tipo)) {
            $where[] = "`tipo` LIKE :tipo";
            $params[':tipo'] = '%' . $tipo . '%';
        }

        if (!empty($termoBusca)) {
            $where[] = "(`titulo` LIKE :termo OR `endereco` LIKE :termo OR `cidade` LIKE :termo OR `nome_leiloeiro` LIKE :termo)";
            $params[':termo'] = '%' . $termoBusca . '%';
        }

        if (!empty($dataFinalLeilao)) {
            // Normalizar data YYYY-MM-DD
            $formattedDate = trim($dataFinalLeilao);
            if (preg_match('#^(\d{2})/(\d{2})/(\d{4})$#', $formattedDate, $dm)) {
                $formattedDate = "{$dm[3]}-{$dm[2]}-{$dm[1]}";
            }
            // Converter para DD/MM/YYYY para comparar com data_encerramento em string se aplicável
            $dateBr = date('d/m/Y', strtotime($formattedDate));
            $where[] = "(`data_encerramento` LIKE :data_br OR `data_encerramento` <= :data_raw OR `data_encerramento` = '' OR `data_encerramento` IS NULL)";
            $params[':data_br'] = '%' . $dateBr . '%';
            $params[':data_raw'] = $formattedDate . ' 23:59:59';
        }

        $whereClause = implode(' AND ', $where);

        // Contar total
        $stmtCount = $pdo->prepare("SELECT COUNT(*) AS total FROM `imoveis` WHERE {$whereClause}");
        $stmtCount->execute($params);
        $total = (int)$stmtCount->fetchColumn();

        // Mapeamento de ordenações
        $orderBy = match ($ordem) {
            'desconto_asc' => "COALESCE(`desconto`, 0) ASC, `id` DESC",
            'valor_asc' => "COALESCE(`valor_leilao`, 999999999) ASC, `id` DESC",
            'valor_desc' => "COALESCE(`valor_leilao`, 0) DESC, `id` DESC",
            'avaliacao_desc' => "COALESCE(`valor_avaliacao`, 0) DESC, `id` DESC",
            'avaliacao_asc' => "COALESCE(`valor_avaliacao`, 999999999) ASC, `id` DESC",
            'encerramento_asc' => "CASE WHEN `data_encerramento` IS NULL OR `data_encerramento` = '' THEN 1 ELSE 0 END, `data_encerramento` ASC, `id` DESC",
            'encerramento_desc' => "`data_encerramento` DESC, `id` DESC",
            'recentes' => "`id` DESC",
            'antigos' => "`id` ASC",
            default => "COALESCE(`desconto`, 0) DESC, `id` DESC", // desconto_desc (padrão)
        };

        // Buscar registros ordenados
        $stmtSelect = $pdo->prepare("
            SELECT 
                `id`, `hash_imovel`, `fonte_slug`, `titulo`, `tipo`, `endereco`, `cidade`, `uf`,
                `valor_avaliacao`, `valor_leilao`, `desconto`, `modalidade`,
                `data_encerramento`, `data_inclusao`, `edital`, `link_matricula`,
                `numero_matricula`, `link_leiloeiro`, `nome_leiloeiro`,
                `link_original` AS `link`, `imagem`, `criado_em`, `atualizado_em`
            FROM `imoveis`
            WHERE {$whereClause}
            ORDER BY {$orderBy}
            LIMIT :limit OFFSET :offset
        ");

        foreach ($params as $k => $v) {
            $stmtSelect->bindValue($k, $v);
        }
        $stmtSelect->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmtSelect->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmtSelect->execute();

        $rows = $stmtSelect->fetchAll();

        $imoveis = array_map(function ($r) {
            return [
                'id' => (int)$r['id'],
                'fonte_slug' => $r['fonte_slug'] ?? 'leilaoimovel',
                'titulo' => $r['titulo'],
                'tipo' => $r['tipo'],
                'endereco' => $r['endereco'],
                'cidade' => $r['cidade'],
                'uf' => $r['uf'],
                'valor_avaliacao' => $r['valor_avaliacao'] !== null ? (float)$r['valor_avaliacao'] : null,
                'valor_leilao' => $r['valor_leilao'] !== null ? (float)$r['valor_leilao'] : null,
                'desconto' => $r['desconto'] !== null ? (float)$r['desconto'] : null,
                'modalidade' => $r['modalidade'],
                'data_encerramento' => $r['data_encerramento'],
                'data_inclusao' => $r['data_inclusao'],
                'edital' => $r['edital'],
                'link_matricula' => $r['link_matricula'],
                'numero_matricula' => $r['numero_matricula'],
                'link_leiloeiro' => $r['link_leiloeiro'],
                'nome_leiloeiro' => $r['nome_leiloeiro'],
                'link' => $r['link'],
                'imagem' => $r['imagem'],
                'origem' => 'banco_offline',
                'atualizado_em' => $r['atualizado_em'],
            ];
        }, $rows);

        $totalPages = (int)ceil($total / $limit);

        return [
            'success' => true,
            'origem' => 'banco_offline',
            'data' => $imoveis,
            'total' => $total,
            'pagina_atual' => $pagina,
            'total_paginas' => max(1, $totalPages),
            'itens_nesta_pagina' => count($imoveis),
            'filtros' => [
                'uf' => strtoupper($uf),
                'municipio' => $municipios,
                'tipo' => $tipo,
                'data_final_leilao' => $dataFinalLeilao,
                's' => $termoBusca,
                'ordem' => $ordem,
                'fonte' => $fonte,
            ],
        ];
    }

    // ==================== Gerenciamento de Fontes de Dados ====================

    public static function getFontes(): array
    {
        $pdo = self::getConnection();
        $stmt = $pdo->query("
            SELECT 
                f.*,
                (SELECT COUNT(*) FROM `imoveis` i WHERE i.`fonte_slug` = f.`slug`) AS `total_imoveis`
            FROM `fontes_dados` f
            ORDER BY f.`id` ASC
        ");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public static function salvarFonte(array $dados): array
    {
        $pdo = self::getConnection();
        $id = !empty($dados['id']) ? (int)$dados['id'] : null;
        $slug = preg_replace('/[^a-z0-9_-]/', '', strtolower($dados['slug'] ?? ''));
        $nome = trim($dados['nome'] ?? '');
        $urlBase = trim($dados['url_base'] ?? '');
        $descricao = trim($dados['descricao'] ?? '');
        $driverClass = trim($dados['driver_class'] ?? 'GenericSource');
        $ativo = isset($dados['ativo']) ? (int)(bool)$dados['ativo'] : 1;
        $configJson = !empty($dados['config']) ? json_encode($dados['config'], JSON_UNESCAPED_UNICODE) : null;

        if (empty($slug) || empty($nome) || empty($urlBase)) {
            return ['success' => false, 'error' => 'Campos obrigatórios: slug, nome e url_base.'];
        }

        if ($id) {
            $stmt = $pdo->prepare("
                UPDATE `fontes_dados` SET
                    `nome` = :nome,
                    `url_base` = :url_base,
                    `descricao` = :descricao,
                    `driver_class` = :driver_class,
                    `config_json` = :config_json,
                    `ativo` = :ativo,
                    `atualizado_em` = NOW()
                WHERE `id` = :id
            ");
            $stmt->execute([
                ':nome' => $nome,
                ':url_base' => $urlBase,
                ':descricao' => $descricao,
                ':driver_class' => $driverClass,
                ':config_json' => $configJson,
                ':ativo' => $ativo,
                ':id' => $id,
            ]);
            return ['success' => true, 'message' => 'Fonte de dados atualizada com sucesso!', 'id' => $id];
        } else {
            // Verificar duplicidade de slug
            $stmtCheck = $pdo->prepare("SELECT id FROM `fontes_dados` WHERE `slug` = :slug LIMIT 1");
            $stmtCheck->execute([':slug' => $slug]);
            if ($stmtCheck->fetch()) {
                return ['success' => false, 'error' => "Já existe uma fonte cadastrada com o slug '{$slug}'."];
            }

            $stmt = $pdo->prepare("
                INSERT INTO `fontes_dados` (`slug`, `nome`, `url_base`, `descricao`, `driver_class`, `config_json`, `ativo`, `criado_em`)
                VALUES (:slug, :nome, :url_base, :descricao, :driver_class, :config_json, :ativo, NOW())
            ");
            $stmt->execute([
                ':slug' => $slug,
                ':nome' => $nome,
                ':url_base' => $urlBase,
                ':descricao' => $descricao,
                ':driver_class' => $driverClass,
                ':config_json' => $configJson,
                ':ativo' => $ativo,
            ]);
            return ['success' => true, 'message' => 'Fonte de dados cadastrada com sucesso!', 'id' => (int)$pdo->lastInsertId()];
        }
    }

    public static function toggleFonte(int $id, bool $ativo): array
    {
        $pdo = self::getConnection();
        $stmt = $pdo->prepare("UPDATE `fontes_dados` SET `ativo` = :ativo, `atualizado_em` = NOW() WHERE `id` = :id");
        $stmt->execute([
            ':ativo' => $ativo ? 1 : 0,
            ':id' => $id,
        ]);
        return ['success' => true, 'message' => $ativo ? 'Fonte ativada com sucesso!' : 'Fonte pausada com sucesso!'];
    }

    public static function excluirFonte(int $id): array
    {
        $pdo = self::getConnection();
        // Proteger a fonte padrão leilaoimovel de exclusão acidental
        $stmtCheck = $pdo->prepare("SELECT slug FROM `fontes_dados` WHERE `id` = :id LIMIT 1");
        $stmtCheck->execute([':id' => $id]);
        $fonte = $stmtCheck->fetch();

        if (!$fonte) {
            return ['success' => false, 'error' => 'Fonte não encontrada.'];
        }
        if ($fonte['slug'] === 'leilaoimovel') {
            return ['success' => false, 'error' => 'A fonte padrão "Leilão Imóvel" não pode ser excluída, apenas pausada.'];
        }

        $stmt = $pdo->prepare("DELETE FROM `fontes_dados` WHERE `id` = :id");
        $stmt->execute([':id' => $id]);
        return ['success' => true, 'message' => 'Fonte excluída com sucesso!'];
    }
}
