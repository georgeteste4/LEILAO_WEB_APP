<?php
declare(strict_types=1);

// Configurações do Scraper de Leilão de Imóveis

define('BASE_URL', 'https://www.leilaoimovel.com.br');
define('LEILAO_PATH', '/leilao-de-imoveis');

// =========================================================================
// BANCO DE DADOS MYSQL (Laragon / Servidor Local)
// =========================================================================
define('DB_HOST', '127.0.0.1');
define('DB_PORT', 3306);
define('DB_NAME', 'leilao_app');
define('DB_USER', 'root');
define('DB_PASS', '');

// Chave mestra para execução de tarefas em Cron via Web/CLI
define('CRON_MASTER_TOKEN', 'leilao_cron_sec_' . md5('leilao_app_master_key_2026'));

// =========================================================================
// POOL DE TOKENS - SCRAPE.DO & FIRECRAWL
// Você pode adicionar quantos tokens quiser em cada array!
// =========================================================================
define('SCRAPE_DO_TOKENS', [
    '40a83d8791a8412a8eeeb57046f34b2e3b9b9532d8b',
    // Adicione mais tokens do scrape.do aqui:
    // 'outro_token_scrape_do_1',
    // 'outro_token_scrape_do_2',
]);

define('FIRECRAWL_TOKENS', [
    'fc-02bb7f91511144a4a550f149ff566c95',
    // Adicione mais tokens do firecrawl aqui:
    // 'fc-outro_token_firecrawl_1',
    // 'fc-outro_token_firecrawl_2',
]);

// Ordem prioritária de provedores ('scrape_do' primeiro, depois 'firecrawl')
define('PROVIDER_PRIORITY', ['scrape_do', 'firecrawl']);

// User-Agent padrão
define('USER_AGENT', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36');

// Tempo limite para requisições de scraping (segundos)
define('SCRAPER_TIMEOUT', 45);

// Cache TTL em segundos (30 minutos para listagens, 2 horas para estados/cidades)
define('CACHE_TTL', 1800);
define('CACHE_TTL_LOCATIONS', 7200);
define('CACHE_DIR', __DIR__ . '/../cache');

// Arquivo que guarda o status de saúde dos tokens (tokens desativados temporariamente)
define('TOKEN_HEALTH_FILE', CACHE_DIR . '/tokens_health.json');

// Tempo para retestar um token desativado (segundos) - 1 hora
define('TOKEN_DISABLE_TIME', 3600);

// Estados brasileiros (Fallback)
define('ESTADOS', [
    'ac' => 'Acre',
    'al' => 'Alagoas',
    'ap' => 'Amapá',
    'am' => 'Amazonas',
    'ba' => 'Bahia',
    'ce' => 'Ceará',
    'df' => 'Distrito Federal',
    'es' => 'Espírito Santo',
    'go' => 'Goiás',
    'ma' => 'Maranhão',
    'mt' => 'Mato Grosso',
    'ms' => 'Mato Grosso do Sul',
    'mg' => 'Minas Gerais',
    'pa' => 'Pará',
    'pb' => 'Paraíba',
    'pr' => 'Paraná',
    'pe' => 'Pernambuco',
    'pi' => 'Piauí',
    'rj' => 'Rio de Janeiro',
    'rn' => 'Rio Grande do Norte',
    'rs' => 'Rio Grande do Sul',
    'ro' => 'Rondônia',
    'rr' => 'Roraima',
    'sc' => 'Santa Catarina',
    'sp' => 'São Paulo',
    'se' => 'Sergipe',
    'to' => 'Tocantins',
]);

// Tipos de imóveis disponíveis
define('TIPOS_IMOVEL', [
    'apartamento' => 'Apartamento',
    'casa' => 'Casa',
    'terreno' => 'Terreno',
    'rural' => 'Imóvel Rural',
    'comercial' => 'Comercial',
    'garagem' => 'Garagem',
    'galpao' => 'Galpão',
]);
