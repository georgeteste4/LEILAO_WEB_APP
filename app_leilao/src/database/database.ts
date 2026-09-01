import { Platform } from 'react-native';
import { CREATE_TABLES_SQL } from './schema';
import seedImoveis from '../../data/seed_imoveis.json';
import seedFontes from '../../data/seed_fontes.json';
import seedFiltros from '../../data/seed_filtros.json';
import { Imovel } from '../types';

let dbInstance: any = null;

class WebSqlFallback {
  private tables: Record<string, any[]> = {
    imoveis: [],
    filtros_salvos: [],
    logs_cron: [],
    fontes_dados: [],
    config_tokens: [],
    app_settings: []
  };

  async execAsync(sql: string): Promise<boolean> {
    return true;
  }

  async getAllAsync(sql: string, params: any[] = []): Promise<any[]> {
    if (sql.includes('FROM imoveis')) return this.tables.imoveis;
    if (sql.includes('FROM filtros_salvos')) return this.tables.filtros_salvos;
    if (sql.includes('FROM fontes_dados')) return this.tables.fontes_dados;
    if (sql.includes('FROM logs_cron')) return this.tables.logs_cron;
    if (sql.includes('FROM config_tokens')) return this.tables.config_tokens;
    return [];
  }

  async getFirstAsync(sql: string, params: any[] = []): Promise<any> {
    const list = await this.getAllAsync(sql, params);
    return list.length > 0 ? list[0] : null;
  }

  async runAsync(sql: string, params: any[] = []): Promise<any> {
    return { lastInsertRowId: Date.now(), changes: 1 };
  }

  setSeedData(imoveis: any[], fontes: any[], filtros: any[]) {
    this.tables.imoveis = [...imoveis];
    this.tables.fontes_dados = [...fontes];
    this.tables.filtros_salvos = [...filtros];
  }
}

export async function getDatabase(): Promise<any> {
  if (dbInstance) return dbInstance;

  if (Platform.OS === 'web') {
    const webDb = new WebSqlFallback();
    webDb.setSeedData(seedImoveis, seedFontes, seedFiltros);
    dbInstance = webDb;
    return dbInstance;
  }

  try {
    const SQLite = require('expo-sqlite');
    const db = await SQLite.openDatabaseAsync('leilao_app.db');
    await db.execAsync('PRAGMA journal_mode = WAL;');
    await db.execAsync(CREATE_TABLES_SQL);

    const countRow: any = await db.getFirstAsync('SELECT COUNT(*) as count FROM imoveis');
    if (!countRow || countRow.count === 0) {
      await seedDatabase(db);
    }

    dbInstance = db;
    return dbInstance;
  } catch (error) {
    console.error('Erro ao inicializar SQLite nativo, fallback ativado:', error);
    const webDb = new WebSqlFallback();
    webDb.setSeedData(seedImoveis, seedFontes, seedFiltros);
    dbInstance = webDb;
    return dbInstance;
  }
}


export async function seedDatabase(db: any) {
  console.log('🌱 Inicializando banco SQLite com dados de seed...');
  
  for (const f of seedFontes) {
    await db.runAsync(
      'INSERT OR IGNORE INTO fontes_dados (slug, nome, url_base, descricao, ativo, driver_class) VALUES (?, ?, ?, ?, ?, ?)',
      [f.slug, f.nome, f.url_base, f.descricao, f.ativo, f.driver_class]
    );
  }

  for (const flt of seedFiltros) {
    await db.runAsync(
      'INSERT OR IGNORE INTO filtros_salvos (id, nome, uf, municipio, tipo, termo_busca, fontes, cron_token, ativo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)',
      [flt.id, flt.nome, flt.uf, flt.municipio, flt.tipo, flt.termo_busca, flt.fontes, 'token_' + flt.id]
    );
  }

  for (const im of (seedImoveis as Imovel[])) {
    await db.runAsync(
      `INSERT OR IGNORE INTO imoveis (
        hash_imovel, fonte_slug, titulo, tipo, endereco, cidade, uf,
        valor_avaliacao, valor_leilao, desconto, modalidade, data_encerramento,
        edital, link_matricula, link_original, imagem, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ativo')`,
      [
        im.hash_imovel || '',
        im.fonte_slug || 'leilaoimovel',
        im.titulo,
        im.tipo,
        im.endereco || '',
        im.cidade || '',
        im.uf || 'MA',
        im.valor_avaliacao,
        im.valor_leilao,
        im.desconto,
        im.modalidade || 'Leilão',
        im.data_encerramento || '',
        im.edital || null,
        im.link_matricula || null,
        im.link || '',
        im.imagem || ''
      ]
    );
  }

  console.log(`✅ ${seedImoveis.length} imóveis importados com sucesso para o SQLite!`);
}
