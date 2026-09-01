<?php
declare(strict_types=1);

namespace App\Sources;

use Database;
use Scraper;
use PDO;

require_once __DIR__ . '/SourceInterface.php';
require_once __DIR__ . '/LeilaoImovelSource.php';
require_once __DIR__ . '/ZukermanSource.php';
require_once __DIR__ . '/CaixaSource.php';
require_once __DIR__ . '/SmartLeiloesCaixaSource.php';
require_once __DIR__ . '/BancoDoBrasilSource.php';
require_once __DIR__ . '/SantanderSource.php';
require_once __DIR__ . '/BradescoSource.php';
require_once __DIR__ . '/BankSource.php';
require_once __DIR__ . '/GenericSource.php';

/**
 * Gerenciador Central de Fontes de Dados (Multi-Source Hub).
 */
class SourceManager
{
    /**
     * Retorna a lista de todas as fontes cadastradas no banco com contagem de imóveis e status.
     */
    public static function listAll(): array
    {
        $pdo = Database::getConnection();
        
        $stmt = $pdo->query("
            SELECT 
                f.*,
                (SELECT COUNT(*) FROM `imoveis` i WHERE i.`fonte_slug` = f.`slug`) AS `total_imoveis`
            FROM `fontes_dados` f
            ORDER BY f.`id` ASC
        ");
        
        $fontes = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return array_map(function ($f) {
            return [
                'id' => (int)$f['id'],
                'slug' => $f['slug'],
                'nome' => $f['nome'],
                'url_base' => $f['url_base'],
                'descricao' => $f['descricao'],
                'ativo' => (bool)$f['ativo'],
                'driver_class' => $f['driver_class'],
                'config' => !empty($f['config_json']) ? json_decode($f['config_json'], true) : [],
                'total_imoveis' => (int)($f['total_imoveis'] ?? 0),
                'ultima_coleta_em' => $f['ultima_coleta_em'],
                'criado_em' => $f['criado_em'],
            ];
        }, $fontes);
    }

    /**
     * Retorna uma fonte ativa específica ou o driver padrão.
     */
    public static function getDriver(string $slug): ?SourceInterface
    {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM `fontes_dados` WHERE `slug` = :slug LIMIT 1");
        $stmt->execute([':slug' => $slug]);
        $fonte = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$fonte || !(bool)$fonte['ativo']) {
            return null;
        }

        return self::instantiateDriver($fonte);
    }

    /**
     * Retorna todos os drivers ativos para execução paralela ou sequencial de coletas.
     * @return SourceInterface[]
     */
    public static function getActiveDrivers(): array
    {
        $pdo = Database::getConnection();
        $stmt = $pdo->query("SELECT * FROM `fontes_dados` WHERE `ativo` = 1 ORDER BY `id` ASC");
        $fontes = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $drivers = [];
        foreach ($fontes as $fonte) {
            $driver = self::instantiateDriver($fonte);
            if ($driver) {
                $drivers[] = $driver;
            }
        }

        return $drivers;
    }

    /**
     * Instancia o driver correspondente à fonte.
     */
    private static function instantiateDriver(array $fonte): SourceInterface
    {
        $slug = $fonte['slug'];
        $nome = $fonte['nome'];
        $urlBase = $fonte['url_base'];
        $driverClass = $fonte['driver_class'] ?? 'GenericSource';
        $config = !empty($fonte['config_json']) ? json_decode($fonte['config_json'], true) : [];

        if ($slug === 'leilaoimovel' || $driverClass === 'LeilaoImovelSource') {
            return new LeilaoImovelSource();
        }

        if ($slug === 'caixa' || $driverClass === 'CaixaSource') {
            return new CaixaSource();
        }

        if ($slug === 'zukerman' || $driverClass === 'ZukermanSource') {
            return new ZukermanSource();
        }

        if ($slug === 'smartleiloescaixa' || $driverClass === 'SmartLeiloesCaixaSource') {
            return new SmartLeiloesCaixaSource();
        }

        if ($slug === 'bancodobrasil' || $driverClass === 'BancoDoBrasilSource') {
            return new BancoDoBrasilSource();
        }

        if ($slug === 'santander' || $driverClass === 'SantanderSource') {
            return new SantanderSource();
        }

        if ($slug === 'bradesco' || $driverClass === 'BradescoSource') {
            return new BradescoSource();
        }

        if (in_array($slug, ['itau', 'bancointer', 'sicredi']) || $driverClass === 'BankSource') {
            return new BankSource($slug, $nome, $urlBase, $config);
        }

        return new GenericSource($slug, $nome, $urlBase, $config);
    }

    /**
     * Atualiza o timestamp de última coleta e contagem de uma fonte.
     */
    public static function registrarColeta(string $slug, int $novosImoveis = 0): void
    {
        try {
            $pdo = Database::getConnection();
            $stmt = $pdo->prepare("
                UPDATE `fontes_dados` SET
                    `ultima_coleta_em` = NOW(),
                    `total_imoveis_coletados` = `total_imoveis_coletados` + :novos
                WHERE `slug` = :slug
            ");
            $stmt->execute([
                ':novos' => $novosImoveis,
                ':slug' => $slug,
            ]);
        } catch (\Throwable $e) {
            // Silencioso
        }
    }

    public static function recordScrapeSuccess(string $slug, int $novosImoveis = 0): void
    {
        self::registrarColeta($slug, $novosImoveis);
    }
}
