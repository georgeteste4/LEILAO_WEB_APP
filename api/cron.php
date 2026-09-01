<?php
declare(strict_types=1);

/**
 * Script de Execução de Tarefas em Cron (ou Download Completo sob Demanda).
 * 
 * Modos de Execução:
 * 
 * 1. Via Navegador / URL:
 *    GET /api/cron.php?filter_id=1&token=TOKEN_DO_FILTRO
 *    GET /api/cron.php?all=1&token=TOKEN_MESTRE
 * 
 * 2. Via Linha de Comando (CLI / Agendador do Windows / Cron Linux):
 *    php api/cron.php --filter_id=1
 *    php api/cron.php --all
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Scraper.php';
require_once __DIR__ . '/sources/SourceManager.php';

use App\Sources\SourceManager;

// Configurações de execução
set_time_limit(0);
ignore_user_abort(true);
ini_set('memory_limit', '512M');

$isCli = (php_sapi_name() === 'cli');
$options = $isCli ? getopt('', ['filter_id:', 'all', 'token:']) : [];

$filterId = null;
if (isset($_GET['filter_id'])) {
    $filterId = (int)$_GET['filter_id'];
} elseif (isset($options['filter_id'])) {
    $filterId = (int)$options['filter_id'];
}

$runAll = false;
if (isset($_GET['all']) && ($_GET['all'] === '1' || $_GET['all'] === 'true')) {
    $runAll = true;
} elseif (isset($options['all'])) {
    $runAll = true;
}

$token = $_GET['token'] ?? $options['token'] ?? '';
if ($isCli && empty($token)) {
    $token = CRON_MASTER_TOKEN;
}

if (!$isCli) {
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
}

$pdo = Database::getConnection();
$scraper = new Scraper();

$results = [];

// Obter filtros a executar
$filtrosParaExecutar = [];

if ($filterId !== null) {
    $stmt = $pdo->prepare("SELECT * FROM `filtros_salvos` WHERE `id` = :id LIMIT 1");
    $stmt->execute([':id' => $filterId]);
    $f = $stmt->fetch();

    if (!$f) {
        respond(['success' => false, 'error' => "Filtro #{$filterId} não encontrado."], $isCli, 404);
        exit;
    }

    // Validar token se não for CLI
    if (!$isCli && $token !== CRON_MASTER_TOKEN && $token !== $f['cron_token']) {
        respond(['success' => false, 'error' => "Token inválido para o filtro #{$filterId}."], $isCli, 403);
        exit;
    }

    $filtrosParaExecutar[] = $f;
} elseif ($runAll) {
    if (!$isCli && $token !== CRON_MASTER_TOKEN) {
        respond(['success' => false, 'error' => "Acesso não autorizado para executar todos os filtros."], $isCli, 403);
        exit;
    }

    $stmt = $pdo->query("SELECT * FROM `filtros_salvos` WHERE `ativo` = 1 ORDER BY `id` ASC");
    $filtrosParaExecutar = $stmt->fetchAll();

    if (empty($filtrosParaExecutar)) {
        respond(['success' => true, 'message' => "Nenhum filtro ativo cadastrado para execução.", 'results' => []], $isCli);
        exit;
    }
} else {
    respond([
        'success' => false,
        'error' => "Especifique ?filter_id=ID&token=TOKEN ou ?all=1&token=TOKEN_MESTRE",
        'exemplo' => "/api/cron.php?filter_id=1&token=" . CRON_MASTER_TOKEN
    ], $isCli, 400);
    exit;
}

// Executar cada filtro
foreach ($filtrosParaExecutar as $filtro) {
    $inicio = microtime(true);
    $fId = (int)$filtro['id'];
    $nome = $filtro['nome'];
    $uf = strtolower($filtro['uf']);
    $municipio = $filtro['municipio'];
    $tipo = $filtro['tipo'];
    $dataFinal = $filtro['data_final_leilao'];
    $termo = $filtro['termo_busca'];
    $fontes = !empty($filtro['fontes']) ? json_decode($filtro['fontes'], true) : ['leilaoimovel'];
    if (empty($fontes) || !is_array($fontes)) {
        $fontes = ['leilaoimovel'];
    }

    logMsg("Iniciando download para o filtro #{$fId} ('{$nome}') em [" . implode(', ', $fontes) . "]...", $isCli);

    $totalNovos = 0;
    $totalAtualizados = 0;
    $totalImoveisProcessados = 0;
    $status = 'sucesso';
    $detalhesLog = [];

    // Executar em cada fonte configurada
    foreach ($fontes as $fonteSlug) {
        $driver = SourceManager::getDriver($fonteSlug);
        if (!$driver) {
            logMsg("  [AVISO] Fonte '{$fonteSlug}' não encontrada ou inativa. Pulando...", $isCli);
            continue;
        }

        logMsg("  -> Executando extração na fonte: {$driver->getNome()} ({$fonteSlug})...", $isCli);

        $pagina = 1;
        $maxPaginas = 1;

        do {
            logMsg("     -> Baixando página {$pagina} de {$maxPaginas}...", $isCli);

            $res = $driver->scrapeImoveis($scraper, [
                'uf' => $uf,
                'municipio' => $municipio,
                'tipo' => $tipo,
                'pagina' => $pagina,
                'data_final_leilao' => $dataFinal,
                's' => $termo,
            ]);

            if (!$res['success']) {
                $status = 'erro';
                $msgErro = "Erro na fonte {$fonteSlug}, página {$pagina}: " . ($res['error'] ?? 'Falha');
                $detalhesLog[] = $msgErro;
                logMsg("     [ERRO] " . $msgErro, $isCli);
                break;
            }

            $maxPaginas = $res['total_paginas'] ?? 1;
            $imoveis = $res['data'] ?? [];

            foreach ($imoveis as $imovel) {
                $imovel['fonte_slug'] = $fonteSlug;
                $up = Database::upsertImovel($imovel, $fId);
                if ($up['action'] === 'inserted') {
                    $totalNovos++;
                } elseif ($up['action'] === 'updated') {
                    $totalAtualizados++;
                }
                $totalImoveisProcessados++;
            }

            $pagina++;
            usleep(300000); // 300ms entre requisições
        } while ($pagina <= $maxPaginas);

        SourceManager::recordScrapeSuccess($fonteSlug, $totalImoveisProcessados);
    }

    $tempoTotal = round(microtime(true) - $inicio, 2);

    // Atualizar dados do filtro salvo
    $stmtUpFiltro = $pdo->prepare("
        UPDATE `filtros_salvos` SET 
            `total_execucoes` = `total_execucoes` + 1,
            `total_imoveis_salvos` = (SELECT COUNT(*) FROM `imoveis` WHERE `filtro_id` = :f_id1),
            `ultima_execucao_em` = NOW()
        WHERE `id` = :f_id2
    ");
    $stmtUpFiltro->execute([':f_id1' => $fId, ':f_id2' => $fId]);

    // Gravar log da execução
    $stmtLog = $pdo->prepare("
        INSERT INTO `logs_cron` (
            `filtro_id`, `status`, `total_paginas`, `total_imoveis`, `novos`, `atualizados`, `tempo_segundos`, `detalhes`, `executado_em`
        ) VALUES (
            :filtro_id, :status, :total_paginas, :total_imoveis, :novos, :atualizados, :tempo_segundos, :detalhes, NOW()
        )
    ");
    $stmtLog->execute([
        ':filtro_id' => $fId,
        ':status' => $status,
        ':total_paginas' => min($pagina - 1, $maxPaginas),
        ':total_imoveis' => $totalImoveisProcessados,
        ':novos' => $totalNovos,
        ':atualizados' => $totalAtualizados,
        ':tempo_segundos' => $tempoTotal,
        ':detalhes' => implode(' | ', $detalhesLog) ?: 'Executado com sucesso',
    ]);

    $resItem = [
        'filtro_id' => $fId,
        'nome' => $nome,
        'status' => $status,
        'paginas_processadas' => min($pagina - 1, $maxPaginas),
        'total_imoveis' => $totalImoveisProcessados,
        'novos' => $totalNovos,
        'atualizados' => $totalAtualizados,
        'duracao_segundos' => $tempoTotal,
    ];

    $results[] = $resItem;
    logMsg("Filtro #{$fId} finalizado em {$tempoTotal}s: {$totalNovos} novos, {$totalAtualizados} atualizados.", $isCli);
}

respond([
    'success' => true,
    'mensagem' => 'Execução do Cron concluída.',
    'execucoes' => $results,
], $isCli);

// ==================== Funções Utilitárias ====================

function respond(array $data, bool $isCli, int $httpCode = 200): void
{
    if ($isCli) {
        echo "\n=== RESULTADO FINAL ===\n";
        echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
    } else {
        http_response_code($httpCode);
        echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    }
}

function logMsg(string $msg, bool $isCli): void
{
    if ($isCli) {
        echo date('[Y-m-d H:i:s] ') . $msg . "\n";
    }
}
