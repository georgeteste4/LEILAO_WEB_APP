import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/imovel.dart';

class PropertyCard extends StatelessWidget {
  final Imovel imovel;
  final bool isFavorito;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorito;

  const PropertyCard({
    super.key,
    required this.imovel,
    this.isFavorito = false,
    required this.onTap,
    required this.onToggleFavorito,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);
    final hasEncerramento = imovel.dataEncerramento != null && imovel.dataEncerramento!.trim().isNotEmpty;
    final hasInclusao = imovel.dataInclusao != null && imovel.dataInclusao!.trim().isNotEmpty;

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
                    right: 48,
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
                        '-' + imovel.desconto!.round().toString() + '% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                // Botão de Favoritar Superior Direito
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: onToggleFavorito,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.canvas.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        isFavorito ? Icons.favorite : Icons.favorite_border,
                        color: isFavorito ? AppColors.discountLight : Colors.white70,
                        size: 18,
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
                          imovel.cidade.isNotEmpty ? imovel.cidade + ' / ' + imovel.uf : imovel.uf,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),

                  // INFORMAÇÕES DE DATAS: ENCERRAMENTO E INCLUSÃO
                  if (hasEncerramento || hasInclusao) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: hasEncerramento ? AppColors.warning.withOpacity(0.12) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: hasEncerramento ? AppColors.warningLight.withOpacity(0.35) : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasEncerramento ? Icons.alarm : Icons.calendar_today_outlined,
                            color: hasEncerramento ? AppColors.warningLight : AppColors.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              hasEncerramento
                                  ? 'Encerramento: ' + imovel.dataEncerramento!
                                  : 'Inclusão: ' + imovel.dataInclusao!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasEncerramento ? AppColors.warningLight : AppColors.textMuted,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: hasEncerramento ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasEncerramento && hasInclusao)
                            Text(
                              'Inc: ' + imovel.dataInclusao!,
                              style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),

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
