import { getDatabase } from './database';
import { FiltroSalvo } from '../types';

export async function getFiltros(): Promise<FiltroSalvo[]> {
  const db = await getDatabase();
  const rows: any[] = (await db.getAllAsync(`
    SELECT f.*, 
    (SELECT COUNT(*) FROM imoveis i WHERE i.filtro_id = f.id) as total_imoveis_salvos 
    FROM filtros_salvos f 
    ORDER BY f.id DESC
  `)) || [];
  return rows.map((r: any) => ({
    ...r,
    ativo: Boolean(r.ativo),
    fontes: typeof r.fontes === 'string' ? JSON.parse(r.fontes || '["leilaoimovel"]') : (r.fontes || ['leilaoimovel'])
  }));
}

export async function salvarFiltro(filtro: Partial<FiltroSalvo>): Promise<number> {
  const db = await getDatabase();
  const fontesStr = JSON.stringify(filtro.fontes || ['leilaoimovel']);
  const token = filtro.cron_token || 'token_' + Date.now();

  if (filtro.id) {
    await db.runAsync(
      `UPDATE filtros_salvos SET
        nome = ?, uf = ?, municipio = ?, tipo = ?, data_final_leilao = ?,
        termo_busca = ?, fontes = ?, ativo = ?, atualizado_em = CURRENT_TIMESTAMP
      WHERE id = ?`,
      [
        filtro.nome,
        filtro.uf,
        filtro.municipio || null,
        filtro.tipo || null,
        filtro.data_final_leilao || null,
        filtro.termo_busca || null,
        fontesStr,
        filtro.ativo ? 1 : 0,
        filtro.id
      ]
    );
    return filtro.id;
  } else {
    const res: any = await db.runAsync(
      `INSERT INTO filtros_salvos (
        nome, uf, municipio, tipo, data_final_leilao, termo_busca, fontes, cron_token, ativo
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
      [
        filtro.nome,
        filtro.uf,
        filtro.municipio || null,
        filtro.tipo || null,
        filtro.data_final_leilao || null,
        filtro.termo_busca || null,
        fontesStr,
        token
      ]
    );
    return res.lastInsertRowId;
  }
}

export async function excluirFiltro(id: number): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('DELETE FROM filtros_salvos WHERE id = ?', [id]);
}
