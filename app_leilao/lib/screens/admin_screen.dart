import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/filtro.dart';
import '../models/fonte_dados.dart';
import '../models/token_pool.dart';
import '../models/log_cron.dart';
import '../services/sync_service.dart';
import '../widgets/fonte_form_modal.dart';
import '../widgets/token_form_modal.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  Map<String, dynamic> stats = {};
  List<FiltroSalvo> filtros = [];
  List<FonteDados> fontes = [];
  List<TokenPool> tokens = [];
  List<LogCron> logs = [];

  bool running = false;
  String? runningStatus;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    loadAllAdminData();
  }

  Future loadAllAdminData() async {
    setState(() => loading = true);
    final s = await DBHelper.instance.getDashboardStats();
    final flts = await DBHelper.instance.getFiltros();
    final fnts = await DBHelper.instance.getFontes();
    final toks = await DBHelper.instance.getTokens();
    final lgs = await DBHelper.instance.getLogs();

    setState(() {
      stats = s;
      filtros = flts;
      fontes = fnts;
      tokens = toks;
      logs = lgs;
      loading = false;
    });
  }

  Future runSingleRoutine(FiltroSalvo f) async {
    setState(() {
      running = true;
      runningStatus = 'Extraindo imóveis para ' + f.nome + '...';
    });

    try {
      final res = await SyncService.executeRoutine(f, onProgress: (pag, novos) {
        setState(() => runningStatus = 'Página ' + pag.toString() + ' processada (' + novos.toString() + ' novos salvos no SQLite)');
      });
      final novos = res['novos'];
      final tempo = res['tempo'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Concluído em ' + tempo.toString() + 's! ' + novos.toString() + ' novos salvos no SQLite.')),
      );
      await loadAllAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + e.toString())));
    } finally {
      setState(() {
        running = false;
        runningStatus = null;
      });
    }
  }

  Future runAllRoutines() async {
    if (filtros.isEmpty) return;
    setState(() {
      running = true;
      runningStatus = 'Executando todas as ' + filtros.length.toString() + ' rotinas em lote...';
    });

    int totalNovos = 0;
    try {
      for (var f in filtros) {
        setState(() => runningStatus = 'Extraindo rotina: ' + f.nome);
        final res = await SyncService.executeRoutine(f);
        totalNovos += (res['novos'] as int? ?? 0);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todas as rotinas concluídas! ' + totalNovos.toString() + ' novos imóveis adicionados.')),
      );
      await loadAllAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ' + e.toString())));
    } finally {
      setState(() {
        running = false;
        runningStatus = null;
      });
    }
  }

  void openNewFonte() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FonteFormModal(),
    ).then((val) {
      if (val == true) loadAllAdminData();
    });
  }

  void openNewToken() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TokenFormModal(),
    ).then((val) {
      if (val == true) loadAllAdminData();
    });
  }

  void openNewFiltroDialog() {
    final nomeCtrl = TextEditingController();
    final ufCtrl = TextEditingController(text: 'MA');
    final cidadeCtrl = TextEditingController();
    final termoCtrl = TextEditingController();
    String tipoFiltro = 'todos';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        title: const Text('Cadastrar Novo Filtro de Captura', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Identificador do Filtro *', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ufCtrl,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'UF *', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: cidadeCtrl,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                      decoration: const InputDecoration(labelText: 'Município (Opcional)', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: termoCtrl,
                style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Palavra-chave / Termo', labelStyle: TextStyle(color: AppColors.textDim, fontSize: 11)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textDim))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
            onPressed: () async {
              if (nomeCtrl.text.trim().isNotEmpty) {
                final flt = FiltroSalvo(
                  nome: nomeCtrl.text.trim(),
                  uf: ufCtrl.text.trim().toUpperCase(),
                  municipio: cidadeCtrl.text.trim().isNotEmpty ? cidadeCtrl.text.trim() : null,
                  tipo: tipoFiltro != 'todos' ? tipoFiltro : null,
                  termoBusca: termoCtrl.text.trim().isNotEmpty ? termoCtrl.text.trim() : null,
                  ativo: true,
                );
                await DBHelper.instance.insertFiltro(flt);
                Navigator.pop(ctx);
                loadAllAdminData();
              }
            },
            child: const Text('Salvar Filtro', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: const Text('Painel de Administração & Tarefas', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.brandLight), onPressed: loadAllAdminData),
        ],
        bottom: TabBar(
          controller: tabController,
          indicatorColor: AppColors.brandLight,
          labelColor: AppColors.brandLight,
          unselectedLabelColor: AppColors.textDim,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Rotinas'),
            Tab(text: 'Fontes'),
            Tab(text: 'Chaves API'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandLight))
          : TabBarView(
              controller: tabController,
              children: [
                _buildRotinasTab(),
                _buildFontesTab(),
                _buildTokensTab(),
                _buildLogsTab(),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: ROTINAS & DASHBOARD STATS
  // ==========================================
  Widget _buildRotinasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4 Cards de Métricas (Paridade total com admin.html)
        Row(
          children: [
            Expanded(child: _metricCard('IMÓVEIS NO BANCO', (stats['total_imoveis'] ?? 0).toString(), AppColors.brandLight)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('FILTROS ATIVOS', (stats['total_filtros'] ?? 0).toString(), AppColors.successLight)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _metricCard('EXECUÇÕES DE CRON', (stats['total_execucoes'] ?? 0).toString(), AppColors.warningLight)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('ÚLTIMA SYNC', (stats['ultima_sync'] ?? '-').toString(), AppColors.textMain)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Filtros Cadastrados & Rotinas', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: openNewFiltroDialog,
                  child: const Text('+ Novo Filtro', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: running ? null : runAllRoutines,
                  child: const Text('Executar Todos', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...filtros.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('UF: ' + f.uf + (f.municipio != null ? ' • ' + f.municipio! : ''), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.discountLight, size: 18),
                onPressed: () async {
                  await DBHelper.instance.deleteFiltro(f.id!);
                  loadAllAdminData();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 10)),
                onPressed: running ? null : () => runSingleRoutine(f),
                child: const Text('Baixar Tudo', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ==========================================
  // TAB 2: FONTES DE DADOS & SCRAPERS
  // ==========================================
  Widget _buildFontesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fontes de Dados & Scrapers Multi-Site', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(fontes.length.toString() + ' portais de leilão conectados', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 10)),
              onPressed: openNewFonte,
              child: const Text('+ Conectar Fonte', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...fontes.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(f.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                  Switch(
                    value: f.ativo,
                    activeColor: AppColors.brandLight,
                    onChanged: (val) async {
                      await DBHelper.instance.toggleFonte(f.id!, f.ativo);
                      loadAllAdminData();
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
                    child: Text(f.slug.toUpperCase(), style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Text('Driver: ' + f.driver, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                ],
              ),
              if (f.urlBase.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(f.urlBase, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ],
          ),
        )),
      ],
    );
  }

  // ==========================================
  // TAB 3: POOL DE CHAVES / TOKENS
  // ==========================================
  Widget _buildTokensTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pool de Chaves de Scraping', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(tokens.length.toString() + ' chaves cadastradas no SQLite', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 10)),
              onPressed: openNewToken,
              child: const Text('+ Nova Chave', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (tokens.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: const [
                  Icon(Icons.vpn_key_outlined, size: 48, color: AppColors.textDim),
                  SizedBox(height: 8),
                  Text('Nenhuma chave de API no pool', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Adicione tokens do Scrape.do ou Firecrawl para rotacionar requisições em portais bloqueados.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ...tokens.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.provedor.toUpperCase(), style: const TextStyle(color: AppColors.brandLight, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Chave: ' + t.tokenMascarado, style: const TextStyle(color: AppColors.textMain, fontFamily: 'JetBrains Mono', fontSize: 11)),
                    Text('Limite: ' + t.limiteMensal.toString() + ' req/mês', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.discountLight, size: 18),
                  onPressed: () async {
                    await DBHelper.instance.deleteToken(t.id!);
                    loadAllAdminData();
                  },
                ),
              ],
            ),
          )),
      ],
    );
  }

  // ==========================================
  // TAB 4: HISTÓRICO DE LOGS
  // ==========================================
  Widget _buildLogsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Histórico de Execuções de Rotina', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: loadAllAdminData,
              child: const Text('Atualizar', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...logs.map((l) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.filtroNome, style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(l.status.toUpperCase(), style: TextStyle(color: l.status == 'sucesso' ? AppColors.successLight : AppColors.discountLight, fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('+' + l.novos.toString() + ' novos • ' + l.totalImoveis.toString() + ' total', style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 11)),
                  Text(l.tempoSegundos.toString() + 's', style: const TextStyle(color: AppColors.textDim, fontFamily: 'JetBrains Mono', fontSize: 11)),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: col, fontFamily: 'JetBrains Mono', fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
