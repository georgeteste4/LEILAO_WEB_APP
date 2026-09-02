import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/states.dart';
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../widgets/property_card.dart';
import '../widgets/property_table.dart';
import '../widgets/property_list.dart';
import '../widgets/property_detail_modal.dart';
import '../widgets/shad_components.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Imovel> imoveis = [];
  Set<String> favoritosHashes = {};
  List<String> cidadesDisponiveis = [];
  List<String> cidadesSelecionadas = [];
  bool loading = true;
  bool apenasSalvos = false;
  String viewMode = 'grid';
  String uf = 'MA';
  String tipo = 'todos';
  String fonte = 'todas';
  String? dataFinal;
  String ordem = 'desconto_desc';
  final searchController = TextEditingController();

  // Mapeamento de Fontes oficiais
  static const Map<String, String> fontesMap = {
    'todas': 'Todas as Fontes',
    'caixa': 'Caixa Econômica Federal',
    'leilaoimovel': 'Leilão Imóvel',
    'bancodobrasil': 'Banco do Brasil',
    'zukerman': 'Portal Zuk (Zukerman)',
    'santander': 'Banco Santander',
    'bradesco': 'Banco Bradesco',
    'itau': 'Banco Itaú',
    'bancointer': 'Banco Inter',
    'sicredi': 'Sicredi',
    'smartleiloescaixa': 'Smart Leilões Caixa',
    'megaleiloes': 'Mega Leilões',
    'sodresantoro': 'Sodré Santoro',
  };

  // Mapeamento de Tipos de Imóveis oficiais
  static const Map<String, String> tiposMap = {
    'todos': 'Todos os Tipos',
    'apartamento': 'Apartamento',
    'casa': 'Casa',
    'terreno': 'Terreno',
    'rural': 'Rural / Fazenda',
    'comercial': 'Comercial / Sala',
    'galpao': 'Galpão',
  };

  // Mapeamento de Ordenações oficiais
  static const Map<String, String> ordenacoesMap = {
    'desconto_desc': 'Maior Desconto %',
    'desconto_asc': 'Menor Desconto %',
    'valor_asc': 'Menor Preço de Leilão',
    'valor_desc': 'Maior Preço de Leilão',
    'avaliacao_desc': 'Maior Valor de Avaliação',
    'encerramento_asc': 'Encerramento Mais Próximo',
    'recentes': 'Mais Recentes',
  };

  @override
  void initState() {
    super.initState();
    loadProperties();
  }

  Future loadProperties() async {
    setState(() => loading = true);
    final favs = await DBHelper.instance.getFavoritosHashes();
    final list = await DBHelper.instance.getImoveis(
      uf: uf,
      municipios: cidadesSelecionadas.isNotEmpty ? cidadesSelecionadas : null,
      tipo: tipo != 'todos' ? tipo : null,
      fonte: fonte != 'todas' ? fonte : null,
      dataFinal: dataFinal,
      busca: searchController.text,
      apenasFavoritos: apenasSalvos,
      ordem: ordem,
    );
    final cidades = await DBHelper.instance.getCidadesByUf(uf);

    setState(() {
      imoveis = list;
      favoritosHashes = favs;
      cidadesDisponiveis = cidades;
      loading = false;
    });
  }

  Future toggleFavorite(String hash) async {
    final res = await DBHelper.instance.toggleFavorito(hash);
    setState(() {
      if (res) {
        favoritosHashes.add(hash);
      } else {
        favoritosHashes.remove(hash);
      }
    });
  }

  void openDetail(Imovel imovel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PropertyDetailModal(imovel: imovel),
    ).then((_) => loadProperties());
  }

  void clearAllFilters() {
    setState(() {
      searchController.clear();
      cidadesSelecionadas.clear();
      tipo = 'todos';
      fonte = 'todas';
      dataFinal = null;
      apenasSalvos = false;
      ordem = 'desconto_desc';
    });
    loadProperties();
  }

  // =========================================================================
  // MODAL 1: SELEÇÃO DE ESTADO (UF)
  // =========================================================================
  void openUfPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selecione o Estado (UF)', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textDim, size: 20), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: kEstadosBrasil.map((e) => ListTile(
                title: Text(e.sigla + ' — ' + e.nome, style: TextStyle(color: uf == e.sigla ? AppColors.brandLight : AppColors.textMain, fontWeight: uf == e.sigla ? FontWeight.bold : FontWeight.normal)),
                trailing: uf == e.sigla ? const Icon(Icons.check, color: AppColors.brandLight, size: 18) : null,
                onTap: () {
                  setState(() {
                    uf = e.sigla;
                    cidadesSelecionadas.clear();
                  });
                  Navigator.pop(ctx);
                  loadProperties();
                },
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODAL 2: SELEÇÃO DE MUNICÍPIOS (MULTI-SELECT COM PESQUISA IGUAL AO INDEX.HTML)
  // =========================================================================
  void openMunicipiosModal() {
    final searchMunCtrl = TextEditingController();
    List<String> tempSelected = List.from(cidadesSelecionadas);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filterText = searchMunCtrl.text.trim().toLowerCase();
            final filteredCidades = cidadesDisponiveis.where((c) => c.toLowerCase().contains(filterText)).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filtrar por Municípios', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(uf + ' • ' + tempSelected.length.toString() + ' selecionados de ' + cidadesDisponiveis.length.toString() + ' disponíveis', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textDim, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ações Rápidas: Marcar Visíveis / Limpar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            for (var c in filteredCidades) {
                              if (!tempSelected.contains(c)) tempSelected.add(c);
                            }
                          });
                        },
                        child: const Text('Marcar Visíveis', style: TextStyle(color: AppColors.brandLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempSelected.clear();
                          });
                        },
                        child: const Text('Limpar Seleção', style: TextStyle(color: AppColors.discountLight, fontSize: 12)),
                      ),
                    ],
                  ),

                  // Campo de Pesquisa de Município
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: searchMunCtrl,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Digite para filtrar cidade...',
                        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 18),
                        suffixIcon: searchMunCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: AppColors.textDim),
                                onPressed: () {
                                  searchMunCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chips Selecionados
                  if (tempSelected.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 70),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: tempSelected.map((c) => ShadBadge.secondary(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(c),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setModalState(() => tempSelected.remove(c)),
                                  child: const Icon(Icons.close, size: 12, color: AppColors.textDim),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Divider(height: 1, color: AppColors.border),

                  // Lista de Checkboxes de Cidades
                  Expanded(
                    child: filteredCidades.isEmpty
                        ? const Center(child: Text('Nenhum município encontrado com esse nome.', style: TextStyle(color: AppColors.textDim, fontSize: 12)))
                        : ListView.builder(
                            itemCount: filteredCidades.length,
                            itemBuilder: (context, i) {
                              final cid = filteredCidades[i];
                              final isChecked = tempSelected.contains(cid);
                              return CheckboxListTile(
                                value: isChecked,
                                activeColor: AppColors.brand,
                                title: Text(cid, style: TextStyle(color: isChecked ? AppColors.brandLight : AppColors.textMain, fontSize: 13, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      tempSelected.add(cid);
                                    } else {
                                      tempSelected.remove(cid);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          cidadesSelecionadas = tempSelected;
                        });
                        Navigator.pop(ctx);
                        loadProperties();
                      },
                      child: Text('Aplicar Cidades (' + tempSelected.length.toString() + ')', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // MODAL 3: SELEÇÃO DE TIPO DE IMÓVEL
  // =========================================================================
  void openTipoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tipo de Imóvel', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...tiposMap.entries.map((e) => ListTile(
            title: Text(e.value, style: TextStyle(color: tipo == e.key ? AppColors.brandLight : AppColors.textMain, fontWeight: tipo == e.key ? FontWeight.bold : FontWeight.normal)),
            trailing: tipo == e.key ? const Icon(Icons.check, color: AppColors.brandLight, size: 18) : null,
            onTap: () {
              setState(() => tipo = e.key);
              Navigator.pop(ctx);
              loadProperties();
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // MODAL 4: SELEÇÃO DE FONTE DE DADOS (PORTAIS MULTI-SITE)
  // =========================================================================
  void openFontePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Fonte de Dados / Portal', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              children: fontesMap.entries.map((e) => ListTile(
                title: Text(e.value, style: TextStyle(color: fonte == e.key ? AppColors.brandLight : AppColors.textMain, fontWeight: fonte == e.key ? FontWeight.bold : FontWeight.normal)),
                trailing: fonte == e.key ? const Icon(Icons.check, color: AppColors.brandLight, size: 18) : null,
                onTap: () {
                  setState(() => fonte = e.key);
                  Navigator.pop(ctx);
                  loadProperties();
                },
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // =========================================================================
  // MODAL 5: SELEÇÃO DE DATA FINAL (ATÉ)
  // =========================================================================
  Future openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brand,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final df = DateFormat('dd/MM/yyyy').format(picked);
      setState(() => dataFinal = df);
      loadProperties();
    }
  }

  // =========================================================================
  // MODAL 6: ORDENAÇÃO COMPLETA (IGUAL AO INDEX.HTML)
  // =========================================================================
  void openSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Ordenar Imóveis', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold))),
          const Divider(height: 1, color: AppColors.border),
          ...ordenacoesMap.entries.map((e) => ListTile(
            title: Text(e.value, style: TextStyle(color: ordem == e.key ? AppColors.brandLight : AppColors.textMain, fontWeight: ordem == e.key ? FontWeight.bold : FontWeight.normal)),
            trailing: ordem == e.key ? const Icon(Icons.check, color: AppColors.brandLight, size: 18) : null,
            onTap: () {
              setState(() => ordem = e.key);
              Navigator.pop(ctx);
              loadProperties();
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = searchController.text.isNotEmpty ||
        cidadesSelecionadas.isNotEmpty ||
        tipo != 'todos' ||
        fonte != 'todas' ||
        dataFinal != null ||
        apenasSalvos;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandLight]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('i', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono')),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Geo Busca Imóveis', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(imoveis.length.toString() + ' imóveis listados no catálogo', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDim, size: 20),
            tooltip: 'Atualizar',
            onPressed: loadProperties,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Campo de Pesquisa + Alternador de Visualização
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.9),
                    ),
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Filtrar por endereço, leiloeiro, cidade...',
                        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 18),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: AppColors.textDim),
                                onPressed: () {
                                  searchController.clear();
                                  loadProperties();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => loadProperties(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botões de Visualização (Grade / Tabela / Lista)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.9),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded, size: 16, color: viewMode == 'grid' ? AppColors.brandLight : AppColors.textDim),
                        tooltip: 'Grade',
                        onPressed: () => setState(() => viewMode = 'grid'),
                      ),
                      IconButton(
                        icon: Icon(Icons.table_chart_rounded, size: 16, color: viewMode == 'table' ? AppColors.brandLight : AppColors.textDim),
                        tooltip: 'Tabela',
                        onPressed: () => setState(() => viewMode = 'table'),
                      ),
                      IconButton(
                        icon: Icon(Icons.view_agenda_rounded, size: 16, color: viewMode == 'list' ? AppColors.brandLight : AppColors.textDim),
                        tooltip: 'Lista',
                        onPressed: () => setState(() => viewMode = 'list'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Barra de Filtros Completa do index.html (Scroll Horizontal)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Filtro 1: UF
                InkWell(
                  onTap: openUfPicker,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined, size: 12, color: AppColors.brandLight),
                        const SizedBox(width: 4),
                        Text('UF: ' + uf, style: const TextStyle(color: AppColors.brandLight, fontWeight: FontWeight.bold)),
                        const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.brandLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Filtro 2: Municípios (Multi-Select)
                InkWell(
                  onTap: openMunicipiosModal,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge(
                    variant: cidadesSelecionadas.isNotEmpty ? ShadBadgeVariant.defaultVariant : ShadBadgeVariant.outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_city_outlined, size: 12),
                        const SizedBox(width: 4),
                        Text(cidadesSelecionadas.isEmpty
                            ? 'Cidades (Todas)'
                            : 'Cidades (' + cidadesSelecionadas.length.toString() + ')'),
                        const Icon(Icons.arrow_drop_down, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Filtro 3: Tipo de Imóvel
                InkWell(
                  onTap: openTipoPicker,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge(
                    variant: tipo != 'todos' ? ShadBadgeVariant.defaultVariant : ShadBadgeVariant.outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_outlined, size: 12),
                        const SizedBox(width: 4),
                        Text(tiposMap[tipo] ?? 'Tipo: Todos'),
                        const Icon(Icons.arrow_drop_down, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Filtro 4: Fonte de Dados
                InkWell(
                  onTap: openFontePicker,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge(
                    variant: fonte != 'todas' ? ShadBadgeVariant.defaultVariant : ShadBadgeVariant.outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hub_outlined, size: 12),
                        const SizedBox(width: 4),
                        Text(fonte == 'todas' ? 'Fonte: Todas' : (fontesMap[fonte] ?? fonte).toUpperCase()),
                        const Icon(Icons.arrow_drop_down, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Filtro 5: Data Final (Até)
                InkWell(
                  onTap: openDatePicker,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge(
                    variant: dataFinal != null ? ShadBadgeVariant.warning : ShadBadgeVariant.outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12),
                        const SizedBox(width: 4),
                        Text(dataFinal != null ? 'Até: ' + dataFinal! : 'Data Final'),
                        if (dataFinal != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() => dataFinal = null);
                              loadProperties();
                            },
                            child: const Icon(Icons.close, size: 12),
                          ),
                        ] else
                          const Icon(Icons.arrow_drop_down, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Filtro 6: Ordenação
                InkWell(
                  onTap: openSortPicker,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert, size: 12, color: AppColors.textDim),
                        const SizedBox(width: 4),
                        Text(ordenacoesMap[ordem] ?? 'Ordenar'),
                        const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textDim),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Filtro 7: Apenas Salvos
                InkWell(
                  onTap: () {
                    setState(() => apenasSalvos = !apenasSalvos);
                    loadProperties();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge(
                    variant: apenasSalvos ? ShadBadgeVariant.destructive : ShadBadgeVariant.outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(apenasSalvos ? Icons.favorite : Icons.favorite_border, size: 12, color: apenasSalvos ? Colors.white : AppColors.discountLight),
                        const SizedBox(width: 4),
                        Text('SALVOS (' + favoritosHashes.length.toString() + ')'),
                      ],
                    ),
                  ),
                ),

                // Botão Limpar Tudo
                if (hasActiveFilters) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: clearAllFilters,
                    borderRadius: BorderRadius.circular(6),
                    child: const ShadBadge.destructive(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all, size: 12, color: AppColors.discountLight),
                          SizedBox(width: 4),
                          Text('Limpar'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Chips de Filtros Ativos (com remoção individual com um toque)
          if (hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (searchController.text.isNotEmpty)
                      _activeFilterChip('Busca: "' + searchController.text + '"', () {
                        searchController.clear();
                        loadProperties();
                      }),
                    if (cidadesSelecionadas.isNotEmpty)
                      _activeFilterChip('Cidades: ' + cidadesSelecionadas.join(', '), () {
                        setState(() => cidadesSelecionadas.clear());
                        loadProperties();
                      }),
                    if (tipo != 'todos')
                      _activeFilterChip('Tipo: ' + (tiposMap[tipo] ?? tipo), () {
                        setState(() => tipo = 'todos');
                        loadProperties();
                      }),
                    if (fonte != 'todas')
                      _activeFilterChip('Fonte: ' + (fontesMap[fonte] ?? fonte), () {
                        setState(() => fonte = 'todas');
                        loadProperties();
                      }),
                    if (dataFinal != null)
                      _activeFilterChip('Até: ' + dataFinal!, () {
                        setState(() => dataFinal = null);
                        loadProperties();
                      }),
                    if (apenasSalvos)
                      _activeFilterChip('Apenas Favoritos', () {
                        setState(() => apenasSalvos = false);
                        loadProperties();
                      }),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.border),

          // 4. Exibição dos Imóveis (Grade / Tabela / Lista)
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLight))
                : imoveis.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 56, color: AppColors.textDim.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text('Nenhum imóvel encontrado', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Tente ajustar os filtros ou execute uma rotina para atualizar a base local.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                              if (hasActiveFilters) ...[
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceElevated),
                                  onPressed: clearAllFilters,
                                  icon: const Icon(Icons.clear_all, size: 16, color: AppColors.brandLight),
                                  label: const Text('Limpar Todos os Filtros', style: TextStyle(color: AppColors.brandLight, fontSize: 12)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : viewMode == 'table'
                        ? PropertyTable(
                            imoveis: imoveis,
                            onSelect: openDetail,
                          )
                        : viewMode == 'list'
                            ? PropertyList(
                                imoveis: imoveis,
                                onSelect: openDetail,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: imoveis.length,
                                itemBuilder: (ctx, i) {
                                  final im = imoveis[i];
                                  final fav = favoritosHashes.contains(im.hashImovel);
                                  return PropertyCard(
                                    imovel: im,
                                    isFavorito: fav,
                                    onTap: () => openDetail(im),
                                    onToggleFavorito: () => toggleFavorite(im.hashImovel),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMain, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
