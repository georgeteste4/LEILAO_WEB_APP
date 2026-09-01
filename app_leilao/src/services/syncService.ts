import { FiltroSalvo } from '../types';
import { SourceManager } from '../scrapers/SourceManager';
import { upsertImovel } from '../database/imoveisRepository';
import { salvarLog } from '../database/logsRepository';

export async function executeFiltroCapture(
  filtro: FiltroSalvo,
  onProgress?: (pagina: number, totalNovos: number) => void
) {
  const startTime = Date.now();
  const fontes: string[] = Array.isArray(filtro.fontes)
    ? filtro.fontes
    : typeof filtro.fontes === 'string'
      ? JSON.parse(filtro.fontes || '["leilaoimovel"]')
      : ['leilaoimovel'];

  let totalNovos = 0;
  let totalAtualizados = 0;
  let totalProcessados = 0;
  let paginas = 0;

  for (const fonteSlug of fontes) {
    const driver = SourceManager.getDriver(fonteSlug);
    let pagina = 1;
    let maxPaginas = 3;

    do {
      paginas++;
      if (onProgress) onProgress(pagina, totalNovos);

      const res = await driver.scrapeImoveis({
        uf: filtro.uf,
        municipio: filtro.municipio,
        tipo: filtro.tipo,
        pagina,
        data_final_leilao: filtro.data_final_leilao,
        s: filtro.termo_busca
      });

      if (!res.success || !res.data || res.data.length === 0) break;

      for (const im of res.data) {
        im.fonte_slug = fonteSlug;
        const up = await upsertImovel(im, filtro.id);
        if (up.action === 'inserted') totalNovos++;
        if (up.action === 'updated') totalAtualizados++;
        totalProcessados++;
      }

      maxPaginas = res.total_paginas || 1;
      pagina++;
    } while (pagina <= maxPaginas && pagina <= 5);
  }

  const durationSec = Math.round((Date.now() - startTime) / 1000);

  await salvarLog({
    filtro_id: filtro.id,
    status: 'sucesso',
    total_paginas: paginas,
    total_imoveis: totalProcessados,
    novos: totalNovos,
    atualizados: totalAtualizados,
    tempo_segundos: durationSec,
    detalhes: `Rotina executada diretamente no app com sucesso.`
  });

  return {
    novos: totalNovos,
    atualizados: totalAtualizados,
    tempo_segundos: durationSec
  };
}
