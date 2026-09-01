import { Imovel } from '../types';

export interface ScrapeOptions {
  uf: string;
  municipio?: string | null;
  tipo?: string | null;
  pagina?: number;
  data_final_leilao?: string | null;
  s?: string | null;
}

export interface ScrapeResult {
  success: boolean;
  provider?: string;
  data: Imovel[];
  total?: number;
  pagina_atual?: number;
  total_paginas?: number;
  error?: string;
}

export interface SourceDriver {
  slug: string;
  nome: string;
  urlBase: string;
  scrapeImoveis(options: ScrapeOptions): Promise<ScrapeResult>;
}
