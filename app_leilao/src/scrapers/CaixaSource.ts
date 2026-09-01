import { SourceDriver, ScrapeOptions, ScrapeResult } from './SourceInterface';
import { ScraperService } from './ScraperService';
import { Imovel } from '../types';

export class CaixaSource implements SourceDriver {
  slug = 'caixa';
  nome = 'Caixa Econômica Federal';
  urlBase = 'https://venda-imoveis.caixa.gov.br';

  async scrapeImoveis(options: ScrapeOptions): Promise<ScrapeResult> {
    const uf = options.uf.toUpperCase();
    const csvUrl = `${this.urlBase}/listaweb/Lista_imoveis_${uf}.csv`;

    const fetchRes = await ScraperService.getInstance().fetch(csvUrl, 'html');
    if (!fetchRes.success) {
      return { success: false, data: [], error: fetchRes.error };
    }

    const lines = fetchRes.content.split('\n');
    const imoveis: Imovel[] = [];

    for (let i = 3; i < lines.length && imoveis.length < 50; i++) {
      const line = lines[i].trim();
      if (!line) continue;
      const cols = line.split(';');
      if (cols.length < 7) continue;

      const numImovel = cols[0].replace(/"/g, '').trim();
      const ufItem = (cols[1] || uf).replace(/"/g, '').trim();
      const cidade = cols[2]?.replace(/"/g, '').trim() || '';
      const bairro = cols[3]?.replace(/"/g, '').trim() || '';
      const endereco = cols[4]?.replace(/"/g, '').trim() || '';
      const precoStr = cols[5]?.replace(/"/g, '').trim() || '';
      const valAvStr = cols[6]?.replace(/"/g, '').trim() || '';
      const descr = cols[7]?.replace(/"/g, '').trim() || '';
      const modalidade = cols[8]?.replace(/"/g, '').trim() || 'Venda Online Caixa';

      const valorLeilao = parseFloat(precoStr.replace('.', '').replace(',', '.')) || null;
      const valorAvaliacao = parseFloat(valAvStr.replace('.', '').replace(',', '.')) || null;

      let desconto: number | null = null;
      if (valorAvaliacao && valorLeilao && valorAvaliacao > valorLeilao) {
        desconto = Math.round(((valorAvaliacao - valorLeilao) / valorAvaliacao) * 100);
      }

      const link = `${this.urlBase}/sistema/detalhe-imovel.asp?hdnOrigem=index&hdnimovel=${numImovel}`;
      const linkMatricula = `https://venda-imoveis.caixa.gov.br/editais/matricula/${ufItem}/${numImovel}.pdf`;
      const edital = `https://venda-imoveis.caixa.gov.br/editais/regras-VOL/comocomprar.pdf?v=01`;

      imoveis.push({
        fonte_slug: 'caixa',
        titulo: `${descr || 'Imóvel Caixa'} - ${cidade}/${ufItem}`,
        tipo: 'Imóvel Caixa',
        endereco: `${endereco}, ${bairro} - ${cidade}/${ufItem}`,
        cidade,
        uf: ufItem,
        valor_avaliacao: valorAvaliacao,
        valor_leilao: valorLeilao,
        desconto,
        modalidade,
        edital,
        link_matricula: linkMatricula,
        numero_matricula: numImovel,
        link,
        imagem: `https://venda-imoveis.caixa.gov.br/fotos/F${numImovel}01.jpg`
      });
    }

    return {
      success: true,
      data: imoveis,
      total: imoveis.length,
      pagina_atual: 1,
      total_paginas: 1
    };
  }
}
