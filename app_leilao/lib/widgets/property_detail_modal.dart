import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<String> extractFeatures(Imovel im) {
    final List<String> feats = [];
    final text = (im.titulo + ' ' + im.linkOriginal + ' ' + im.endereco).toLowerCase();

    if (text.contains('1 quarto') || text.contains('1 dorm')) feats.add('1 Quarto');
    if (text.contains('2 quarto') || text.contains('2 dorm')) feats.add('2 Quartos');
    if (text.contains('3 quarto') || text.contains('3 dorm')) feats.add('3 Quartos');
    if (text.contains('4 quarto') || text.contains('4 dorm')) feats.add('4 Quartos');
    if (text.contains('suite') || text.contains('suíte')) feats.add('Suíte');
    if (text.contains('garagem') || text.contains('vaga')) feats.add('Vaga de Garagem');
    if (text.contains('area de servico') || text.contains('área de serviço')) feats.add('Área de Serviço');
    if (text.contains('sala')) feats.add('Sala de Estar');
    if (text.contains('cozinha')) feats.add('Cozinha');
    if (text.contains('terraco') || text.contains('terraço') || text.contains('varanda')) feats.add('Varanda / Terraço');
    if (text.contains('quintal')) feats.add('Quintal');
    if (text.contains('piscina')) feats.add('Piscina');

    return feats;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);
    final features = extractFeatures(widget.imovel);

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
            // Handle de arrastar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Foto de Capa com Tags
            Stack(
              children: [
                if (widget.imovel.imagem.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.imovel.imagem,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 190,
                        color: AppColors.surfaceElevated,
                        child: const Center(child: Icon(Icons.home_work_outlined, size: 48, color: AppColors.textDim)),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 190,
                    decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Icon(Icons.home_work_outlined, size: 48, color: AppColors.textDim)),
                  ),

                if (widget.imovel.desconto != null && widget.imovel.desconto! > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.discount,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        '-' + widget.imovel.desconto!.round().toString() + '% OFF',
                        style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.canvas.withOpacity(0.9), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border)),
                    child: Text(
                      widget.imovel.tipo.toUpperCase() + ' • FONTE: ' + widget.imovel.fonteSlug.toUpperCase(),
                      style: const TextStyle(color: AppColors.brandLight, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Título Principal
            Text(widget.imovel.titulo, style: const TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 6),

            // BANNER DESTACADO: DATA DE ENCERRAMENTO DO LEILÃO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (widget.imovel.dataEncerramento != null && widget.imovel.dataEncerramento!.isNotEmpty)
                    ? AppColors.warning.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (widget.imovel.dataEncerramento != null && widget.imovel.dataEncerramento!.isNotEmpty)
                      ? AppColors.warningLight.withOpacity(0.4)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm,
                    color: (widget.imovel.dataEncerramento != null && widget.imovel.dataEncerramento!.isNotEmpty)
                        ? AppColors.warningLight
                        : AppColors.textDim,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DATA E HORA DE ENCERRAMENTO', style: TextStyle(color: AppColors.textDim, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          (widget.imovel.dataEncerramento != null && widget.imovel.dataEncerramento!.isNotEmpty)
                              ? widget.imovel.dataEncerramento!
                              : 'Consulte o cronograma no edital oficial',
                          style: TextStyle(
                            color: (widget.imovel.dataEncerramento != null && widget.imovel.dataEncerramento!.isNotEmpty)
                                ? AppColors.warningLight
                                : AppColors.textMuted,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Resumo Financeiro em 4 Colunas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(child: _metricBox('AVALIAÇÃO', widget.imovel.valorAvaliacao != null ? fmt.format(widget.imovel.valorAvaliacao) : '-', AppColors.textDim)),
                  Expanded(child: _metricBox('LANCE INICIAL', widget.imovel.valorLeilao != null ? fmt.format(widget.imovel.valorLeilao) : '-', AppColors.successLight)),
                  Expanded(child: _metricBox('DESCONTO', widget.imovel.desconto != null ? '-' + widget.imovel.desconto!.round().toString() + '%' : '-', AppColors.discountLight)),
                  Expanded(child: _metricBox('ECONOMIA', widget.imovel.economia != null ? fmt.format(widget.imovel.economia) : '-', AppColors.brandLight)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Ações Rápidas: Favoritar & Me Avise
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

            const SizedBox(height: 16),

            // SEÇÃO: DESCRIÇÃO COMPLETA DO IMÓVEL & LOCALIZAÇÃO
            const Text('DESCRIÇÃO E LOCALIZAÇÃO DO IMÓVEL', style: TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: AppColors.brandLight, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SelectableText(
                          widget.imovel.endereco.isNotEmpty ? widget.imovel.endereco : 'Endereço registrado na matrícula oficial.',
                          style: const TextStyle(color: AppColors.textMain, fontSize: 12, height: 1.4),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 14, color: AppColors.textDim),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.imovel.endereco));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço copiado para a área de transferência!')));
                        },
                      ),
                    ],
                  ),

                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 8),
                    const Text('Composição e Cômodos Identificados:', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.borderSubtle)),
                        child: Text(f, style: const TextStyle(color: AppColors.textMain, fontSize: 10, fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SEÇÃO: FICHA JURÍDICA E NOTARIAL
            const Text('FICHA TÉCNICA E JURÍDICA', style: TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  _infoRow('Modalidade', widget.imovel.modalidade),
                  _infoRow('Leiloeiro / Agente', (widget.imovel.nomeLeiloeiro != null && widget.imovel.nomeLeiloeiro!.isNotEmpty) ? widget.imovel.nomeLeiloeiro! : 'Caixa / Leiloeiro Oficial'),
                  _infoRow('Nº da Matrícula', (widget.imovel.numeroMatricula != null && widget.imovel.numeroMatricula!.isNotEmpty) ? widget.imovel.numeroMatricula! : 'Disponível na Certidão de Matrícula'),
                  _infoRow('Data de Inclusão', (widget.imovel.dataInclusao != null && widget.imovel.dataInclusao!.isNotEmpty) ? widget.imovel.dataInclusao! : 'Recente'),
                  _infoRow('Identificador (Hash)', widget.imovel.hashImovel.length > 12 ? widget.imovel.hashImovel.substring(0, 12) + '...' : widget.imovel.hashImovel),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DOCUMENTAÇÃO E EDITAIS
            Row(
              children: [
                if (widget.imovel.edital != null && widget.imovel.edital!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandLight)),
                      onPressed: () => launchUrl(Uri.parse(widget.imovel.edital!)),
                      icon: const Icon(Icons.picture_as_pdf, color: AppColors.brandLight, size: 16),
                      label: const Text('Edital Oficial (PDF)', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                    ),
                  ),
                if (widget.imovel.edital != null && widget.imovel.edital!.isNotEmpty && widget.imovel.linkMatricula != null && widget.imovel.linkMatricula!.isNotEmpty)
                  const SizedBox(width: 8),
                if (widget.imovel.linkMatricula != null && widget.imovel.linkMatricula!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandLight)),
                      onPressed: () => launchUrl(Uri.parse(widget.imovel.linkMatricula!)),
                      icon: const Icon(Icons.description, color: AppColors.brandLight, size: 16),
                      label: const Text('Matrícula (PDF)', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                onPressed: () => launchUrl(Uri.parse(widget.imovel.linkOriginal)),
                icon: const Icon(Icons.open_in_new, color: Colors.white, size: 16),
                label: const Text('Acessar Anúncio Oficial no Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
