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
      throw Exception('Falha ao baixar dados do GitHub: HTTP ' + response.statusCode.toString());
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

  /// Executa a rotina para todas as fontes configuradas no filtro
  static Future<Map<String, dynamic>> executeRoutine(FiltroSalvo f, {Function(String status, int novos)? onProgress}) async {
    final stopwatch = Stopwatch()..start();
    int novos = 0;
    int atualizados = 0;
    int totalProcessados = 0;

    List<String> fontes = f.fontesList;
    if (fontes.isEmpty) {
      fontes = ['caixa', 'leilaoimovel'];
    }

    for (final fonteSlug in fontes) {
      if (onProgress != null) {
        onProgress('Extraindo na fonte: ' + fonteSlug.toUpperCase(), novos);
      }

      List<Imovel> loteFonte = [];

      if (fonteSlug == 'caixa') {
        loteFonte = await ScraperService.scrapeCaixa(
          uf: f.uf,
          municipio: f.municipio,
          tipo: f.tipo,
          termoBusca: f.termoBusca,
          dataFinal: f.dataFinalLeilao,
          filtroId: f.id,
        );
      } else if (fonteSlug == 'leilaoimovel') {
        for (int p = 1; p <= 2; p++) {
          final pagItems = await ScraperService.scrapeLeilaoImovel(
            uf: f.uf,
            municipio: f.municipio,
            tipo: f.tipo,
            pagina: p,
            termoBusca: f.termoBusca,
            dataFinal: f.dataFinalLeilao,
            filtroId: f.id,
          );
          loteFonte.addAll(pagItems);
          if (pagItems.isEmpty) break;
        }
      } else {
        loteFonte = await ScraperService.scrapePortalGenerico(
          slug: fonteSlug,
          nomeFonte: fonteSlug,
          uf: f.uf,
          municipio: f.municipio,
          tipo: f.tipo,
          filtroId: f.id,
        );
      }

      for (var im in loteFonte) {
        final res = await DBHelper.instance.upsertImovel(im, filtroId: f.id);
        if (res == 'inserted') novos++;
        if (res == 'updated') atualizados++;
        totalProcessados++;
      }

      if (onProgress != null) {
        onProgress('Fonte ' + fonteSlug.toUpperCase() + ': ' + loteFonte.length.toString() + ' imóveis analisados', novos);
      }
    }

    stopwatch.stop();
    final tempo = stopwatch.elapsed.inSeconds;

    await DBHelper.instance.insertLog(LogCron(
      filtroId: f.id,
      filtroNome: f.nome,
      status: 'sucesso',
      totalPaginas: fontes.length,
      totalImoveis: totalProcessados,
      novos: novos,
      atualizados: atualizados,
      tempoSegundos: tempo,
      executadoEm: DateTime.now().toIso8601String(),
    ));

    return {
      'novos': novos,
      'atualizados': atualizados,
      'total': totalProcessados,
      'tempo': tempo,
    };
  }
}
