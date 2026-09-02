import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../models/imovel.dart';

class PropertyDetailModal extends StatelessWidget {
  final Imovel imovel;

  const PropertyDetailModal({super.key, required this.imovel});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R$', decimalDigits: 0);

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
            if (imovel.imagem.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imovel.imagem, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(imovel.titulo, style: const TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${imovel.cidade} / ${imovel.uf} • Fonte: ${imovel.fonteSlug.toUpperCase()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 14),

            // Painel de 4 Métricas Financeiras (Leilão Design System)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: _metricBox('AVALIAÇÃO', imovel.valorAvaliacao != null ? fmt.format(imovel.valorAvaliacao) : '-', AppColors.textDim)),
                  Expanded(child: _metricBox('LANCE', imovel.valorLeilao != null ? fmt.format(imovel.valorLeilao) : '-', AppColors.successLight)),
                  Expanded(child: _metricBox('DESCONTO', imovel.desconto != null ? '-${imovel.desconto!.round()}%' : '-', AppColors.discountLight)),
                  Expanded(child: _metricBox('ECONOMIA', imovel.economia != null ? fmt.format(imovel.economia) : '-', AppColors.brandLight)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Informações Estruturadas
            _infoRow('Modalidade', imovel.modalidade),
            if (imovel.nomeLeiloeiro != null && imovel.nomeLeiloeiro!.isNotEmpty)
              _infoRow('Leiloeiro', imovel.nomeLeiloeiro!),
            if (imovel.dataEncerramento != null && imovel.dataEncerramento!.isNotEmpty)
              _infoRow('Encerramento', imovel.dataEncerramento!),
            if (imovel.numeroMatricula != null && imovel.numeroMatricula!.isNotEmpty)
              _infoRow('Nº Matrícula', imovel.numeroMatricula!),

            const SizedBox(height: 16),

            // Botões de Ação
            Row(
              children: [
                if (imovel.edital != null && imovel.edital!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                      onPressed: () => launchUrl(Uri.parse(imovel.edital!)),
                      child: const Text('Edital Oficial (PDF)', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                    ),
                  ),
                if (imovel.edital != null && imovel.edital!.isNotEmpty && imovel.linkMatricula != null && imovel.linkMatricula!.isNotEmpty)
                  const SizedBox(width: 8),
                if (imovel.linkMatricula != null && imovel.linkMatricula!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                      onPressed: () => launchUrl(Uri.parse(imovel.linkMatricula!)),
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
                onPressed: () => launchUrl(Uri.parse(imovel.linkOriginal)),
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
