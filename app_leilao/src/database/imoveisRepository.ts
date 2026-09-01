import { getDatabase } from './database';
import { Imovel } from '../types';

export interface GetImoveisOptions {
  uf: string;
  municipios?: string[];
  tipo?: string;
  fonte?: string;
  dataFinal?: string;
  termoBusca?: string;
  ordem?: string;
  pagina?: number;
  limit?: number;
}

export async function getImoveisOffline(options: GetImoveisOptions) {
  const db = await getDatabase();
  const {
    uf,
    municipios = [],
    tipo,
    fonte,
    dataFinal,
    termoBusca,
    ordem = 'desconto_desc',
    pagina = 1,
    limit = 20
  } = options;

  const offset = (pagina - 1) * limit;
  const where: string[] = ["uf = ?", "status = 'ativo'"];
  const params: any[] = [uf.toUpperCase()];

  if (fonte && fonte !== 'todas') {
    where.push("fonte_slug = ?");
    params.push(fonte.toLowerCase());
  }

  if (municipios && municipios.length > 0) {
    const munClauses = municipios.map(() => "(cidade LIKE ? OR LOWER(REPLACE(cidade, ' ', '-')) = ?)");
    where.push("(" + munClauses.join(" OR ") + ")");
    for (const m of municipios) {
      params.push('%' + m.replace(/-/g, ' ') + '%');
      params.push(m.toLowerCase());
    }
  }

  if (tipo) {
    where.push("tipo LIKE ?");
    params.push('%' + tipo + '%');
  }

  if (termoBusca) {
    where.push("(titulo LIKE ? OR endereco LIKE ? OR cidade LIKE ? OR nome_leiloeiro LIKE ?)");
    params.push('%' + termoBusca + '%');
    params.push('%' + termoBusca + '%');
    params.push('%' + termoBusca + '%');
    params.push('%' + termoBusca + '%');
  }

  if (dataFinal) {
    where.push("(data_encerramento LIKE ? OR data_encerramento <= ? OR data_encerramento = '' OR data_encerramento IS NULL)");
    params.push('%' + dataFinal + '%');
    params.push(dataFinal + ' 23:59:59');
  }

  const whereClause = where.join(" AND ");

  const countSql = "SELECT COUNT(*) as total FROM imoveis WHERE " + whereClause;
  const countRes = await db.getFirstAsync<{ total: number }>(countSql, params);
  const total = countRes ? countRes.total : 0;

  let orderBy = "COALESCE(desconto, 0) DESC, id DESC";
  switch (ordem) {
    case 'desconto_asc': orderBy = "COALESCE(desconto, 0) ASC, id DESC"; break;
    case 'valor_asc': orderBy = "COALESCE(valor_leilao, 999999999) ASC, id DESC"; break;
    case 'valor_desc': orderBy = "COALESCE(valor_leilao, 0) DESC, id DESC"; break;
    case 'avaliacao_desc': orderBy = "COALESCE(valor_avaliacao, 0) DESC, id DESC"; break;
    case 'avaliacao_asc': orderBy = "COALESCE(valor_avaliacao, 999999999) ASC, id DESC"; break;
    case 'encerramento_asc': orderBy = "CASE WHEN data_encerramento IS NULL OR data_encerramento = '' THEN 1 ELSE 0 END, data_encerramento ASC, id DESC"; break;
    case 'recentes': orderBy = "id DESC"; break;
    default: orderBy = "COALESCE(desconto, 0) DESC, id DESC"; break;
  }

  const selectSql = "SELECT * FROM imoveis WHERE " + whereClause + " ORDER BY " + orderBy + " LIMIT ? OFFSET ?";
  const pageParams = [...params, limit, offset];
  const rows = await db.getAllAsync<Imovel>(selectSql, pageParams);

  const totalPages = Math.ceil(total / limit);

  return {
    success: true,
    origem: 'banco_sqlite',
    data: rows.map(r => ({ ...r, link: r.link_original || r.link })),
    total,
    pagina_atual: pagina,
    total_paginas: Math.max(1, totalPages),
    itens_nesta_pagina: rows.length
  };
}

export async function upsertImovel(imovel: Imovel, filtroId?: number | null) {
  const db = await getDatabase();
  const link = imovel.link || imovel.link_original || '';
  if (!link) return { action: 'skip' };

  const hash = imovel.hash_imovel || 'hash_' + Math.abs(Array.from(link).reduce((s, c) => Math.imul(31, s) + c.charCodeAt(0) | 0, 0));

  const existing = await db.getFirstAsync<{ id: number }>('SELECT id FROM imoveis WHERE hash_imovel = ? LIMIT 1', [hash]);

  if (existing) {
    await db.runAsync(
      `UPDATE imoveis SET
        fonte_slug = ?, titulo = ?, tipo = ?, endereco = ?, cidade = ?, uf = ?,
        valor_avaliacao = ?, valor_leilao = ?, desconto = ?, modalidade = ?,
        data_encerramento = ?, data_inclusao = COALESCE(?, data_inclusao),
        edital = COALESCE(?, edital), link_matricula = COALESCE(?, link_matricula),
        numero_matricula = COALESCE(?, numero_matricula), link_leiloeiro = COALESCE(?, link_leiloeiro),
        nome_leiloeiro = COALESCE(?, nome_leiloeiro), imagem = COALESCE(?, imagem),
        status = 'ativo', atualizado_em = CURRENT_TIMESTAMP
      WHERE id = ?`,
      [
        imovel.fonte_slug || 'leilaoimovel',
        imovel.titulo,
        imovel.tipo,
        imovel.endereco,
        imovel.cidade,
        (imovel.uf || 'MA').toUpperCase(),
        imovel.valor_avaliacao,
        imovel.valor_leilao,
        imovel.desconto,
        imovel.modalidade,
        imovel.data_encerramento || '',
        imovel.data_inclusao,
        imovel.edital,
        imovel.link_matricula,
        imovel.numero_matricula,
        imovel.link_leiloeiro,
        imovel.nome_leiloeiro,
        imovel.imagem,
        existing.id
      ]
    );
    return { action: 'updated', id: existing.id };
  } else {
    const res = await db.runAsync(
      `INSERT INTO imoveis (
        hash_imovel, fonte_slug, filtro_id, titulo, tipo, endereco, cidade, uf,
        valor_avaliacao, valor_leilao, desconto, modalidade, data_encerramento,
        data_inclusao, edital, link_matricula, numero_matricula, link_leiloeiro,
        nome_leiloeiro, link_original, imagem, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ativo')`,
      [
        hash,
        imovel.fonte_slug || 'leilaoimovel',
        filtroId || null,
        imovel.titulo,
        imovel.tipo,
        imovel.endereco,
        imovel.cidade,
        (imovel.uf || 'MA').toUpperCase(),
        imovel.valor_avaliacao,
        imovel.valor_leilao,
        imovel.desconto,
        imovel.modalidade,
        imovel.data_encerramento || '',
        imovel.data_inclusao,
        imovel.edital,
        imovel.link_matricula,
        imovel.numero_matricula,
        imovel.link_leiloeiro,
        imovel.nome_leiloeiro,
        link,
        imovel.imagem
      ]
    );
    return { action: 'inserted', id: res.lastInsertRowId };
  }
}
