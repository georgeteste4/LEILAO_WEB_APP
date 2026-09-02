import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/imovel.dart';

class PropertyTable extends StatelessWidget {
  final List<Imovel> imoveis;
  final Function(Imovel) onSelect;

  const PropertyTable({super.key, required this.imoveis, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.surfaceElevated),
          headingTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('IMÓVEL')),
            DataColumn(label: Text('FONTE')),
            DataColumn(label: Text('CIDADE/UF')),
            DataColumn(label: Text('AVALIAÇÃO', textAlign: TextAlign.right)),
            DataColumn(label: Text('LANCE INICIAL', textAlign: TextAlign.right)),
            DataColumn(label: Text('DESC %')),
          ],
          rows: imoveis.map((im) {
            return DataRow(
              onSelectChanged: (_) => onSelect(im),
              cells: [
                DataCell(SizedBox(
                  width: 160,
                  child: Text(
                    im.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )),
                DataCell(Text(im.fonteSlug.toUpperCase(), style: const TextStyle(color: AppColors.brandLight, fontSize: 11))),
                DataCell(Text('\${im.cidade}/\${im.uf}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                DataCell(Text(
                  im.valorAvaliacao != null ? fmt.format(im.valorAvaliacao) : '-',
                  style: const TextStyle(color: AppColors.textDim, fontFamily: 'JetBrains Mono', fontSize: 12, decoration: TextDecoration.lineThrough),
                )),
                DataCell(Text(
                  im.valorLeilao != null ? fmt.format(im.valorLeilao) : '-',
                  style: const TextStyle(color: AppColors.successLight, fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.bold),
                )),
                DataCell(Text(
                  im.desconto != null ? '-\${im.desconto!.round()}%' : '-',
                  style: const TextStyle(color: AppColors.discountLight, fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
