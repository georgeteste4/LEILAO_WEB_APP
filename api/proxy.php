<?php
/**
 * Proxy CORS para bypass do Cloudflare.
 * 
 * Estratégia: O frontend abre o site no iframe oculto primeiro para resolver o 
 * challenge do Cloudflare, e depois as requisições passam pelos cookies.
 * 
 * Alternativa usada aqui: O PHP atua como proxy transparente, 
 * repassando cookies do Cloudflare obtidos pelo navegador do usuário.
 */
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$targetUrl = $_GET['url'] ?? '';
if (empty($targetUrl)) {
    echo json_encode(['error' => 'URL não fornecida']);
    exit;
}

// Validar que a URL é do domínio permitido
if (!str_starts_with($targetUrl, 'https://www.leilaoimovel.com.br/')) {
    echo json_encode(['error' => 'Domínio não permitido']);
    exit;
}

// Repassar cookies do Cloudflare se fornecidos
$cfCookies = $_GET['cf_cookies'] ?? $_SERVER['HTTP_X_CF_COOKIES'] ?? '';

$ch = curl_init();
$headers = [
    'Accept: application/json, text/html, */*',
    'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
    'Connection: keep-alive',
    'Referer: https://www.leilaoimovel.com.br/',
];

$opts = [
    CURLOPT_URL => $targetUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_USERAGENT => $_SERVER['HTTP_USER_AGENT'] ?? 'Mozilla/5.0',
    CURLOPT_HTTPHEADER => $headers,
    CURLOPT_ENCODING => '',
    CURLOPT_SSL_VERIFYPEER => false,
];

if (!empty($cfCookies)) {
    $opts[CURLOPT_COOKIE] = $cfCookies;
}

curl_setopt_array($ch, $opts);
$resp = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

http_response_code($code);
echo $resp;
