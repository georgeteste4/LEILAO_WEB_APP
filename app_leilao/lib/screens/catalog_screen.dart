import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/states.dart';
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../widgets/property_card.dart';
import '../widgets/property_table.dart';
import '../widgets/property_list.dart';
import '../widgets/property_detail_modal.dart';

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
      builder: (ctx) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: kEstadosBrasil.map((e) => ListTile(
          title: Text(e.sigla + ' — ' + e.nome, style: TextStyle(color: uf == e.sigla ? AppColors.brandLight : AppColors.textMain, fontWeight: uf == e.sigla ? FontWeight.bold : FontWeight.normal)),
          trailing: uf == e.sigla ? const Icon(Icons.check, color: AppColors.brandLight) : null,
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
    );
  }

  void openSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Ordenar Por', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold))),
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
      trailing: ordem == val ? const Icon(Icons.check, color: AppColors.brandLight) : null,
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
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text('L', style: TextStyle(color: AppColors.canvas, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Leilão de Imóveis', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(imoveis.length.toString() + ' no SQLite local', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.brandLight),
            onPressed: loadProperties,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa & Visualização
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por endereço, leiloeiro, cidade...',
                      hintStyle: const TextStyle(color: AppColors.textDim),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                    onSubmitted: (_) => loadProperties(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.grid_view, size: 16, color: viewMode == 'grid' ? AppColors.brandLight : AppColors.textDim),
                        onPressed: () => setState(() => viewMode = 'grid'),
                      ),
                      IconButton(
                        icon: Icon(Icons.table_chart, size: 16, color: viewMode == 'table' ? AppColors.brandLight : AppColors.textDim),
                        onPressed: () => setState(() => viewMode = 'table'),
                      ),
                      IconButton(
                        icon: Icon(Icons.view_list, size: 16, color: viewMode == 'list' ? AppColors.brandLight : AppColors.textDim),
                        onPressed: () => setState(() => viewMode = 'list'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chips de Filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(apenasSalvos ? Icons.favorite : Icons.favorite_border, size: 14, color: apenasSalvos ? Colors.white : AppColors.discountLight),
                      const SizedBox(width: 4),
                      Text('SALVOS (' + favoritosHashes.length.toString() + ')', style: TextStyle(color: apenasSalvos ? Colors.white : AppColors.textMain, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  selected: apenasSalvos,
                  selectedColor: AppColors.discount,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  onSelected: (sel) {
                    setState(() => apenasSalvos = sel);
                    loadProperties();
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: Text('UF: ' + uf, style: const TextStyle(color: AppColors.brandLight, fontWeight: FontWeight.bold, fontSize: 11)),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: openUfPicker,
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('Ordenar', style: TextStyle(color: AppColors.textMain, fontSize: 11)),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: openSortPicker,
                ),
                const SizedBox(width: 6),
                ...['todos', 'apartamento', 'casa', 'terreno', 'rural', 'comercial'].map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(t.toUpperCase(), style: TextStyle(color: tipo == t ? Colors.white : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    selected: tipo == t,
                    selectedColor: AppColors.brand,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onSelected: (sel) {
                      setState(() => tipo = t);
                      loadProperties();
                    },
                  ),
                )),
              ],
            ),
          ),

          // Lista de Resultados
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandLight))
                : imoveis.isEmpty
                    ? const Center(child: Text('Nenhum imóvel encontrado', style: TextStyle(color: AppColors.textDim)))
                    : RefreshIndicator(
                        onRefresh: loadProperties,
                        color: AppColors.brandLight,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (viewMode == 'grid')
                              ...imoveis.map((im) => PropertyCard(
                                imovel: im,
                                isFavorito: favoritosHashes.contains(im.hashImovel),
                                onTap: () => openDetail(im),
                                onToggleFavorito: () => toggleFavorite(im.hashImovel),
                              ))
                            else if (viewMode == 'table')
                              PropertyTable(imoveis: imoveis, onSelect: openDetail)
                            else
                              PropertyList(imoveis: imoveis, onSelect: openDetail),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
