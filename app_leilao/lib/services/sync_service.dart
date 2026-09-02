import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';
import '../models/filtro.dart';
import '../models/imovel.dart';
import '../models/log_cron.dart';
import 'scraper_service.dart';

class SyncService {
  static const String githubSeedUrl = 'https://raw.githubusercontent.com/georgeteste4/LEILAO_WEB_APP/main/data/seed_imoveis.json';

  static Future<Map<String, int>> syncFromGitHub({Function(int, int)? onProgress}) async {
    final response = await http.get(Uri.parse(githubSeedUrl));
    if (response.statusCode != 200) {
      throw Exception('Falha ao baixar dados do GitHub: HTTP \${response.statusCode}');
    }

    final List<dynamic> list = jsonDecode(response.body);
    int novos = 0;
    int atualizados = 0;

    for (int i = 0; i < list.length; i++) {
      final imovel = Imovel.fromMap(list[i]);
      final res = await DBHelper.instance.upsertImovel(imovel);
      if (res == 'inserted') novos++;
      if (res == 'updated') atualizados++;
      if (onProgress != null && i % 10 == 0) {
        onProgress(i + 1, list.length);
      }
    }

    return {'total': list.length, 'novos': novos, 'atualizados': atualizados};
  }

  static Future<Map<String, dynamic>> executeRoutine(FiltroSalvo f, {Function(int, int)? onProgress}) async {
    final stopwatch = Stopwatch()..start();
    int novos = 0;
    int atualizados = 0;
    int totalPaginas = 1;

    for (int p = 1; p <= 2; p++) {
      final imoveis = await ScraperService.buscarLeilaoImovel(
        uf: f.uf,
        municipio: f.municipio,
        tipo: f.tipo,
        pagina: p,
      );

      for (var im in imoveis) {
        final res = await DBHelper.instance.upsertImovel(im);
        if (res == 'inserted') novos++;
        if (res == 'updated') atualizados++;
      }

      totalPaginas = p;
      if (onProgress != null) onProgress(p, novos);
      if (imoveis.isEmpty) break;
    }

    stopwatch.stop();
    final tempo = stopwatch.elapsed.inSeconds;

    await DBHelper.instance.insertLog(LogCron(
      filtroId: f.id,
      filtroNome: f.nome,
      status: 'sucesso',
      totalPaginas: totalPaginas,
      totalImoveis: novos + atualizados,
      novos: novos,
      atualizados: atualizados,
      tempoSegundos: tempo,
      executadoEm: DateTime.now().toIso8601String(),
    ));

    return {'novos': novos, 'atualizados': atualizados, 'tempo': tempo};
  }
}
