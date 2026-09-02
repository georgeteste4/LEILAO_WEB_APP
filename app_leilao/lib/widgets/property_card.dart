import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/imovel.dart';

class PropertyCard extends StatelessWidget {
  final Imovel imovel;
  final VoidCallback onTap;

  const PropertyCard({super.key, required this.imovel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com Badge de Desconto em Destaque
            Stack(
              children: [
                if (imovel.imagem.isNotEmpty)
                  Image.network(
                    imovel.imagem,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 150,
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: Icon(Icons.home_work_outlined, color: AppColors.textDim, size: 40),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: Icon(Icons.home_work_outlined, color: AppColors.textDim, size: 40),
                    ),
                  ),

                // Badge Desconto Superior Direito
                if (imovel.desconto != null && imovel.desconto! > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.discount,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        '-\${imovel.desconto!.round()}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                // Badge Fonte Superior Esquerdo
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.canvas.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      imovel.fonteSlug.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.brandLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imovel.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          imovel.cidade.isNotEmpty ? '\${imovel.cidade} / \${imovel.uf}' : imovel.uf,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),

                  // Preços
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Avaliação', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                          Text(
                            imovel.valorAvaliacao != null ? fmt.format(imovel.valorAvaliacao) : '-',
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Lance Inicial', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                          Text(
                            imovel.valorLeilao != null ? fmt.format(imovel.valorLeilao) : '-',
                            style: const TextStyle(
                              color: AppColors.successLight,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
