import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/filtro.dart';
import '../models/log_cron.dart';
import '../services/sync_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<FiltroSalvo> filtros = [];
  List<LogCron> logs = [];
  int totalDb = 0;
  bool running = false;
  String? runningStatus;

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future loadAdminData() async {
    final flts = await DBHelper.instance.getFiltros();
    final lgs = await DBHelper.instance.getLogs();
    final count = await DBHelper.instance.countImoveis();
    setState(() {
      filtros = flts;
      logs = lgs;
      totalDb = count;
    });
  }

  Future runCapture(FiltroSalvo f) async {
    setState(() {
      running = true;
      runningStatus = 'Extraindo imóveis para ${f.nome}...';
    });

    try {
      final res = await SyncService.executeRoutine(f, onProgress: (pag, novos) {
        setState(() => runningStatus = 'Página $pag processada ($novos novos salvos no SQLite)');
      });
      final novos = res['novos'];
      final tempo = res['tempo'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Concluído em ${tempo}s! $novos novos salvos no SQLite.')),
      );

      await loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() {
        running = false;
        runningStatus = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: const Text('Administração & Rotinas', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Column(children: [
                    const Text('TOTAL NO SQLITE', style: TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$totalDb', style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Column(children: [
                    const Text('ROTINAS ATIVAS', style: TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${filtros.length}', style: const TextStyle(color: AppColors.successLight, fontFamily: 'JetBrains Mono', fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),

          if (runningStatus != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.brandLight)),
              child: Text(runningStatus!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.brandLight, fontSize: 12, fontWeight: FontWeight.bold)),
            ),

          const SizedBox(height: 18),
          const Text('Rotinas de Captura', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...filtros.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('UF: ${f.uf} ${f.municipio != null ? "• Cidade: ${f.municipio}" : ""}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                  onPressed: running ? null : () => runCapture(f),
                  child: const Text('Baixar Tudo', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          )),

          const SizedBox(height: 18),
          const Text('Histórico de Execuções', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...logs.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.filtroNome, style: const TextStyle(color: AppColors.textMain, fontSize: 12)),
                Text('${l.novos} novos • ${l.tempoSegundos}s', style: const TextStyle(color: AppColors.successLight, fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
