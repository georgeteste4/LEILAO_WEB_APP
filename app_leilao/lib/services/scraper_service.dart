import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/imovel.dart';

class ScraperService {
  static Future<List<Imovel>> buscarLeilaoImovel({
    required String uf,
    String? municipio,
    String? tipo,
    int pagina = 1,
  }) async {
    final List<Imovel> lista = [];
    try {
      String url = 'https://www.leilaoimovel.com.br/imoveis/\${uf.toLowerCase()}';
      if (municipio != null && municipio.isNotEmpty) {
        final munSlug = municipio.toLowerCase().replaceAll(' ', '-');
        url += '/\$munSlug';
      }
      url += '?pagina=\$pagina';
      if (tipo != null && tipo.isNotEmpty) {
        url += '&tipo=\$tipo';
      }

      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final html = response.body;
        final cardRegex = RegExp(r'<article[^>]*data-link="([^"]*)"[^>]*>(.*?)</article>', dotAll: true);
        final matches = cardRegex.allMatches(html);

        for (final m in matches) {
          final link = m.group(1) ?? '';
          final content = m.group(2) ?? '';

          final titleMatch = RegExp(r'<h[23][^>]*>(.*?)</h[23]>').firstMatch(content);
          final title = titleMatch?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? 'Imóvel Leilão';

          final valAvalMatch = RegExp(r'Avalia[çc][ãa]o:[^R]*R\$\s*([\d\.,]+)', caseSensitive: false).firstMatch(content);
          final valLeilaoMatch = RegExp(r'Lance[^R]*R\$\s*([\d\.,]+)', caseSensitive: false).firstMatch(content);
          final descMatch = RegExp(r'(\d+)%\s*desconto', caseSensitive: false).firstMatch(content);
          final imgMatch = RegExp(r'<img[^>]*src="([^"]*)"').firstMatch(content);

          double? parseMoney(String? s) {
            if (s == null) return null;
            return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.').trim());
          }

          final aval = parseMoney(valAvalMatch?.group(1));
          final leilao = parseMoney(valLeilaoMatch?.group(1));
          final desc = descMatch != null ? double.tryParse(descMatch.group(1)!) : (aval != null && leilao != null && aval > 0 ? ((aval - leilao) / aval) * 100 : null);

          lista.add(Imovel(
            hashImovel: 'hash_\${link.hashCode.abs()}',
            fonteSlug: 'leilaoimovel',
            titulo: title,
            tipo: tipo ?? 'Imóvel',
            endereco: '',
            cidade: municipio ?? '',
            uf: uf.toUpperCase(),
            valorAvaliacao: aval,
            valorLeilao: leilao,
            desconto: desc,
            modalidade: 'Leilão',
            linkOriginal: link.startsWith('http') ? link : 'https://www.leilaoimovel.com.br\$link',
            imagem: imgMatch?.group(1) ?? '',
          ));
        }
      }
    } catch (e) {
      print('Erro ao raspar Leilão Imóvel: \$e');
    }
    return lista;
  }
}
