import 'package:flutter/material.dart';
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
      runningStatus = 'Capturando \${f.nome}...';
    });

    try {
      final res = await SyncService.executeRoutine(f, onProgress: (pag, novos) {
        setState(() => runningStatus = 'Página \$pag processada (\$novos novos salvos no SQLite)');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sucesso! \${res['novos']} novos imóveis gravados no SQLite.')),
      );
      await loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: \$e')));
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
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D16),
        elevation: 0,
        title: const Text('Administração & Rotinas', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Métricas
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E293B))),
                  child: Column(children: [
                    const Text('TOTAL NO SQLITE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text('\$totalDb', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 20, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E293B))),
                  child: Column(children: [
                    const Text('ROTINAS ATIVAS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text('\${filtros.length}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 20, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
            ],
          ),

          if (runningStatus != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF38BDF8))),
              child: Text(runningStatus!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
            ),

          const SizedBox(height: 18),
          const Text('Rotinas de Captura', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...filtros.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E293B))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.nome, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('UF: \${f.uf} \${f.municipio != null ? "• Cidade: \${f.municipio}" : ""}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: running ? null : () => runCapture(f),
                  child: const Text('Baixar Tudo', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          )),

          const SizedBox(height: 18),
          const Text('Histórico de Execuções', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...logs.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E293B))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.filtroNome, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12)),
                Text('\${l.novos} novos • \${l.tempoSegundos}s', style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
