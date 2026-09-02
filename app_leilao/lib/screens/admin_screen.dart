import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/filtro.dart';
import '../models/fonte_dados.dart';
import '../models/log_cron.dart';
import '../models/token_pool.dart';
import '../services/sync_service.dart';
import '../services/scraper_service.dart';
import '../widgets/fonte_form_modal.dart';
import '../widgets/filtro_form_modal.dart';
import '../widgets/token_form_modal.dart';
import '../widgets/shad_components.dart';

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
  bool loading = true;
  bool running = false;
  String? runningStatus;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    loadAllAdminData();
  }

  Future loadAllAdminData() async {
    setState(() => loading = true);
    await DBHelper.instance.ensureTokensSeeded();
    final s = await DBHelper.instance.getDashboardStats();
    final f = await DBHelper.instance.getFiltros();
    final ft = await DBHelper.instance.getFontes();
    final tk = await DBHelper.instance.getTokens();
    final lg = await DBHelper.instance.getLogs();

    setState(() {
      stats = s;
      filtros = f;
      fontes = ft;
      tokens = tk;
      logs = lg;
      loading = false;
    });
  }

  Future runSingleRoutine(FiltroSalvo f) async {
    setState(() {
      running = true;
      runningStatus = 'Executando rotina: ' + f.nome;
    });

    try {
      final res = await SyncService.executeRoutine(
        f,
        onProgress: (status, novos) {
          setState(() {
            runningStatus = status + ' (+' + novos.toString() + ' novos)';
          });
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rotina concluída! +' + res['novos'].toString() + ' novos, ' + res['total'].toString() + ' processados em ' + res['tempo'].toString() + 's.')),
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
    if (filtros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma rotina cadastrada!')));
      return;
    }

    setState(() {
      running = true;
      runningStatus = 'Iniciando execução de todas as rotinas ativas...';
    });

    int totalNovos = 0;
    try {
      for (var f in filtros.where((x) => x.ativo)) {
        final res = await SyncService.executeRoutine(
          f,
          onProgress: (status, novos) {
            setState(() {
              runningStatus = '[' + f.nome + '] ' + status;
            });
          },
        );
        totalNovos += (res['novos'] as int? ?? 0);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todas as rotinas foram executadas com sucesso! Total de +' + totalNovos.toString() + ' novos imóveis adicionados.')),
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

  void openFiltroModal({FiltroSalvo? filtro}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FiltroFormModal(filtro: filtro),
    ).then((val) {
      if (val == true) loadAllAdminData();
    });
  }

  Future confirmDeleteFiltro(FiltroSalvo f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir Rotina?'),
        content: Text('Deseja realmente remover a rotina "' + f.nome + '"? Os imóveis já capturados permanecerão na base local.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.discount),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && f.id != null) {
      await DBHelper.instance.deleteFiltro(f.id!);
      await loadAllAdminData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rotina excluída com sucesso!')));
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

  Future clearAllLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Limpar Histórico de Logs?'),
        content: const Text('Deseja realmente apagar todos os logs de execução registrados?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.discount),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.clearLogs();
      await loadAllAdminData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Histórico de logs limpo com sucesso!')));
    }
  }

  Future testRegisteredToken(TokenPool t) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Testando chave ' + t.tokenMascarado + '...')));
    final res = await ScraperService.testarChave(t.provedor, t.token);
    final success = res['success'] == true;
    final msg = res['message'] ?? 'Resposta recebida';
    final latency = res['latency_ms'] != null ? ' (' + res['latency_ms'].toString() + 'ms)' : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: success ? AppColors.successLight : AppColors.discountLight),
            const SizedBox(width: 8),
            Text(success ? 'Chave Operacional' : 'Falha no Teste'),
          ],
        ),
        content: Text(msg + latency, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future testFonteScraper(FonteDados f) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Testando extração do driver ' + f.driver + ' (' + f.slug.toUpperCase() + ')...')));
    final sw = Stopwatch()..start();
    try {
      final list = await ScraperService.scrapeByFonte(f.slug, uf: 'SP', pagina: 1);
      sw.stop();
      final count = list.length;
      final success = count > 0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(success ? Icons.check_circle : Icons.info, color: success ? AppColors.successLight : AppColors.warningLight),
              const SizedBox(width: 8),
              Text(success ? 'Driver Operacional' : 'Sem Imóveis no Teste'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fonte: ' + f.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Driver Específico: ' + f.driver, style: const TextStyle(fontFamily: 'JetBrains Mono', color: AppColors.brandLight, fontSize: 12)),
              const SizedBox(height: 4),
              Text('Imóveis Extraídos: ' + count.toString(), style: const TextStyle(fontSize: 12)),
              Text('Latência / Tempo: ' + sw.elapsedMilliseconds.toString() + 'ms', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          ],
        ),
      );
    } catch (e) {
      sw.stop();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.error, color: AppColors.discountLight),
              SizedBox(width: 8),
              Text('Erro no Teste do Driver'),
            ],
          ),
          content: Text(e.toString(), style: const TextStyle(fontSize: 12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 16,
        title: const Text('Gestão de Rotinas & Scrapers', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.textDim, size: 20), onPressed: loadAllAdminData),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: AppColors.brandLight,
          unselectedLabelColor: AppColors.textDim,
          indicatorColor: AppColors.brandLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Rotinas'),
            Tab(text: 'Fontes'),
            Tab(text: 'Chaves API'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLight))
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
  // TAB 1: ROTINAS DE CAPTURA & DASHBOARD STATS
  // ==========================================
  Widget _buildRotinasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4 Cards de Métricas
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.brandLight)),
            child: Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLight)),
                const SizedBox(width: 10),
                Expanded(child: Text(runningStatus!, style: const TextStyle(color: AppColors.brandLight, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtros Cadastrados & Rotinas', style: TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(filtros.length.toString() + ' rotinas salvas no SQLite', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: () => openFiltroModal(),
                  icon: const Icon(Icons.add, size: 14, color: AppColors.brandLight),
                  label: const Text('Novo Filtro', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 10)),
                  onPressed: running ? null : runAllRoutines,
                  icon: const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                  label: const Text('Baixar Tudo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filtros.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.tune_outlined, size: 48, color: AppColors.textDim.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  const Text('Nenhuma rotina cadastrada', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Toque em "+ Novo Filtro" para definir estado, município, fontes e palavras-chave de captura.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ...filtros.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(f.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    Switch(
                      value: f.ativo,
                      activeColor: AppColors.brandLight,
                      onChanged: (val) async {
                        await DBHelper.instance.toggleFiltro(f.id!, f.ativo);
                        loadAllAdminData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Localização
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 13, color: AppColors.brandLight),
                    const SizedBox(width: 4),
                    Text(
                      'Estado: ' + f.uf + (f.municipio != null && f.municipio!.isNotEmpty ? ' • Cidade: ' + f.municipio! : ' (Todo o Estado)'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fontes configuradas
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: f.fontesList.map((slug) => ShadBadge.secondary(
                    child: Text(slug.toUpperCase()),
                  )).toList(),
                ),

                if (f.termoBusca != null && f.termoBusca!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Palavra-chave: "' + f.termoBusca! + '"', style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontStyle: FontStyle.italic)),
                ],

                const SizedBox(height: 10),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),

                // Ações da Rotina: Baixar Tudo, Editar, Excluir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.brandLight),
                          tooltip: 'Editar Rotina',
                          onPressed: () => openFiltroModal(filtro: f),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.discountLight),
                          tooltip: 'Excluir Rotina',
                          onPressed: () => confirmDeleteFiltro(f),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                      onPressed: running ? null : () => runSingleRoutine(f),
                      icon: const Icon(Icons.download, size: 14, color: Colors.white),
                      label: const Text('Baixar Tudo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          )),
      ],
    );
  }

  // ==========================================
  // TAB 2: FONTES DE DADOS & DRIVERS ESPECÍFICOS
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
                const Text('Fontes de Dados & Drivers Específicos', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(fontes.length.toString() + ' portais de leilão mapeados', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 10)),
              onPressed: openNewFonte,
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Conectar Fonte', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...fontes.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(f.nome, style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline, color: AppColors.successLight, size: 20),
                        tooltip: 'Testar Driver Específico',
                        onPressed: () => testFonteScraper(f),
                      ),
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
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
                    child: Text(f.slug.toUpperCase(), style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: f.driver != 'GenericSource' ? AppColors.successBg : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: f.driver != 'GenericSource' ? AppColors.success.withOpacity(0.3) : AppColors.border),
                    ),
                    child: Text(
                      'Driver: ' + f.driver,
                      style: TextStyle(
                        color: f.driver != 'GenericSource' ? AppColors.successLight : AppColors.textDim,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (f.urlBase.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(f.urlBase, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(horizontal: 10)),
              onPressed: openNewToken,
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Nova Chave', style: TextStyle(color: Colors.white, fontSize: 11)),
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
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
                            child: Text(t.provedor.toUpperCase(), style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: t.ativo ? AppColors.successLight : AppColors.discountLight),
                          ),
                          const SizedBox(width: 4),
                          Text(t.ativo ? 'Ativa' : 'Pausada', style: TextStyle(color: t.ativo ? AppColors.successLight : AppColors.discountLight, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Chave: ' + t.tokenMascarado, style: const TextStyle(color: AppColors.textMain, fontFamily: 'JetBrains Mono', fontSize: 11)),
                      Text('Limite: ' + t.limiteMensal.toString() + ' req/mês', style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.speed, color: AppColors.brandLight, size: 18),
                      tooltip: 'Testar Conexão',
                      onPressed: () => testRegisteredToken(t),
                    ),
                    Switch(
                      value: t.ativo,
                      activeColor: AppColors.brandLight,
                      onChanged: (val) async {
                        await DBHelper.instance.toggleToken(t.id!, t.ativo);
                        loadAllAdminData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.discountLight, size: 18),
                      tooltip: 'Excluir Chave',
                      onPressed: () async {
                        await DBHelper.instance.deleteToken(t.id!);
                        loadAllAdminData();
                      },
                    ),
                  ],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico de Execuções de Rotina', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(logs.length.toString() + ' execuções registradas', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            Row(
              children: [
                if (logs.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.discountLight), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: clearAllLogs,
                    icon: const Icon(Icons.delete_sweep, size: 14, color: AppColors.discountLight),
                    label: const Text('Limpar', style: TextStyle(color: AppColors.discountLight, fontSize: 11)),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: loadAllAdminData,
                  child: const Text('Atualizar', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (logs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: const [
                  Icon(Icons.history_outlined, size: 48, color: AppColors.textDim),
                  SizedBox(height: 8),
                  Text('Nenhum log registrado ainda', style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Execute uma rotina de cron para registrar o histórico.', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ],
              ),
            ),
          )
        else
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: l.status == 'sucesso' ? AppColors.successBg : AppColors.discountBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(l.status.toUpperCase(), style: TextStyle(color: l.status == 'sucesso' ? AppColors.successLight : AppColors.discountLight, fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('+' + l.novos.toString() + ' novos • ' + l.totalImoveis.toString() + ' total processados', style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 11)),
                    Text(l.tempoSegundos.toString() + 's • ' + (l.executadoEm.length >= 16 ? l.executadoEm.substring(0, 16).replaceAll('T', ' ') : l.executadoEm), style: const TextStyle(color: AppColors.textDim, fontFamily: 'JetBrains Mono', fontSize: 10)),
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
