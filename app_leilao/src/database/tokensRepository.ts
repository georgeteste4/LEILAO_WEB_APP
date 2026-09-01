import { getDatabase } from './database';
import { ScraperToken } from '../types';

export async function getTokens(): Promise<ScraperToken[]> {
  const db = await getDatabase();
  const rows: any[] = (await db.getAllAsync('SELECT * FROM config_tokens ORDER BY id DESC')) || [];
  return rows;
}

export async function addToken(provider: 'scrape_do' | 'firecrawl', token: string) {
  const db = await getDatabase();
  await db.runAsync(
    'INSERT INTO config_tokens (provider, token, status) VALUES (?, ?, ?)',
    [provider, token.trim(), 'ativo']
  );
}

export async function updateTokenStatus(id: number, status: ScraperToken['status']) {
  const db = await getDatabase();
  await db.runAsync('UPDATE config_tokens SET status = ? WHERE id = ?', [status, id]);
}

export async function removeToken(id: number) {
  const db = await getDatabase();
  await db.runAsync('DELETE FROM config_tokens WHERE id = ?', [id]);
}
