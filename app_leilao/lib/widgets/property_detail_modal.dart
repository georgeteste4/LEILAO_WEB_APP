import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../widgets/alert_config_modal.dart';

class PropertyDetailModal extends StatefulWidget {
  final Imovel imovel;

  const PropertyDetailModal({super.key, required this.imovel});

  @override
  State<PropertyDetailModal> createState() => _PropertyDetailModalState();
}

class _PropertyDetailModalState extends State<PropertyDetailModal> {
  bool isFavorito = false;
  bool hasAlert = false;

  @override
  void initState() {
    super.initState();
    loadStatus();
  }

  Future loadStatus() async {
    final fav = await DBHelper.instance.isFavorito(widget.imovel.hashImovel);
    final alert = await DBHelper.instance.getAlertaByHash(widget.imovel.hashImovel);
    setState(() {
      isFavorito = fav;
      hasAlert = (alert != null && alert.ativo);
    });
  }

  Future toggleFavorite() async {
    final res = await DBHelper.instance.toggleFavorito(widget.imovel.hashImovel);
    setState(() => isFavorito = res);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? 'Adicionado aos Favoritos!' : 'Removido dos Favoritos.')),
      );
    }
  }

  void openAlertConfig() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlertConfigModal(imovel: widget.imovel),
    ).then((_) => loadStatus());
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (widget.imovel.imagem.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(widget.imovel.imagem, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(widget.imovel.titulo, style: const TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.imovel.cidade + ' / ' + widget.imovel.uf + ' • Fonte: ' + widget.imovel.fonteSlug.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 14),

            // Métricas Financeiras
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: _metricBox('AVALIAÇÃO', widget.imovel.valorAvaliacao != null ? fmt.format(widget.imovel.valorAvaliacao) : '-', AppColors.textDim)),
                  Expanded(child: _metricBox('LANCE', widget.imovel.valorLeilao != null ? fmt.format(widget.imovel.valorLeilao) : '-', AppColors.successLight)),
                  Expanded(child: _metricBox('DESCONTO', widget.imovel.desconto != null ? '-' + widget.imovel.desconto!.round().toString() + '%' : '-', AppColors.discountLight)),
                  Expanded(child: _metricBox('ECONOMIA', widget.imovel.economia != null ? fmt.format(widget.imovel.economia) : '-', AppColors.brandLight)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Barra de Ação Rápida: Favoritar & Me Avise
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isFavorito ? AppColors.discountLight : AppColors.borderSubtle),
                      backgroundColor: isFavorito ? AppColors.discount.withOpacity(0.15) : AppColors.surface,
                    ),
                    onPressed: toggleFavorite,
                    icon: Icon(isFavorito ? Icons.favorite : Icons.favorite_border, color: isFavorito ? AppColors.discountLight : AppColors.textMain, size: 18),
                    label: Text(isFavorito ? 'Salvo' : 'Favoritar', style: TextStyle(color: isFavorito ? AppColors.discountLight : AppColors.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAlert ? AppColors.brandDark : AppColors.surfaceElevated,
                      side: BorderSide(color: hasAlert ? AppColors.brandLight : AppColors.borderSubtle),
                    ),
                    onPressed: openAlertConfig,
                    icon: Icon(hasAlert ? Icons.notifications_active : Icons.notifications_none, color: AppColors.brandLight, size: 18),
                    label: Text(hasAlert ? 'Alerta Ativo' : 'Me Avise', style: const TextStyle(color: AppColors.brandLight, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _infoRow('Modalidade', widget.imovel.modalidade),
            if (widget.imovel.nomeLeiloeiro != null && widget.imovel.nomeLeiloeiro!.isNotEmpty)
              _infoRow('Leiloeiro', widget.imovel.nomeLeiloeiro!),
            if (widget.imovel.dataEncerramento != null && widget.imovel.dataEncerramento!.isNotEmpty)
              _infoRow('Encerramento', widget.imovel.dataEncerramento!),
            if (widget.imovel.numeroMatricula != null && widget.imovel.numeroMatricula!.isNotEmpty)
              _infoRow('Nº Matrícula', widget.imovel.numeroMatricula!),

            const SizedBox(height: 16),

            Row(
              children: [
                if (widget.imovel.edital != null && widget.imovel.edital!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                      onPressed: () => launchUrl(Uri.parse(widget.imovel.edital!)),
                      child: const Text('Edital Oficial (PDF)', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                    ),
                  ),
                if (widget.imovel.edital != null && widget.imovel.edital!.isNotEmpty && widget.imovel.linkMatricula != null && widget.imovel.linkMatricula!.isNotEmpty)
                  const SizedBox(width: 8),
                if (widget.imovel.linkMatricula != null && widget.imovel.linkMatricula!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                      onPressed: () => launchUrl(Uri.parse(widget.imovel.linkMatricula!)),
                      child: const Text('Matrícula (PDF)', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                onPressed: () => launchUrl(Uri.parse(widget.imovel.linkOriginal)),
                child: const Text('Acessar Anúncio Original', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: valColor, fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(val, style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
