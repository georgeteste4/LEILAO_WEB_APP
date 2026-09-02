import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Download concluído! Instalador aberto.')),
      );
    }
    setState(() => downloadProgress = null);
  }

  Future syncFromGitHub() async {
    setState(() => syncingDb = true);
    try {
      final res = await SyncService.syncFromGitHub();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Base atualizada! \${res['novos']} novos imóveis.')),
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
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D16),
        elevation: 0,
        title: const Text('Configurações & Atualizações', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção Atualizador de APK
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Atualização do Aplicativo (APK)', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                      child: const Text('v1.0.0', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Verifique novas versões compiladas no GitHub e atualize o APK diretamente pelo app.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const SizedBox(height: 12),

                if (updateInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF064E3B).withOpacity(0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF059669))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova versão v\${updateInfo!.version} disponível!', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(updateInfo!.releaseNotes, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (downloadProgress != null) ...[
                  LinearProgressIndicator(value: downloadProgress, color: const Color(0xFF38BDF8), backgroundColor: const Color(0xFF1E293B)),
                  const SizedBox(height: 6),
                  Text('Baixando APK: \${(downloadProgress! * 100).round()}%', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                  const SizedBox(height: 10),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: checking ? null : checkAppUpdate,
                        child: Text(checking ? 'Buscando...' : 'Buscar Atualização', style: const TextStyle(color: Color(0xFF38BDF8))),
                      ),
                    ),
                    if (updateInfo != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
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

          // Seção Base de Dados
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestão da Base de Dados SQLite', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Baixe novos dados de leilões direto do GitHub ou restaure os dados iniciais.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: syncingDb ? null : syncFromGitHub,
                    child: Text(syncingDb ? 'Baixando do GitHub...' : 'Baixar Base do GitHub', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await DBHelper.instance.resetDatabase();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base padrão restaurada!')));
                    },
                    child: const Text('Restaurar Base Padrão', style: TextStyle(color: Color(0xFF94A3B8))),
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
