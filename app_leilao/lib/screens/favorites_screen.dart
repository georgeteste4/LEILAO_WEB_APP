import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../widgets/property_card.dart';
import '../widgets/property_detail_modal.dart';

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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.discountLight, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Imóveis Salvos', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(favoritos.length.toString() + ' favoritos gravados no SQLite', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.brandLight),
            onPressed: loadFavorites,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandLight))
          : favoritos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: AppColors.textDim.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Nenhum imóvel salvo ainda', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Toque no ícone de coração nos cards do Catálogo para guardar oportunidades e definir alertas "Me Avise".', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoritos.length,
                  itemBuilder: (ctx, i) {
                    final im = favoritos[i];
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
