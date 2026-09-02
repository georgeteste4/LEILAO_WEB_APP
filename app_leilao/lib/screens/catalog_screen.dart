import 'package:flutter/material.dart';
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
  bool loading = true;
  String viewMode = 'grid'; // grid, table, list
  String uf = 'MA';
  String? tipo;
  String fonte = 'todas';
  String ordem = 'desconto_desc';
  final searchController = TextEditingController();

  final List<String> estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  void initState() {
    super.initState();
    loadProperties();
  }

  Future loadProperties() async {
    setState(() => loading = true);
    final list = await DBHelper.instance.getImoveis(
      uf: uf,
      tipo: tipo,
      fonte: fonte,
      busca: searchController.text,
      ordem: ordem,
    );
    setState(() {
      imoveis = list;
      loading = false;
    });
  }

  void openDetail(Imovel imovel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PropertyDetailModal(imovel: imovel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D16),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: const Text('L', style: TextStyle(color: Color(0xFF090D16), fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Leilão de Imóveis', style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.bold)),
                Text('\${imoveis.length} encontrados', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
            onPressed: loadProperties,
          )
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por cidade, endereço...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    ),
                    onSubmitted: (_) => loadProperties(),
                  ),
                ),
                const SizedBox(width: 8),
                // Botões de Visualização
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.grid_view, size: 18, color: viewMode == 'grid' ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
                        onPressed: () => setState(() => viewMode = 'grid'),
                      ),
                      IconButton(
                        icon: Icon(Icons.table_chart, size: 18, color: viewMode == 'table' ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
                        onPressed: () => setState(() => viewMode = 'table'),
                      ),
                      IconButton(
                        icon: Icon(Icons.view_list, size: 18, color: viewMode == 'list' ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
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
                // Seletor UF
                ActionChip(
                  label: Text('UF: \$uf', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11)),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF1E293B)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => ListView(
                        children: estados.map((e) => ListTile(
                          title: Text(e),
                          onTap: () {
                            setState(() => uf = e);
                            Navigator.pop(ctx);
                            loadProperties();
                          },
                        )).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                // Ordenação
                ActionChip(
                  label: const Text('Maior Desconto', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF1E293B)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Lista de Resultados
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : imoveis.isEmpty
                    ? const Center(child: Text('Nenhum imóvel encontrado', style: TextStyle(color: Color(0xFF64748B))))
                    : RefreshIndicator(
                        onRefresh: loadProperties,
                        color: const Color(0xFF38BDF8),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (viewMode == 'grid')
                              ...imoveis.map((im) => PropertyCard(imovel: im, onTap: () => openDetail(im)))
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
