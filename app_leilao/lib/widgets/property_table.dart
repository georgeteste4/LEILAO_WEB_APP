import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF1E293B)),
          columns: const [
            DataColumn(label: Text('IMÓVEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('FONTE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CIDADE/UF', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('LANCE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('DESC %', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
          ],
          rows: imoveis.map((im) {
            return DataRow(
              onSelectChanged: (_) => onSelect(im),
              cells: [
                DataCell(SizedBox(
                  width: 150,
                  child: Text(im.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12, fontWeight: FontWeight.w600)),
                )),
                DataCell(Text(im.fonteSlug.toUpperCase(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11))),
                DataCell(Text('\${im.cidade}/\${im.uf}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                DataCell(Text(im.valorLeilao != null ? fmt.format(im.valorLeilao) : '-', style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold))),
                DataCell(Text(im.desconto != null ? '-\${im.desconto!.round()}%' : '-', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
