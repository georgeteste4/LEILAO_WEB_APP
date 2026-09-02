const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');
const DATA_DIR = path.join(__dirname, 'data');

let imoveis = [];
let filtros = [];
let fontes = [];

try {
  imoveis = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'seed_imoveis.json'), 'utf-8'));
  filtros = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'seed_filtros.json'), 'utf-8'));
  fontes = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'seed_fontes.json'), 'utf-8'));
} catch (e) {
  console.error('Erro ao ler seeds:', e.message);
}

const ESTADOS = [
  { sigla: "AC", nome: "Acre" }, { sigla: "AL", nome: "Alagoas" }, { sigla: "AP", nome: "Amapá" },
  { sigla: "AM", nome: "Amazonas" }, { sigla: "BA", nome: "Bahia" }, { sigla: "CE", nome: "Ceará" },
  { sigla: "DF", nome: "Distrito Federal" }, { sigla: "ES", nome: "Espírito Santo" }, { sigla: "GO", nome: "Goiás" },
  { sigla: "MA", nome: "Maranhão" }, { sigla: "MT", nome: "Mato Grosso" }, { sigla: "MS", nome: "Mato Grosso do Sul" },
  { sigla: "MG", nome: "Minas Gerais" }, { sigla: "PA", nome: "Pará" }, { sigla: "PB", nome: "Paraíba" },
  { sigla: "PR", nome: "Paraná" }, { sigla: "PE", nome: "Pernambuco" }, { sigla: "PI", nome: "Piauí" },
  { sigla: "RJ", nome: "Rio de Janeiro" }, { sigla: "RN", nome: "Rio Grande do Norte" }, { sigla: "RS", nome: "Rio Grande do Sul" },
  { sigla: "RO", nome: "Rondônia" }, { sigla: "RR", nome: "Roraima" }, { sigla: "SC", nome: "Santa Catarina" },
  { sigla: "SP", nome: "São Paulo" }, { sigla: "SE", nome: "Sergipe" }, { sigla: "TO", nome: "Tocantins" }
];

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  let pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Normalizar /api/index.php ou ../api/index.php
  if (pathname.includes('/api/index.php') || pathname === '/api/buscar.php' || pathname === '/api/imoveis') {
    const action = query.action;

    if (action === 'estados') {
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, data: ESTADOS }));
      return;
    }

    if (action === 'municipios') {
      const targetUf = (query.uf || 'MA').toUpperCase();
      const cities = Array.from(new Set(
        imoveis.filter(i => (i.uf || '').toUpperCase() === targetUf && i.cidade).map(i => i.cidade)
      )).sort();
      const data = cities.map(c => ({ nome: c, slug: c.toLowerCase().replace(/\s+/g, '-') }));
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, data }));
      return;
    }

    if (action === 'fontes_listar') {
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, data: fontes }));
      return;
    }

    if (action === 'tokens_status') {
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ success: true, data: [] }));
      return;
    }

    // Busca padrão de imóveis
    const uf = (query.uf || 'MA').toUpperCase();
    const tipo = query.tipo ? query.tipo.toLowerCase() : '';
    const fonte = query.fonte ? query.fonte.toLowerCase() : 'todas';
    const termo = query.q || query.termo || query.termo_busca || '';
    const ordem = query.ordem || 'desconto_desc';
    const pagina = parseInt(query.pagina || query.page || '1', 10);
    const limit = parseInt(query.limit || '24', 10);
    const municipiosParam = query.municipios || query.municipio || '';

    let filtrados = imoveis.filter(im => {
      if (im.uf && im.uf.toUpperCase() !== uf) return false;
      if (tipo && !((im.tipo || '').toLowerCase().includes(tipo))) return false;
      if (fonte && fonte !== 'todas' && (im.fonte_slug || '').toLowerCase() !== fonte) return false;
      if (municipiosParam) {
        const mList = municipiosParam.toLowerCase().split(',');
        const c = (im.cidade || '').toLowerCase();
        if (!mList.some(m => c.includes(m.trim()))) return false;
      }
      if (termo) {
        const t = termo.toLowerCase();
        const matchTitle = (im.titulo || '').toLowerCase().includes(t);
        const matchCity = (im.cidade || '').toLowerCase().includes(t);
        const matchAddress = (im.endereco || '').toLowerCase().includes(t);
        const matchLeiloeiro = (im.nome_leiloeiro || '').toLowerCase().includes(t);
        if (!matchTitle && !matchCity && !matchAddress && !matchLeiloeiro) return false;
      }
      return true;
    });

    filtrados.sort((a, b) => {
      if (ordem === 'desconto_desc') return (b.desconto || 0) - (a.desconto || 0);
      if (ordem === 'desconto_asc') return (a.desconto || 0) - (b.desconto || 0);
      if (ordem === 'valor_asc') return (a.valor_leilao || 999999999) - (b.valor_leilao || 999999999);
      if (ordem === 'valor_desc') return (b.valor_leilao || 0) - (a.valor_leilao || 0);
      if (ordem === 'avaliacao_desc') return (b.valor_avaliacao || 0) - (a.valor_avaliacao || 0);
      return 0;
    });

    const total = filtrados.length;
    const totalPaginas = Math.ceil(total / limit) || 1;
    const startIndex = (pagina - 1) * limit;
    const itens = filtrados.slice(startIndex, startIndex + limit);

    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      success: true,
      origem: 'servidor_local',
      data: itens,
      total,
      pagina_atual: pagina,
      total_paginas: totalPaginas,
      itens_nesta_pagina: itens.length
    }));
    return;
  }

  // Servir estáticos
  let filePath = path.join(PUBLIC_DIR, pathname === '/' ? 'index.html' : pathname);
  if (pathname === '/admin') filePath = path.join(PUBLIC_DIR, 'admin.html');

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Pagina nao encontrada');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, () => {
  console.log(`🌐 Servidor rodando: http://localhost:${PORT}`);
});
