import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/imovel.dart';
import 'shad_components.dart';

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.9),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com Sobreposição Gradiente e Badges
            Stack(
              children: [
                if (imovel.imagem.isNotEmpty)
                  Image.network(
                    imovel.imagem,
                    height: 165,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 165,
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: Icon(Icons.home_work_outlined, color: AppColors.textDim, size: 44),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 165,
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: Icon(Icons.home_work_outlined, color: AppColors.textDim, size: 44),
                    ),
                  ),

                // Gradiente escuro sutil na base da foto
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Badge Desconto Superior Esquerdo
                if (imovel.desconto != null && imovel.desconto! > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ShadBadge.destructive(
                      child: Text(
                        '-' + imovel.desconto!.round().toString() + '% OFF',
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),

                // Botão de Favoritar Superior Direito
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onToggleFavorito,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          isFavorito ? Icons.favorite : Icons.favorite_border,
                          color: isFavorito ? AppColors.discountLight : Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge Fonte e Cidade na base da imagem
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShadBadge.secondary(
                        child: Text(imovel.fonteSlug.toUpperCase()),
                      ),
                      if (imovel.cidade.isNotEmpty)
                        Text(
                          imovel.cidade + '/' + imovel.uf,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(14),
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

                  if (imovel.endereco.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, color: AppColors.textDim, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            imovel.endereco,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),

                  // Banner de Datas: Encerramento e Inclusão
                  if (hasEncerramento || hasInclusao) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasEncerramento ? AppColors.warningBg : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasEncerramento ? AppColors.warning.withOpacity(0.3) : AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasEncerramento ? Icons.alarm_on : Icons.calendar_today_outlined,
                            color: hasEncerramento ? AppColors.warningLight : AppColors.textDim,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasEncerramento ? 'Encerramento: ' + imovel.dataEncerramento! : 'Inclusão: ' + imovel.dataInclusao!,
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
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // Resumo Financeiro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Avaliação', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                          const SizedBox(height: 1),
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
                          const Text('Lance Mínimo', style: TextStyle(color: AppColors.textDim, fontSize: 10)),
                          const SizedBox(height: 1),
                          Text(
                            imovel.valorLeilao != null ? fmt.format(imovel.valorLeilao) : 'Consulte',
                            style: const TextStyle(
                              color: AppColors.successLight,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
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
