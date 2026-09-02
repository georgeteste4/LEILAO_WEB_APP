import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/imovel.dart';

class PropertyDetailModal extends StatelessWidget {
  final Imovel imovel;

  const PropertyDetailModal({super.key, required this.imovel});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
    final economia = (imovel.valorAvaliacao != null && imovel.valorLeilao != null)
        ? (imovel.valorAvaliacao! - imovel.valorLeilao!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF090D16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (imovel.imagem.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imovel.imagem, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(imovel.titulo, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('\${imovel.cidade} / \${imovel.uf}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),

            // Métricas Financeiras
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    const Text('AVALIAÇÃO', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(imovel.valorAvaliacao != null ? fmt.format(imovel.valorAvaliacao) : '-', style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12)),
                  ]),
                  Column(children: [
                    const Text('LANCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(imovel.valorLeilao != null ? fmt.format(imovel.valorLeilao) : '-', style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                  Column(children: [
                    const Text('DESCONTO', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(imovel.desconto != null ? '-\${imovel.desconto!.round()}%' : '-', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),

            if (economia != null && economia > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Economia estimada: \${fmt.format(economia)}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 16),

            // Botões de Ação
            Row(
              children: [
                if (imovel.edital != null && imovel.edital!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => launchUrl(Uri.parse(imovel.edital!)),
                      child: const Text('Edital PDF'),
                    ),
                  ),
                const SizedBox(width: 8),
                if (imovel.linkMatricula != null && imovel.linkMatricula!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => launchUrl(Uri.parse(imovel.linkMatricula!)),
                      child: const Text('Matrícula PDF'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                onPressed: () => launchUrl(Uri.parse(imovel.linkOriginal)),
                child: const Text('Ver Anúncio Original', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
