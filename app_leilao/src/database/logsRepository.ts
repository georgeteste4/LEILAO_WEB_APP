import { getDatabase } from './database';
import { LogCron } from '../types';

export async function getLogs(): Promise<LogCron[]> {
  const db = await getDatabase();
  const rows: any[] = (await db.getAllAsync(`
    SELECT l.*, COALESCE(f.nome, 'Rotina Manual') as filtro_nome
    FROM logs_cron l
    LEFT JOIN filtros_salvos f ON f.id = l.filtro_id
    ORDER BY l.id DESC
    LIMIT 50
  `)) || [];
  return rows;
}

export async function salvarLog(log: Omit<LogCron, 'id' | 'executado_em'>): Promise<void> {
  const db = await getDatabase();
  await db.runAsync(
    `INSERT INTO logs_cron (
      filtro_id, status, total_paginas, total_imoveis, novos, atualizados, tempo_segundos, detalhes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      log.filtro_id || null,
      log.status,
      log.total_paginas,
      log.total_imoveis,
      log.novos,
      log.atualizados,
      log.tempo_segundos,
      log.detalhes || null
    ]
  );
}
