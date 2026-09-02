import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../widgets/property_card.dart';
import '../widgets/property_detail_modal.dart';
import '../widgets/shad_components.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Imovel> favoritos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future loadFavorites() async {
    setState(() => loading = true);
    final list = await DBHelper.instance.getImoveisFavoritos();
    setState(() {
      favoritos = list;
      loading = false;
    });
  }

  Future removeFavorite(String hash) async {
    await DBHelper.instance.toggleFavorito(hash);
    await loadFavorites();
  }

  void openDetail(Imovel imovel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PropertyDetailModal(imovel: imovel),
    ).then((_) => loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);
    double economiaTotal = 0;
    for (var im in favoritos) {
      if (im.economia != null) economiaTotal += im.economia!;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.discountLight, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Imóveis Salvos', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(favoritos.length.toString() + ' oportunidades favoritadas', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDim, size: 20),
            onPressed: loadFavorites,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLight))
          : favoritos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 56, color: AppColors.textDim.withOpacity(0.35)),
                        const SizedBox(height: 14),
                        const Text('Nenhum imóvel salvo ainda', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Toque no ícone de coração nos cards do Catálogo para guardar imóveis e programar avisos automáticos.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoritos.length + (economiaTotal > 0 ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (economiaTotal > 0 && i == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ShadCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ECONOMIA POTENCIAL TOTAL', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(fmt.format(economiaTotal), style: const TextStyle(color: AppColors.brandLight, fontFamily: 'JetBrains Mono', fontSize: 16, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const ShadBadge.success(
                                child: Text('OPORTUNIDADES'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final idx = economiaTotal > 0 ? i - 1 : i;
                    final im = favoritos[idx];
                    return PropertyCard(
                      imovel: im,
                      isFavorito: true,
                      onTap: () => openDetail(im),
                      onToggleFavorito: () => removeFavorite(im.hashImovel),
                    );
                  },
                ),
    );
  }
}
