import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../services/sync_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UpdateInfo? updateInfo;
  bool checking = false;
  double? downloadProgress;
  bool syncingDb = false;

  Future checkAppUpdate() async {
    setState(() => checking = true);
    final info = await UpdateService.checkUpdate();
    setState(() {
      updateInfo = info;
      checking = false;
    });

    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já está na versão mais recente (v1.0.0)!')),
      );
    }
  }

  Future downloadApk() async {
    if (updateInfo == null) return;
    setState(() => downloadProgress = 0.0);

    final file = await UpdateService.downloadAndInstallApk(updateInfo!.apkUrl, (p) {
      setState(() => downloadProgress = p);
    });

    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download concluído! Abrindo instalador do APK...')),
      );
    }
    setState(() => downloadProgress = null);
  }

  Future syncFromGitHub() async {
    setState(() => syncingDb = true);
    try {
      final res = await SyncService.syncFromGitHub();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Base atualizada com sucesso! \${res['novos']} novos imóveis.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: \$e')));
    } finally {
      setState(() => syncingDb = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: const Text('Configurações & Atualizações', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Atualização de APK In-App
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Atualização do Aplicativo (APK)', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
                      child: const Text('v1.0.0', style: TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Busca novas compilações geradas pelo GitHub Actions e atualiza o aplicativo diretamente no celular.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 12),

                if (updateInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.success)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova versão v\${updateInfo!.version} disponível!', style: const TextStyle(color: AppColors.successLight, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(updateInfo!.releaseNotes, style: const TextStyle(color: AppColors.textMain, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (downloadProgress != null) ...[
                  LinearProgressIndicator(value: downloadProgress, color: AppColors.brandLight, backgroundColor: AppColors.surfaceElevated),
                  const SizedBox(height: 6),
                  Text('Baixando APK: \${(downloadProgress! * 100).round()}%', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.brandLight, fontSize: 11)),
                  const SizedBox(height: 10),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                        onPressed: checking ? null : checkAppUpdate,
                        child: Text(checking ? 'Buscando...' : 'Buscar Atualização', style: const TextStyle(color: AppColors.brandLight)),
                      ),
                    ),
                    if (updateInfo != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: downloadProgress != null ? null : downloadApk,
                          child: const Text('Baixar e Atualizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gestão da Base SQLite
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestão da Base de Dados SQLite', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Sincronize a base de imóveis do celular diretamente com os dados mais recentes do GitHub.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                    onPressed: syncingDb ? null : syncFromGitHub,
                    child: Text(syncingDb ? 'Baixando do GitHub...' : 'Baixar Base do GitHub', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                    onPressed: () async {
                      await DBHelper.instance.resetDatabase();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base padrão restaurada com 373 imóveis!')));
                    },
                    child: const Text('Restaurar Base Padrão', style: TextStyle(color: AppColors.textDim)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
