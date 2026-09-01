export interface Imovel {
  id?: number;
  hash_imovel?: string;
  fonte_slug: string;
  filtro_id?: number | null;
  titulo: string;
  tipo: string;
  endereco: string;
  cidade: string;
  uf: string;
  valor_avaliacao: number | null;
  valor_leilao: number | null;
  desconto: number | null;
  modalidade: string;
  data_encerramento?: string;
  data_inclusao?: string | null;
  edital?: string | null;
  link_matricula?: string | null;
  numero_matricula?: string | null;
  link_leiloeiro?: string | null;
  nome_leiloeiro?: string | null;
  link: string;
  link_original?: string;
  imagem: string;
  dados_json?: string | null;
  status?: string;
  criado_em?: string;
  atualizado_em?: string;
  origem?: string;
}

export interface FiltroSalvo {
  id: number;
  nome: string;
  uf: string;
  municipio?: string | null;
  tipo?: string | null;
  data_final_leilao?: string | null;
  termo_busca?: string | null;
  fontes?: string[] | string;
  cron_token?: string;
  ativo: boolean | number;
  total_execucoes?: number;
  total_imoveis_salvos?: number;
  ultima_execucao_em?: string | null;
  criado_em?: string;
}

export interface LogCron {
  id: number;
  filtro_id?: number | null;
  filtro_nome?: string;
  status: string;
  total_paginas: number;
  total_imoveis: number;
  novos: number;
  atualizados: number;
  tempo_segundos: number;
  detalhes?: string | null;
  executado_em: string;
}

export interface FonteDados {
  id?: number;
  slug: string;
  nome: string;
  url_base: string;
  descricao?: string;
  ativo: boolean | number;
  driver_class: string;
  config?: Record<string, any>;
  total_imoveis?: number;
  ultima_coleta_em?: string | null;
}

export interface ScraperToken {
  id?: number;
  provider: 'scrape_do' | 'firecrawl';
  token: string;
  status: 'ativo' | 'pausado' | 'invalido' | 'esgotado';
  total_reqs?: number;
  total_erros?: number;
  criado_em?: string;
}

export interface AppReleaseInfo {
  version: string;
  name: string;
  published_at: string;
  body: string;
  html_url: string;
  apk_url?: string;
  apk_size?: number;
  has_update: boolean;
}

export interface FilterState {
  uf: string;
  municipios: string[];
  tipo: string;
  fonte: string;
  dataFinal: string;
  termoBusca: string;
  ordem: string;
  pagina: number;
  modoOnline: boolean;
}
