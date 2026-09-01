import { SourceDriver, ScrapeOptions, ScrapeResult } from './SourceInterface';
import { ScraperService } from './ScraperService';
import { Imovel } from '../types';

export class LeilaoImovelSource implements SourceDriver {
  slug = 'leilaoimovel';
  nome = 'Leilão Imóvel';
  urlBase = 'https://www.leilaoimovel.com.br';

  async scrapeImoveis(options: ScrapeOptions): Promise<ScrapeResult> {
    const uf = options.uf.toLowerCase();
    let path = `/leilao-de-imoveis/${uf}`;
    if (options.municipio) {
      path = `/leilao-de-imoveis/${options.municipio.toLowerCase()}/${uf}`;
    }

    const params: string[] = [];
    if (options.pagina && options.pagina > 1) params.push(`pag=${options.pagina}`);
    if (options.tipo) params.push(`tipo=${options.tipo.toLowerCase()}`);
    if (options.data_final_leilao) params.push(`data_final_leilao=${options.data_final_leilao}`);
    if (options.s) params.push(`s=${encodeURIComponent(options.s)}`);

    const url = `${this.urlBase}${path}${params.length > 0 ? '?' + params.join('&') : ''}`;
    const fetchRes = await ScraperService.getInstance().fetch(url, 'html');

    if (!fetchRes.success) {
      return { success: false, data: [], error: fetchRes.error };
    }

    const html = fetchRes.content;
    const imoveis = this.parseHtml(html, uf.toUpperCase());

    return {
      success: true,
      provider: fetchRes.provider,
      data: imoveis,
      total: imoveis.length,
      pagina_atual: options.pagina || 1,
      total_paginas: imoveis.length >= 20 ? (options.pagina || 1) + 1 : options.pagina || 1
    };
  }

  private parseHtml(html: string, defaultUf: string): Imovel[] {
    const imoveis: Imovel[] = [];
    const boxRegex = /<div[^>]*class=["'][^"']*place-box[^"']*["'][^>]*>([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>/gi;
    let match;

    while ((match = boxRegex.exec(html)) !== null) {
      const boxHtml = match[1];

      const linkMatch = /href=["']([^"']*\/imovel\/[^"']*)["']/i.exec(boxHtml);
      if (!linkMatch) continue;
      let link = linkMatch[1];
      if (link.startsWith('/')) link = this.urlBase + link;

      let imagem = '';
      const imgMatch = /<img[^>]*(?:src|data-src)=["']([^"']+)["']/i.exec(boxHtml);
      if (imgMatch) imagem = imgMatch[1];

      let valorLeilao: number | null = null;
      const leilaoMatch = /discount-price[^>]*>([^<]+)/i.exec(boxHtml);
      if (leilaoMatch) {
        valorLeilao = this.parseMoney(leilaoMatch[1]);
      }

      let valorAvaliacao: number | null = null;
      const avMatch = /last-price[^>]*>([^<]+)/i.exec(boxHtml);
      if (avMatch) {
        valorAvaliacao = this.parseMoney(avMatch[1]);
      }

      let desconto: number | null = null;
      const descMatch = /down[^>]*>[\s\S]*?<b>([^<]+)/i.exec(boxHtml);
      if (descMatch) {
        const num = parseFloat(descMatch[1].replace(',', '.').replace('%', '').trim());
        if (!isNaN(num)) desconto = num;
      } else if (valorAvaliacao && valorLeilao && valorAvaliacao > valorLeilao) {
        desconto = Math.round(((valorAvaliacao - valorLeilao) / valorAvaliacao) * 100);
      }

      let titulo = '';
      let endereco = '';
      const titleMatch = /<div[^>]*class=["'][^"']*address[^"']*["'][^>]*>[\s\S]*?<b>([^<]+)<\/b>[\s\S]*?<span>([^<]+)<\/span>/i.exec(boxHtml);
      if (titleMatch) {
        titulo = titleMatch[1].trim();
        endereco = titleMatch[2].trim();
      } else {
        const parts = link.split('/');
        titulo = (parts[parts.length - 1] || 'Imóvel').replace(/-/g, ' ');
      }

      let modalidade = 'Leilão';
      const modMatch = /categories[^>]*>([\s\S]*?)<\/div>/i.exec(boxHtml);
      if (modMatch) {
        modalidade = modMatch[1].replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
      }

      let dataEncerramento = '';
      const encMatch = /(\d{2}\/\d{2}\/\d{2,4}(?:\s+\d{2}:\d{2})?)/.exec(boxHtml);
      if (encMatch) dataEncerramento = encMatch[1];

      let edital: string | null = null;
      let linkMatricula: string | null = null;
      const caixaMatch = /-(\d{13,14})-/.exec(link);
      if (caixaMatch) {
        const cid = caixaMatch[1];
        linkMatricula = `https://venda-imoveis.caixa.gov.br/editais/matricula/${defaultUf}/${cid}.pdf`;
        edital = `https://venda-imoveis.caixa.gov.br/editais/regras-VOL/comocomprar.pdf?v=01`;
      }

      imoveis.push({
        fonte_slug: 'leilaoimovel',
        titulo,
        tipo: this.detectarTipo(titulo + ' ' + link),
        endereco,
        cidade: this.extrairCidade(link, endereco),
        uf: defaultUf,
        valor_avaliacao: valorAvaliacao,
        valor_leilao: valorLeilao,
        desconto,
        modalidade: modalidade || 'Leilão',
        data_encerramento: dataEncerramento,
        edital,
        link_matricula: linkMatricula,
        link,
        imagem
      });
    }

    return imoveis;
  }

  private parseMoney(str: string): number | null {
    const clean = str.replace(/[^\d,]/g, '').replace(',', '.');
    const num = parseFloat(clean);
    return isNaN(num) ? null : num;
  }

  private detectarTipo(texto: string): string {
    const t = texto.toLowerCase();
    if (t.includes('apartamento') || t.includes('apto')) return 'Apartamento';
    if (t.includes('casa')) return 'Casa';
    if (t.includes('terreno') || t.includes('lote')) return 'Terreno';
    if (t.includes('rural') || t.includes('fazenda') || t.includes('sítio')) return 'Rural';
    if (t.includes('comercial') || t.includes('sala') || t.includes('galpão')) return 'Comercial';
    return 'Imóvel';
  }

  private extrairCidade(link: string, endereco: string): string {
    const linkMatch = /\/imovel\/[a-z]{2}\/([^/]+)\//i.exec(link);
    if (linkMatch) {
      return linkMatch[1].replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    }
    const endMatch = /,\s*([^,-]+)\s*-\s*[A-Z]{2}/.exec(endereco);
    if (endMatch) return endMatch[1].trim();
    return '';
  }
}
