import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/imovel.dart';

class PropertyList extends StatelessWidget {
  final List<Imovel> imoveis;
  final Function(Imovel) onSelect;

  const PropertyList({super.key, required this.imoveis, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: imoveis.length,
      itemBuilder: (ctx, i) {
        final im = imoveis[i];
        return InkWell(
          onTap: () => onSelect(im),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(im.fonteSlug.toUpperCase(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                    if (im.desconto != null && im.desconto! > 0)
                      Text('-\${im.desconto!.round()}% OFF', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(im.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\${im.cidade}/\${im.uf}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    Text(im.valorLeilao != null ? fmt.format(im.valorLeilao) : '-', style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
