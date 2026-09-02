import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/imovel.dart';

class PropertyList extends StatelessWidget {
  final List<Imovel> imoveis;
  final Function(Imovel) onSelect;

  const PropertyList({super.key, required this.imoveis, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R$', decimalDigits: 0);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: imoveis.length,
      itemBuilder: (ctx, i) {
        final im = imoveis[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () => onSelect(im),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              im.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Text(im.fonteSlug.toUpperCase(), style: const TextStyle(color: AppColors.brandLight, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${im.cidade}/${im.uf}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  im.valorLeilao != null ? fmt.format(im.valorLeilao) : '-',
                  style: const TextStyle(color: AppColors.successLight, fontFamily: 'JetBrains Mono', fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (im.desconto != null && im.desconto! > 0)
                  Text(
                    '-${im.desconto!.round()}%',
                    style: const TextStyle(color: AppColors.discountLight, fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
