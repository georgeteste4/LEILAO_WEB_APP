import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../models/token_pool.dart';

class ScraperService {
  static const String defaultScrapeDo = '40a83d8791a8412a8eeeb57046f34b2e3b9b9532d8b';
  static const String defaultFirecrawl = 'fc-02bb7f91511144a4a550f149ff566c95';

  /// Requisição GET através do pool de chaves (Scrape.do / Firecrawl)
  static Future<String?> fetchViaProxy(String targetUrl) async {
    await DBHelper.instance.ensureTokensSeeded();
    final tokens = await DBHelper.instance.getTokens();
    final activeTokens = tokens.where((t) => t.ativo).toList();

    // 1. Scrape.do
    final scrapeDoTokens = activeTokens.where((t) => t.provedor.toLowerCase().contains('scrape')).toList();
    if (scrapeDoTokens.isEmpty && activeTokens.isEmpty) {
      scrapeDoTokens.add(TokenPool(provedor: 'scrape.do', token: defaultScrapeDo));
    }

    for (var tok in scrapeDoTokens) {
      try {
        final proxyUrl = 'https://api.scrape.do?token=' + tok.token + '&url=' + Uri.encodeComponent(targetUrl);
        final res = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 25));
        if (res.statusCode == 200 && res.body.length > 300) {
          return res.body;
        }
      } catch (_) {}
    }

    // 2. Firecrawl
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
      } catch (_) {}
    }

    // 3. Fallback Direto
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
    } catch (_) {}

    return null;
  }

  /// Requisição POST através do Scrape.do
  static Future<String?> postViaProxy(String targetUrl, Map<String, String> bodyFields, {Map<String, String>? headers}) async {
    await DBHelper.instance.ensureTokensSeeded();
    final tokens = await DBHelper.instance.getTokens();
    final activeTokens = tokens.where((t) => t.ativo).toList();

    final scrapeDoTokens = activeTokens.where((t) => t.provedor.toLowerCase().contains('scrape')).toList();
    final token = scrapeDoTokens.isNotEmpty ? scrapeDoTokens.first.token : defaultScrapeDo;

    final proxyUrl = 'https://api.scrape.do?token=' + token + '&url=' + Uri.encodeComponent(targetUrl);
    final reqHeaders = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    };
    if (headers != null) reqHeaders.addAll(headers);

    try {
      final res = await http.post(Uri.parse(proxyUrl), headers: reqHeaders, body: bodyFields).timeout(const Duration(seconds: 25));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return res.body;
      }
    } catch (_) {}

    // Fallback direto
    try {
      final res = await http.post(Uri.parse(targetUrl), headers: reqHeaders, body: bodyFields).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) return res.body;
    } catch (_) {}

    return null;
  }

  // =========================================================================
  // 1. DRIVER ESPECÍFICO: CAIXA ECONÔMICA FEDERAL (CSV OFICIAL)
  // =========================================================================
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

      final csvText = latin1.decode(res.bodyBytes);
      final lines = csvText.split('\n');

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

        if (municipio != null && municipio.trim().isNotEmpty) {
          final targetMun = municipio.trim().toLowerCase();
          if (!itemCidade.toLowerCase().contains(targetMun) && !targetMun.contains(itemCidade.toLowerCase())) {
            continue;
          }
        }

        if (tipo != null && tipo.trim().isNotEmpty) {
          final targetTipo = tipo.trim().toLowerCase();
          if (!itemDescricao.toLowerCase().contains(targetTipo) && !itemModalidade.toLowerCase().contains(targetTipo)) {
            continue;
          }
        }

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
    } catch (_) {}

    return resultado;
  }

  // =========================================================================
  // 2. DRIVER ESPECÍFICO: LEILÃO IMÓVEL
  // =========================================================================
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
      final linkMatches = RegExp(r"""<a[^>]*href=["']([^"']*/imovel/[^"']*)["'][^>]*>(.*?)</a>""", dotAll: true).allMatches(html);
      final Map<String, Map<String, dynamic>> imoveisMap = {};

      for (final m in linkMatches) {
        final link = m.group(1) ?? '';
        final content = m.group(2) ?? '';
        final text = content.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

        final precos = RegExp(r'R\$\s*([\d\.,]+)').allMatches(text).map((p) => p.group(1)!).toList();

        final imgMatch = RegExp(r"""src=["']([^"']*image\.leilaoimovel[^"']*)["']""").firstMatch(content);
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
    } catch (_) {}

    return resultado;
  }

  // =========================================================================
  // 3. DRIVER ESPECÍFICO: BANCO DO BRASIL (SEU IMÓVEL BB)
  // =========================================================================
  static Future<List<Imovel>> scrapeBancoDoBrasil({
    required String uf,
    String? municipio,
    String? tipo,
    int pagina = 1,
    String? termoBusca,
    int? filtroId,
  }) async {
    final List<Imovel> resultado = [];
    final targetUrl = 'https://seuimovelbb.com.br/catalogo';

    final bodyParams = {
      'pagina': pagina.toString(),
      'contento': '50',
      'ordem': '1',
      'categorias': 'todas',
      'tipoVenda': 'todas',
      'localidade': uf.toUpperCase(),
      'texto': termoBusca ?? '',
    };

    final rawJson = await postViaProxy(targetUrl, bodyParams, headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Referer': 'https://seuimovelbb.com.br/imoveis',
    });

    if (rawJson == null || rawJson.isEmpty) return resultado;

    try {
      final decoded = jsonDecode(rawJson);
      final html = decoded['lista'] ?? '';
      if (html.isEmpty) return resultado;

      // Parse dos cards no HTML do BB
      final linkMatches = RegExp(r"""<a[^>]*href=["']([^"']*/imovel[^"']*)["'][^>]*>(.*?)</a>""", dotAll: true).allMatches(html);
      final seen = <String>{};

      for (var m in linkMatches) {
        final href = m.group(1) ?? '';
        final content = m.group(2) ?? '';
        if (seen.contains(href)) continue;
        seen.add(href);

        final text = content.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        final precos = RegExp(r'R\$\s*([\d\.,]+)').allMatches(text).map((p) => p.group(1)!).toList();
        if (precos.isEmpty) continue;

        double? parseVal(String s) {
          try {
            return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.').trim());
          } catch (_) {
            return null;
          }
        }

        final valLeilao = parseVal(precos[0]);
        final valAvaliacao = precos.length > 1 ? parseVal(precos[1]) : null;

        // Desconto
        final descMatch = RegExp(r'(\d+)%').firstMatch(text);
        final desc = descMatch != null ? double.tryParse(descMatch.group(1)!) : null;

        // Imagem
        final imgMatch = RegExp(r"""src=["']([^"']+)["']""").firstMatch(content);
        String img = imgMatch != null ? imgMatch.group(1)! : '';
        if (img.isNotEmpty && !img.startsWith('http')) img = 'https://seuimovelbb.com.br/' + img;

        final fullLink = href.startsWith('http') ? href : 'https://seuimovelbb.com.br' + href;
        final hash = 'bb_' + href.replaceAll(RegExp(r'[^0-9]'), '');

        resultado.add(Imovel(
          hashImovel: hash.isNotEmpty ? hash : 'bb_' + href.hashCode.abs().toString(),
          fonteSlug: 'bancodobrasil',
          filtroId: filtroId,
          titulo: 'Imóvel Banco do Brasil - ' + uf.toUpperCase(),
          tipo: tipo ?? 'Imóvel',
          endereco: 'Consulte o edital Banco do Brasil',
          cidade: municipio ?? 'São Luís',
          uf: uf.toUpperCase(),
          valorAvaliacao: valAvaliacao,
          valorLeilao: valLeilao,
          desconto: desc,
          modalidade: 'Venda Direta Banco do Brasil',
          nomeLeiloeiro: 'Banco do Brasil',
          linkOriginal: fullLink,
          imagem: img,
          status: 'ativo',
        ));
      }
    } catch (_) {}

    return resultado;
  }

  // =========================================================================
  // 4. DRIVER ESPECÍFICO: PORTAL ZUK (ZUKERMAN LEILÕES)
  // =========================================================================
  static Future<List<Imovel>> scrapeZukerman({
    required String uf,
    String? municipio,
    String? tipo,
    int pagina = 1,
    int? filtroId,
  }) async {
    final cleanUf = uf.toLowerCase().trim();
    String targetUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/u/todos-imoveis/' + cleanUf;
    if (pagina > 1) targetUrl += '?pagina=' + pagina.toString();

    return await _parseZukermanCommon(targetUrl, uf: uf, fonteSlug: 'zukerman', leiloeiro: 'Zukerman Leilões', filtroId: filtroId);
  }

  // =========================================================================
  // 5. DRIVER ESPECÍFICO: BANCO SANTANDER
  // =========================================================================
  static Future<List<Imovel>> scrapeSantander({
    required String uf,
    int pagina = 1,
    int? filtroId,
  }) async {
    String targetUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-santander';
    if (pagina > 1) targetUrl += '?pagina=' + pagina.toString();

    var list = await _parseZukermanCommon(targetUrl, uf: uf, fonteSlug: 'santander', leiloeiro: 'Banco Santander', filtroId: filtroId);
    if (list.isEmpty) {
      // Fallback estado
      final urlUf = 'https://www.portalzuk.com.br/leilao-de-imoveis/u/todos-imoveis/' + uf.toLowerCase();
      list = await _parseZukermanCommon(urlUf, uf: uf, fonteSlug: 'santander', leiloeiro: 'Banco Santander', filtroId: filtroId, filterBankText: 'santander');
    }
    return list;
  }

  // =========================================================================
  // 6. DRIVER ESPECÍFICO: BANCO BRADESCO
  // =========================================================================
  static Future<List<Imovel>> scrapeBradesco({
    required String uf,
    int pagina = 1,
    int? filtroId,
  }) async {
    String targetUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-bradesco';
    if (pagina > 1) targetUrl += '?pagina=' + pagina.toString();

    var list = await _parseZukermanCommon(targetUrl, uf: uf, fonteSlug: 'bradesco', leiloeiro: 'Banco Bradesco', filtroId: filtroId);
    if (list.isEmpty) {
      final urlUf = 'https://www.portalzuk.com.br/leilao-de-imoveis/u/todos-imoveis/' + uf.toLowerCase();
      list = await _parseZukermanCommon(urlUf, uf: uf, fonteSlug: 'bradesco', leiloeiro: 'Banco Bradesco', filtroId: filtroId, filterBankText: 'bradesco');
    }
    return list;
  }

  // =========================================================================
  // 7. DRIVER ESPECÍFICO: CANAIS DE BANCOS (ITAÚ, BANCO INTER, SICREDI)
  // =========================================================================
  static Future<List<Imovel>> scrapeBankChannel({
    required String bankSlug,
    required String bankNome,
    required String uf,
    int pagina = 1,
    int? filtroId,
  }) async {
    String channelUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/u/todos-imoveis/' + uf.toLowerCase();

    if (bankSlug == 'itau') {
      channelUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-itau';
    } else if (bankSlug == 'bancointer') {
      channelUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/v/creditas';
    } else if (bankSlug == 'sicredi') {
      channelUrl = 'https://www.portalzuk.com.br/leilao-de-imoveis/v/banco-sicoob';
    }

    if (pagina > 1) channelUrl += '?pagina=' + pagina.toString();

    return await _parseZukermanCommon(channelUrl, uf: uf, fonteSlug: bankSlug, leiloeiro: bankNome, filtroId: filtroId, filterBankText: bankSlug);
  }

  // =========================================================================
  // 8. DRIVER ESPECÍFICO: SMART LEILÕES CAIXA (API ESTRUTURADA)
  // =========================================================================
  static Future<List<Imovel>> scrapeSmartLeiloesCaixa({
    required String uf,
    String? municipio,
    String? tipo,
    int pagina = 1,
    int? filtroId,
  }) async {
    final List<Imovel> resultado = [];
    final apiUrl = 'https://api-dot-site-smart-leiloes.rj.r.appspot.com/api/imovel/busca';

    try {
      final payload = jsonEncode({
        'page': pagina,
        'limit': 30,
        'uf': uf.toUpperCase(),
      });

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final records = data['records'] ?? data['data'] ?? [];

        for (var r in records) {
          final estado = (r['estado'] ?? '').toString().toUpperCase();
          if (estado.isNotEmpty && estado != uf.toUpperCase()) continue;

          final matricula = (r['hdnImovel'] ?? '').toString();
          final cidade = (r['cidade'] ?? '').toString();
          final bairro = (r['bairro'] ?? '').toString();
          final endereco = (r['endereco'] ?? '').toString();
          final tipoIm = (r['tipoImovel'] ?? 'Imóvel').toString();

          double? valAval = r['precoAvaliacao'] != null ? double.tryParse(r['precoAvaliacao'].toString()) : null;
          double? valLeil = r['precoVenda'] != null ? double.tryParse(r['precoVenda'].toString()) : null;
          double? desc = r['desconto'] != null ? double.tryParse(r['desconto'].toString()) : null;

          String img = '';
          if (r['imagens'] != null && (r['imagens'] as List).isNotEmpty) {
            final fRef = r['imagens'][0]['fileReference'] ?? r['imagens'][0]['filename'];
            if (fRef != null) img = 'https://storage.googleapis.com/imagens-imoveis-smart-leiloes/' + fRef.toString();
          }

          final link = 'https://venda-imoveis.caixa.gov.br/sistema/detalhe-imovel.asp?hdnimovel=' + matricula;
          final titulo = tipoIm + ' em ' + cidade + '/' + uf.toUpperCase() + (bairro.isNotEmpty ? ' - ' + bairro : '');

          resultado.add(Imovel(
            hashImovel: 'smart_' + (matricula.isNotEmpty ? matricula : r['_id'].toString()),
            fonteSlug: 'smartleiloescaixa',
            filtroId: filtroId,
            titulo: titulo,
            tipo: tipoIm,
            endereco: endereco + (bairro.isNotEmpty ? ' - ' + bairro : '') + ', ' + cidade + ' - ' + uf.toUpperCase(),
            cidade: cidade,
            uf: uf.toUpperCase(),
            valorAvaliacao: valAval,
            valorLeilao: valLeil,
            desconto: desc,
            modalidade: (r['modoVenda'] ?? 'Leilão Smart Caixa').toString(),
            nomeLeiloeiro: 'Smart Leilões Caixa',
            linkOriginal: link,
            imagem: img,
            status: 'ativo',
          ));
        }
      }
    } catch (_) {}

    return resultado;
  }

  // =========================================================================
  // PARSER AUXILIAR ZUKERMAN
  // =========================================================================
  static Future<List<Imovel>> _parseZukermanCommon(
    String targetUrl, {
    required String uf,
    required String fonteSlug,
    required String leiloeiro,
    int? filtroId,
    String? filterBankText,
  }) async {
    final List<Imovel> resultado = [];
    final html = await fetchViaProxy(targetUrl);
    if (html == null || html.isEmpty) return resultado;

    try {
      final linkMatches = RegExp(r"""href=["']([^"']*/imovel/[^"']*)["']""").allMatches(html);
      final seen = <String>{};

      for (var m in linkMatches) {
        var href = m.group(1) ?? '';
        if (seen.contains(href)) continue;
        seen.add(href);

        if (!href.startsWith('http')) href = 'https://www.portalzuk.com.br' + href;

        // Extrair UF da URL: /imovel/{uf}/{cidade}/{bairro}/{rua}/{id}
        final urlParts = RegExp(r'/imovel/([a-zA-Z]{2})/([^/]+)/([^/]+)/([^/]+)/').firstMatch(href);
        String cardUf = uf.toUpperCase();
        String cidade = 'São Paulo';
        String rua = '';
        String bairro = '';

        if (urlParts != null) {
          cardUf = urlParts.group(1)!.toUpperCase();
          if (cardUf != uf.toUpperCase()) continue;
          cidade = urlParts.group(2)!.replaceAll('-', ' ');
          bairro = urlParts.group(3)!.replaceAll('-', ' ');
          rua = urlParts.group(4)!.replaceAll('-', ' ');
        }

        final hash = 'zuk_' + href.hashCode.abs().toString();
        final titulo = 'Imóvel em ' + cidade + ' / ' + cardUf + (rua.isNotEmpty ? ' - ' + rua : '');

        resultado.add(Imovel(
          hashImovel: hash,
          fonteSlug: fonteSlug,
          filtroId: filtroId,
          titulo: titulo,
          tipo: 'Imóvel',
          endereco: (rua.isNotEmpty ? rua + ' - ' : '') + bairro + ', ' + cidade + ' - ' + cardUf,
          cidade: cidade,
          uf: cardUf,
          valorAvaliacao: null,
          valorLeilao: null,
          desconto: null,
          modalidade: 'Leilão ' + leiloeiro,
          nomeLeiloeiro: leiloeiro,
          linkOriginal: href,
          imagem: '',
          status: 'ativo',
        ));
      }
    } catch (_) {}

    return resultado;
  }

  // =========================================================================
  // DISPATCHER CENTRAL DE SCRAPING ESPECÍFICO POR FONTE
  // =========================================================================
  static Future<List<Imovel>> scrapeByFonte(
    String fonteSlug, {
    required String uf,
    String? municipio,
    String? tipo,
    int pagina = 1,
    String? termoBusca,
    String? dataFinal,
    int? filtroId,
  }) async {
    final slug = fonteSlug.toLowerCase().trim();

    switch (slug) {
      case 'caixa':
        return await scrapeCaixa(
          uf: uf,
          municipio: municipio,
          tipo: tipo,
          termoBusca: termoBusca,
          dataFinal: dataFinal,
          filtroId: filtroId,
        );

      case 'leilaoimovel':
        return await scrapeLeilaoImovel(
          uf: uf,
          municipio: municipio,
          tipo: tipo,
          pagina: pagina,
          termoBusca: termoBusca,
          dataFinal: dataFinal,
          filtroId: filtroId,
        );

      case 'bancodobrasil':
        return await scrapeBancoDoBrasil(
          uf: uf,
          municipio: municipio,
          tipo: tipo,
          pagina: pagina,
          termoBusca: termoBusca,
          filtroId: filtroId,
        );

      case 'zukerman':
        return await scrapeZukerman(
          uf: uf,
          municipio: municipio,
          tipo: tipo,
          pagina: pagina,
          filtroId: filtroId,
        );

      case 'santander':
        return await scrapeSantander(
          uf: uf,
          pagina: pagina,
          filtroId: filtroId,
        );

      case 'bradesco':
        return await scrapeBradesco(
          uf: uf,
          pagina: pagina,
          filtroId: filtroId,
        );

      case 'itau':
        return await scrapeBankChannel(
          bankSlug: 'itau',
          bankNome: 'Banco Itaú',
          uf: uf,
          pagina: pagina,
          filtroId: filtroId,
        );

      case 'bancointer':
        return await scrapeBankChannel(
          bankSlug: 'bancointer',
          bankNome: 'Banco Inter',
          uf: uf,
          pagina: pagina,
          filtroId: filtroId,
        );

      case 'sicredi':
        return await scrapeBankChannel(
          bankSlug: 'sicredi',
          bankNome: 'Sicredi',
          uf: uf,
          pagina: pagina,
          filtroId: filtroId,
        );

      case 'smartleiloescaixa':
        return await scrapeSmartLeiloesCaixa(
          uf: uf,
          municipio: municipio,
          tipo: tipo,
          pagina: pagina,
          filtroId: filtroId,
        );

      default:
        // Se a fonte não tiver driver específico, consulta Leilão Imóvel como fallback inteligente
        return await scrapeLeilaoImovel(
          uf: uf,
          municipio: municipio,
          tipo: tipo,
          pagina: pagina,
          termoBusca: termoBusca,
          dataFinal: dataFinal,
          filtroId: filtroId,
        );
    }
  }

  /// Teste de Chave em Tempo Real
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
            'message': 'Falha na validação Scrape.do (HTTP ' + res.statusCode.toString() + ').',
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
