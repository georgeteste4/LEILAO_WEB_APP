import { getTokens } from '../database/tokensRepository';

export interface FetchResult {
  success: boolean;
  content: string;
  provider: string;
  error?: string;
}

export class ScraperService {
  private static instance: ScraperService;

  static getInstance(): ScraperService {
    if (!this.instance) {
      this.instance = new ScraperService();
    }
    return this.instance;
  }

  async fetch(url: string, format: 'html' | 'json' = 'html'): Promise<FetchResult> {
    const tokens = await getTokens();
    const activeTokens = tokens.filter(t => t.status === 'ativo');

    // 1. Tentar requisição direta
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000);

      const resp = await fetch(url, {
        signal: controller.signal,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': format === 'json' ? 'application/json' : 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        }
      });
      clearTimeout(timeoutId);

      if (resp.ok) {
        const text = await resp.text();
        if (text && text.length > 200) {
          return { success: true, content: text, provider: 'direct' };
        }
      }
    } catch (e) {}

    // 2. Scrape.do tokens
    const scrapeDoTokens = activeTokens.filter(t => t.provider === 'scrape_do');
    for (const st of scrapeDoTokens) {
      try {
        const scrapeUrl = `https://api.scrape.do?token=${st.token}&url=${encodeURIComponent(url)}`;
        const resp = await fetch(scrapeUrl);
        if (resp.ok) {
          const text = await resp.text();
          return { success: true, content: text, provider: 'scrape_do' };
        }
      } catch (e) {}
    }

    // 3. Firecrawl tokens
    const firecrawlTokens = activeTokens.filter(t => t.provider === 'firecrawl');
    for (const fc of firecrawlTokens) {
      try {
        const resp = await fetch('https://api.firecrawl.dev/v0/scrape', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${fc.token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ url, pageOptions: { onlyMainContent: false } })
        });
        if (resp.ok) {
          const data = await resp.json();
          const content = data.data?.html || data.data?.content || JSON.stringify(data);
          return { success: true, content, provider: 'firecrawl' };
        }
      } catch (e) {}
    }

    return {
      success: false,
      content: '',
      provider: 'none',
      error: 'Não foi possível obter dados da URL. Verifique a conexão ou adicione tokens em Configurações.'
    };
  }
}
