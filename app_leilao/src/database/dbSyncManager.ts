import { getDatabase, seedDatabase } from './database';
import { upsertImovel } from './imoveisRepository';
import { Imovel } from '../types';

const GITHUB_SEED_URL = 'https://raw.githubusercontent.com/georgeteste4/LEILAO_WEB_APP/main/data/seed_imoveis.json';

export async function syncDatabaseFromGitHub(onProgress?: (progress: number, total: number) => void) {
  console.log('🔄 Baixando base de dados atualizada do GitHub...');
  const response = await fetch(GITHUB_SEED_URL);
  if (!response.ok) {
    throw new Error('Falha ao baixar dados do GitHub. HTTP ' + response.status);
  }
  const imoveis: Imovel[] = await response.json();
  let imported = 0;
  let updated = 0;

  for (let i = 0; i < imoveis.length; i++) {
    const res = await upsertImovel(imoveis[i]);
    if (res.action === 'inserted') imported++;
    if (res.action === 'updated') updated++;
    if (onProgress && i % 10 === 0) {
      onProgress(i + 1, imoveis.length);
    }
  }

  return {
    total: imoveis.length,
    novos: imported,
    atualizados: updated
  };
}

export async function exportDatabaseToJson(): Promise<string> {
  const db = await getDatabase();
  const rows = await db.getAllAsync<Imovel>('SELECT * FROM imoveis ORDER BY id DESC');
  return JSON.stringify(rows, null, 2);
}

export async function restoreDefaultSeed() {
  const db = await getDatabase();
  await db.runAsync('DELETE FROM imoveis');
  await seedDatabase(db);
}
