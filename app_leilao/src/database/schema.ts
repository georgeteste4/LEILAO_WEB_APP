export const CREATE_TABLES_SQL = `
CREATE TABLE IF NOT EXISTS fontes_dados (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slug TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    url_base TEXT NOT NULL,
    descricao TEXT,
    ativo INTEGER DEFAULT 1,
    driver_class TEXT NOT NULL DEFAULT 'LeilaoImovelSource',
    config_json TEXT,
    total_imoveis_coletados INTEGER DEFAULT 0,
    ultima_coleta_em TEXT,
    criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS filtros_salvos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    uf TEXT NOT NULL,
    municipio TEXT,
    tipo TEXT,
    data_final_leilao TEXT,
    termo_busca TEXT,
    fontes TEXT,
    cron_token TEXT NOT NULL,
    ativo INTEGER DEFAULT 1,
    total_execucoes INTEGER DEFAULT 0,
    total_imoveis_salvos INTEGER DEFAULT 0,
    ultima_execucao_em TEXT,
    criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS imoveis (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hash_imovel TEXT NOT NULL UNIQUE,
    fonte_slug TEXT NOT NULL DEFAULT 'leilaoimovel',
    filtro_id INTEGER,
    titulo TEXT NOT NULL,
    tipo TEXT NOT NULL,
    endereco TEXT,
    cidade TEXT,
    uf TEXT NOT NULL,
    valor_avaliacao REAL,
    valor_leilao REAL,
    desconto REAL,
    modalidade TEXT,
    data_encerramento TEXT,
    data_inclusao TEXT,
    edital TEXT,
    link_matricula TEXT,
    numero_matricula TEXT,
    link_leiloeiro TEXT,
    nome_leiloeiro TEXT,
    link_original TEXT NOT NULL,
    imagem TEXT,
    dados_json TEXT,
    status TEXT DEFAULT 'ativo',
    criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS logs_cron (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filtro_id INTEGER,
    status TEXT NOT NULL,
    total_paginas INTEGER DEFAULT 0,
    total_imoveis INTEGER DEFAULT 0,
    novos INTEGER DEFAULT 0,
    atualizados INTEGER DEFAULT 0,
    tempo_segundos REAL DEFAULT 0,
    detalhes TEXT,
    executado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS config_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL,
    token TEXT NOT NULL,
    status TEXT DEFAULT 'ativo',
    total_reqs INTEGER DEFAULT 0,
    total_erros INTEGER DEFAULT 0,
    criado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
`;
