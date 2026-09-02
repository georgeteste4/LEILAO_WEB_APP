import 'package:flutter/material.dart';
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
  String ordem = 'desconto_desc';
  final searchController = TextEditingController();

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

  void openUfPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
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
          _sortItem('Maior Desconto %', 'desconto_desc', ctx),
          _sortItem('Menor Preço de Leilão', 'valor_asc', ctx),
          _sortItem('Maior Preço de Leilão', 'valor_desc', ctx),
          _sortItem('Maior Avaliação', 'avaliacao_desc', ctx),
          _sortItem('Mais Recentes', 'recentes', ctx),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sortItem(String label, String val, BuildContext ctx) {
    return ListTile(
      title: Text(label, style: TextStyle(color: ordem == val ? AppColors.brandLight : AppColors.textMain, fontWeight: ordem == val ? FontWeight.bold : FontWeight.normal)),
      trailing: ordem == val ? const Icon(Icons.check, color: AppColors.brandLight, size: 18) : null,
      onTap: () {
        setState(() => ordem = val);
        Navigator.pop(ctx);
        loadProperties();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Text(imoveis.length.toString() + ' oportunidades no SQLite', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDim, size: 20),
            tooltip: 'Recarregar',
            onPressed: loadProperties,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Campo de Busca Shadcn com Botão de Limpar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        hintText: 'Buscar por rua, leiloeiro, cidade...',
                        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => loadProperties(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Seletor de Modo de Exibição
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.9),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded, size: 17, color: viewMode == 'grid' ? AppColors.brandLight : AppColors.textDim),
                        onPressed: () => setState(() => viewMode = 'grid'),
                      ),
                      IconButton(
                        icon: Icon(Icons.table_chart_rounded, size: 17, color: viewMode == 'table' ? AppColors.brandLight : AppColors.textDim),
                        onPressed: () => setState(() => viewMode = 'table'),
                      ),
                      IconButton(
                        icon: Icon(Icons.view_agenda_rounded, size: 17, color: viewMode == 'list' ? AppColors.brandLight : AppColors.textDim),
                        onPressed: () => setState(() => viewMode = 'list'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pílulas de Filtro Rápidas (Shadcn Badges Interativas)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() => apenasSalvos = !apenasSalvos);
                    loadProperties();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge(
                    variant: apenasSalvos ? ShadBadgeVariant.destructive : ShadBadgeVariant.secondary,
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
                const SizedBox(width: 6),
                InkWell(
                  onTap: openUfPicker,
                  borderRadius: BorderRadius.circular(6),
                  child: ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined, size: 12, color: AppColors.textDim),
                        const SizedBox(width: 4),
                        Text('UF: ' + uf),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: openSortPicker,
                  borderRadius: BorderRadius.circular(6),
                  child: const ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_vert, size: 12, color: AppColors.textDim),
                        SizedBox(width: 4),
                        Text('ORDENAR'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Lista Principal
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
                              const Text('Tente ajustar os filtros ou execute uma rotina na aba Rotinas para atualizar a base.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : viewMode == 'table'
                        ? PropertyTable(
                            imoveis: imoveis,
                            favoritosHashes: favoritosHashes,
                            onToggleFavorito: toggleFavorite,
                            onTap: openDetail,
                          )
                        : viewMode == 'list'
                            ? PropertyList(
                                imoveis: imoveis,
                                favoritosHashes: favoritosHashes,
                                onToggleFavorito: toggleFavorite,
                                onTap: openDetail,
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
}
