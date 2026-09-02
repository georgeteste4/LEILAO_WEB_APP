import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String apkUrl;
  final String releaseNotes;

  UpdateInfo({required this.version, required this.apkUrl, required this.releaseNotes});
}

class UpdateService {
  static const String currentVersion = '1.0.0';
  static const String githubRepo = 'georgeteste4/LEILAO_WEB_APP';

  static Future<UpdateInfo?> checkUpdate() async {
    final url = 'https://api.github.com/repos/\$githubRepo/releases/latest';
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'LeilaoApp-Updater',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tag = (data['tag_name'] ?? '').toString().replaceAll('v', '').trim();
        final assets = data['assets'] as List<dynamic>? ?? [];

        String? downloadUrl;
        for (var a in assets) {
          if ((a['name'] ?? '').toString().endsWith('.apk')) {
            downloadUrl = a['browser_download_url'];
            break;
          }
        }

        if (downloadUrl != null) {
          return UpdateInfo(
            version: tag,
            apkUrl: downloadUrl,
            releaseNotes: data['body'] ?? 'Novas melhorias e correções.',
          );
        }
      }
    } catch (e) {
      print('Erro ao checar update: \$e');
    }
    return null;
  }

  static Future<File?> downloadAndInstallApk(String url, Function(double) onProgress) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final file = File('\${dir.path}/leilao_update.apk');
      final sink = file.openWrite();

      await response.stream.listen((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }).asFuture();

      await sink.close();
      client.close();

      // Abrir o instalador nativo do Android
      await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
      return file;
    } catch (e) {
      print('Erro ao baixar APK: \$e');
      return null;
    }
  }
}
