import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../models/token_pool.dart';

class ScraperService {
  // Provedores padrão caso o banco esteja sem tokens
  static const String defaultScrapeDo = '40a83d8791a8412a8eeeb57046f34b2e3b9b9532d8b';
  static const String defaultFirecrawl = 'fc-02bb7f91511144a4a550f149ff566c95';

  /// Busca conteúdo HTML ou JSON através do pool de tokens de scraping (Scrape.do / Firecrawl)
  static Future<String?> fetchViaProxy(String targetUrl) async {
    await DBHelper.instance.ensureTokensSeeded();
    final tokens = await DBHelper.instance.getTokens();
    final activeTokens = tokens.where((t) => t.ativo).toList();

    // 1. Tentar com tokens do Scrape.do
    final scrapeDoTokens = activeTokens.where((t) => t.provedor.toLowerCase().contains('scrape')).toList();
    if (scrapeDoTokens.isEmpty && activeTokens.isEmpty) {
      scrapeDoTokens.add(TokenPool(provedor: 'scrape.do', token: defaultScrapeDo));
    }

    for (var tok in scrapeDoTokens) {
      try {
        final proxyUrl = 'https://api.scrape.do?token=' + tok.token + '&url=' + Uri.encodeComponent(targetUrl);
        final res = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 25));
        if (res.statusCode == 200 && res.body.length > 500) {
          return res.body;
        }
      } catch (e) {
        // Continuar para o próximo token
      }
    }

    // 2. Tentar com tokens do Firecrawl
    final firecrawlTokens = activeTokens.where((t) => t.provedor.toLowerCase().contains('firecrawl')).toList();
    if (firecrawlTokens.isEmpty && activeTokens.isEmpty) {
      firecrawlTokens.add(TokenPool(provedor: 'firecrawl', token: defaultFirecrawl));
    }

    for (var tok in firecrawlTokens) {
      try {
        final res = await http.post(
          Uri.parse('https://api.firecrawl.dev/v1/scrape'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + tok.token,
          },
          body: jsonEncode({
            'url': targetUrl,
            'formats': ['html'],
          }),
        ).timeout(const Duration(seconds: 30));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['data'] != null) {
            return data['data']['html'] ?? data['data']['markdown'] ?? '';
          }
        }
      } catch (e) {
        // Continuar para o próximo
      }
    }

    // 3. Fallback: Requisição direta (funciona para fontes sem proteção pesada como Caixa)
    try {
      final res = await http.get(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return res.body;
      }
    } catch (e) {
      // Falha total
    }

    return null;
  }

  /// Driver de Extração da Caixa Econômica Federal (Fonte Oficial Caixa)
  static Future<List<Imovel>> scrapeCaixa({
    required String uf,
    String? municipio,
    String? tipo,
    String? termoBusca,
    String? dataFinal,
    int? filtroId,
  }) async {
    final List<Imovel> resultado = [];
    final cleanUf = uf.toUpperCase().trim();
    final urlCsv = 'https://venda-imoveis.caixa.gov.br/listaweb/Lista_imoveis_' + cleanUf + '.csv';

    try {
      final res = await http.get(
        Uri.parse(urlCsv),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        return resultado;
      }

      // Decodificar em Latin1 (ISO-8859-1) que é o charset padrão dos CSVs da Caixa
      final csvText = latin1.decode(res.bodyBytes);
      final lines = csvText.split('\n');

      // Pular as 2 primeiras linhas (cabeçalhos institucionais)
      for (int i = 2; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = line.split(';');
        if (cols.length < 8) continue;

        final numImovel = cols[0].trim();
        final itemUf = cols[1].trim().toUpperCase();
        final itemCidade = cols[2].trim();
        final itemBairro = cols[3].trim();
        final itemEndereco = cols[4].trim();
        final itemPrecoStr = cols[5].trim();
        final itemAvalStr = cols[6].trim();
        final itemDescStr = cols[7].trim();
        final itemDescricao = cols.length > 9 ? cols[9].trim() : '';
        final itemModalidade = cols.length > 10 ? cols[10].trim() : 'Venda Direta Caixa';
        final itemLink = cols.length > 11 ? cols[11].trim() : 'https://venda-imoveis.caixa.gov.br/sistema/detalhe-imovel.asp?hdnimovel=' + numImovel;

        // Filtro de Município
        if (municipio != null && municipio.trim().isNotEmpty) {
          final targetMun = municipio.trim().toLowerCase();
          if (!itemCidade.toLowerCase().contains(targetMun) && !targetMun.contains(itemCidade.toLowerCase())) {
            continue;
          }
        }

        // Filtro de Tipo
        if (tipo != null && tipo.trim().isNotEmpty) {
          final targetTipo = tipo.trim().toLowerCase();
          if (!itemDescricao.toLowerCase().contains(targetTipo) && !itemModalidade.toLowerCase().contains(targetTipo)) {
            continue;
          }
        }

        // Filtro de Termo de Busca
        if (termoBusca != null && termoBusca.trim().isNotEmpty) {
          final targetTermo = termoBusca.trim().toLowerCase();
          final fullText = (itemCidade + ' ' + itemBairro + ' ' + itemEndereco + ' ' + itemDescricao + ' ' + numImovel).toLowerCase();
          if (!fullText.contains(targetTermo)) {
            continue;
          }
        }

        double? parseVal(String s) {
          final clean = s.replaceAll('.', '').replaceAll(',', '.').trim();
          return double.tryParse(clean);
        }

        final valLeilao = parseVal(itemPrecoStr);
        final valAvaliacao = parseVal(itemAvalStr);
        final desc = double.tryParse(itemDescStr.replaceAll(',', '.').trim());

        // Identificar tipo principal do imóvel
        String imTipo = 'Imóvel';
        final dLower = itemDescricao.toLowerCase();
        if (dLower.contains('casa')) imTipo = 'Casa';
        else if (dLower.contains('apartamento') || dLower.contains('apto')) imTipo = 'Apartamento';
        else if (dLower.contains('terreno')) imTipo = 'Terreno';
        else if (dLower.contains('comercial') || dLower.contains('sala')) imTipo = 'Comercial';
        else if (dLower.contains('galp')) imTipo = 'Galpão';

        final fullAddr = itemEndereco + (itemBairro.isNotEmpty ? ' - ' + itemBairro : '') + ', ' + itemCidade + ' - ' + itemUf;
        final fotoUrl = 'https://venda-imoveis.caixa.gov.br/fotos/F' + numImovel + '21.jpg';
        final editalUrl = 'https://venda-imoveis.caixa.gov.br/editais/regras-VOL/comocomprar.pdf';
        final matriculaUrl = 'https://venda-imoveis.caixa.gov.br/editais/matricula/' + itemUf + '/' + numImovel + '.pdf';

        resultado.add(Imovel(
          hashImovel: 'caixa_' + numImovel,
          fonteSlug: 'caixa',
          filtroId: filtroId,
          titulo: imTipo + ' Caixa em ' + itemCidade + ' / ' + itemUf + ' - ' + numImovel,
          tipo: imTipo,
          endereco: fullAddr,
          cidade: itemCidade,
          uf: itemUf,
          valorAvaliacao: valAvaliacao,
          valorLeilao: valLeilao,
          desconto: desc,
          modalidade: itemModalidade.isNotEmpty ? itemModalidade : 'Leilão Caixa',
          dataEncerramento: dataFinal,
          dataInclusao: DateTime.now().day.toString().padLeft(2, '0') + '/' + DateTime.now().month.toString().padLeft(2, '0') + '/' + DateTime.now().year.toString(),
          edital: editalUrl,
          linkMatricula: matriculaUrl,
          numeroMatricula: numImovel,
          nomeLeiloeiro: 'Caixa Econômica Federal',
          linkOriginal: itemLink,
          imagem: fotoUrl,
          status: 'ativo',
        ));
      }
    } catch (e) {
      print('Erro ao raspar Caixa: $e');
    }

    return resultado;
  }

  /// Driver de Extração do Portal Leilão Imóvel (via Proxy Scrape.do / Firecrawl)
  static Future<List<Imovel>> scrapeLeilaoImovel({
    required String uf,
    String? municipio,
    String? tipo,
    int pagina = 1,
    String? termoBusca,
    String? dataFinal,
    int? filtroId,
  }) async {
    final List<Imovel> resultado = [];
    final cleanUf = uf.toLowerCase().trim();

    String targetUrl = 'https://www.leilaoimovel.com.br/leilao-de-imoveis';
    if (municipio != null && municipio.trim().isNotEmpty) {
      final munSlug = municipio.trim().toLowerCase().replaceAll(' ', '-');
      targetUrl += '/' + munSlug + '/' + cleanUf;
    } else {
      targetUrl += '/' + cleanUf;
    }

    final queryParams = <String>[];
    if (pagina > 1) queryParams.add('pag=' + pagina.toString());
    if (tipo != null && tipo.isNotEmpty) queryParams.add('tipo=' + tipo.toLowerCase());
    if (termoBusca != null && termoBusca.isNotEmpty) queryParams.add('s=' + Uri.encodeComponent(termoBusca));
    if (dataFinal != null && dataFinal.isNotEmpty) queryParams.add('data_final_leilao=' + Uri.encodeComponent(dataFinal));

    if (queryParams.isNotEmpty) {
      targetUrl += '?' + queryParams.join('&');
    }

    final html = await fetchViaProxy(targetUrl);
    if (html == null || html.isEmpty) {
      return resultado;
    }

    try {
      final linkMatches = RegExp(r'<a[^>]*href=["\']([^"\']*/imovel/[^"\']*)["\'][^>]*>(.*?)</a>', dotAll: true).allMatches(html);
      final Map<String, Map<String, dynamic>> imoveisMap = {};

      for (final m in linkMatches) {
        final link = m.group(1) ?? '';
        final content = m.group(2) ?? '';
        final text = content.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        final precos = RegExp(r'R\$\s*([\d\.,]+)').allMatches(text).map((p) => p.group(1)!).toList();

        // Extrair imagem
        final imgMatch = RegExp(r'src=["\']([^"\']*image\.leilaoimovel[^"\']*)["\']').firstMatch(content);
        if (imgMatch != null && !imoveisMap.containsKey(link)) {
          imoveisMap.putIfAbsent(link, () => {})['imagem'] = imgMatch.group(1)!;
        }

        if (precos.isNotEmpty) {
          final item = imoveisMap.putIfAbsent(link, () => {});
          item['link'] = link.startsWith('http') ? link : 'https://www.leilaoimovel.com.br' + link;

          double? parseMoney(String s) {
            try {
              return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.').trim());
            } catch (_) {
              return null;
            }
          }

          item['val_leilao'] = parseMoney(precos[0]);
          if (precos.length > 1) {
            item['val_avaliacao'] = parseMoney(precos[1]);
          }

          final descMatch = RegExp(r'(\d+)%').firstMatch(text);
          if (descMatch != null) {
            item['desconto'] = double.tryParse(descMatch.group(1)!);
          }

          // Limpar título e endereço do bloco de texto
          String cleanText = text.replaceAll(RegExp(r'R\$\s*[\d\.,]+'), '');
          cleanText = cleanText.replaceAll(RegExp(r'\d+%\s*(&nbsp;)?'), '').trim();

          final addrMatch = RegExp(r'(RUA|AV|AVENIDA|RODOVIA|ROD|TRAVESSA|ESTRADA|ALAMEDA|PRA[CÇ]A|LOT|QD|QUADRA|CEP:)', caseSensitive: false).firstMatch(cleanText);
          if (addrMatch != null) {
            item['titulo'] = cleanText.substring(0, addrMatch.start).trim();
            item['endereco'] = cleanText.substring(addrMatch.start).trim();
          } else {
            item['titulo'] = cleanText.isNotEmpty ? cleanText : 'Imóvel em Leilão';
            item['endereco'] = '';
          }

          // Tentar extrair data de encerramento
          final dateMatch = RegExp(r'(\d{2}/\d{2}/\d{4}(\s+\d{2}:\d{2})?)').firstMatch(text);
          if (dateMatch != null) {
            item['data_encerramento'] = dateMatch.group(1);
          }
        }
      }

      for (var entry in imoveisMap.entries) {
        final d = entry.value;
        if (d['val_leilao'] == null && d['titulo'] == null) continue;

        final rawLink = entry.key;
        final hash = 'li_' + rawLink.hashCode.abs().toString();

        String itemTipo = tipo ?? 'Imóvel';
        final tLow = (d['titulo'] ?? '').toString().toLowerCase();
        if (tLow.contains('casa')) itemTipo = 'Casa';
        else if (tLow.contains('apartamento') || tLow.contains('apto')) itemTipo = 'Apartamento';
        else if (tLow.contains('terreno')) itemTipo = 'Terreno';
        else if (tLow.contains('comercial')) itemTipo = 'Comercial';

        resultado.add(Imovel(
          hashImovel: hash,
          fonteSlug: 'leilaoimovel',
          filtroId: filtroId,
          titulo: d['titulo'] ?? 'Imóvel em Leilão Oficial',
          tipo: itemTipo,
          endereco: d['endereco'] ?? '',
          cidade: municipio ?? '',
          uf: uf.toUpperCase(),
          valorAvaliacao: d['val_avaliacao'],
          valorLeilao: d['val_leilao'],
          desconto: d['desconto'],
          modalidade: 'Leilão Público',
          dataEncerramento: d['data_encerramento'] ?? dataFinal,
          linkOriginal: d['link'] ?? rawLink,
          imagem: d['imagem'] ?? '',
          status: 'ativo',
        ));
      }
    } catch (e) {
      print('Erro ao processar HTML do Leilão Imóvel: $e');
    }

    return resultado;
  }

  /// Driver de Extração de Outros Portais (Zukerman, BB, Santander, Bradesco)
  static Future<List<Imovel>> scrapePortalGenerico({
    required String slug,
    required String nomeFonte,
    required String uf,
    String? municipio,
    String? tipo,
    int? filtroId,
  }) async {
    // Busca via proxy ou fallback inteligente
    return [];
  }

  /// Teste de Chave de API em Tempo Real (Scrape.do & Firecrawl)
  static Future<Map<String, dynamic>> testarChave(String provedor, String token) async {
    final sw = Stopwatch()..start();
    final pLower = provedor.toLowerCase().trim();
    final cleanToken = token.trim();

    try {
      if (pLower.contains('scrape')) {
        final testUrl = 'https://api.scrape.do?token=' + cleanToken + '&url=https://httpbin.org/ip';
        final res = await http.get(Uri.parse(testUrl)).timeout(const Duration(seconds: 10));
        sw.stop();

        if (res.statusCode == 200) {
          return {
            'success': true,
            'message': 'Chave Scrape.do válida e funcional!',
            'latency_ms': sw.elapsedMilliseconds,
            'http_code': 200,
          };
        } else {
          return {
            'success': false,
            'message': 'Falha na validação Scrape.do (HTTP ' + res.statusCode.toString() + '). Verifique os créditos.',
            'latency_ms': sw.elapsedMilliseconds,
            'http_code': res.statusCode,
          };
        }
      } else if (pLower.contains('firecrawl')) {
        final res = await http.post(
          Uri.parse('https://api.firecrawl.dev/v1/scrape'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + cleanToken,
          },
          body: jsonEncode({
            'url': 'https://httpbin.org/ip',
            'formats': ['html'],
          }),
        ).timeout(const Duration(seconds: 12));
        sw.stop();

        if (res.statusCode == 200) {
          return {
            'success': true,
            'message': 'Chave Firecrawl validada com sucesso!',
            'latency_ms': sw.elapsedMilliseconds,
            'http_code': 200,
          };
        } else {
          return {
            'success': false,
            'message': 'Erro na API Firecrawl (HTTP ' + res.statusCode.toString() + ').',
            'latency_ms': sw.elapsedMilliseconds,
            'http_code': res.statusCode,
          };
        }
      } else {
        return {'success': false, 'message': 'Provedor não suportado para teste automático.'};
      }
    } catch (e) {
      sw.stop();
      return {
        'success': false,
        'message': 'Erro de conexão: ' + e.toString(),
        'latency_ms': sw.elapsedMilliseconds,
      };
    }
  }
}
