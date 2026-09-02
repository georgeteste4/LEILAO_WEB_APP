import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/fonte_dados.dart';

class FonteFormModal extends StatefulWidget {
  final FonteDados? fonte;

  const FonteFormModal({super.key, this.fonte});

  @override
  State<FonteFormModal> createState() => _FonteFormModalState();
}

class _FonteFormModalState extends State<FonteFormModal> {
  final nomeController = TextEditingController();
  final slugController = TextEditingController();
  final urlController = TextEditingController();
  final descController = TextEditingController();
  String selectedDriver = 'GenericSource';
  bool ativo = true;

  static const List<Map<String, String>> driversDisponiveis = [
    {'class': 'CaixaSource', 'label': 'CaixaSource (Caixa Econômica - CSV Oficial)'},
    {'class': 'LeilaoImovelSource', 'label': 'LeilaoImovelSource (Portal Leilão Imóvel)'},
    {'class': 'BancoDoBrasilSource', 'label': 'BancoDoBrasilSource (Seu Imóvel BB)'},
    {'class': 'ZukermanSource', 'label': 'ZukermanSource (Portal Zuk)'},
    {'class': 'SantanderSource', 'label': 'SantanderSource (Banco Santander)'},
    {'class': 'BradescoSource', 'label': 'BradescoSource (Banco Bradesco)'},
    {'class': 'BankSource', 'label': 'BankSource (Itaú, Inter, Sicredi)'},
    {'class': 'SmartLeiloesCaixaSource', 'label': 'SmartLeiloesCaixaSource (Smart Leilões API)'},
    {'class': 'GenericSource', 'label': 'GenericSource (Driver Genérico de Fallback)'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fonte != null) {
      nomeController.text = widget.fonte!.nome;
      slugController.text = widget.fonte!.slug;
      urlController.text = widget.fonte!.urlBase;
      descController.text = widget.fonte!.descricao ?? '';
      selectedDriver = widget.fonte!.driver;
      ativo = widget.fonte!.ativo;
    }
  }

  Future saveFonte() async {
    final nome = nomeController.text.trim();
    final slug = slugController.text.trim().toLowerCase().replaceAll(' ', '-');

    if (nome.isEmpty || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome e o slug da fonte!')));
      return;
    }

    final f = FonteDados(
      id: widget.fonte?.id,
      nome: nome,
      slug: slug,
      driver: selectedDriver,
      urlBase: urlController.text.trim(),
      descricao: descController.text.trim(),
      ativo: ativo,
      totalColetados: widget.fonte?.totalColetados ?? 0,
      ultimaColeta: widget.fonte?.ultimaColeta,
    );

    await DBHelper.instance.saveFonte(f);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.fonte != null ? 'Fonte atualizada com sucesso!' : 'Fonte conectada com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fonte != null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Fonte de Dados' : 'Conectar Nova Fonte de Dados',
                  style: const TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textDim), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 14),

            _label('NOME DO PORTAL / FONTE *'),
            _input(nomeController, 'Ex: Mega Leilões, Sodré Santoro...'),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('SLUG IDENTIFICADOR *'),
                      _input(slugController, 'megaleiloes'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('DRIVER DE EXTRAÇÃO *'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: driversDisponiveis.any((d) => d['class'] == selectedDriver) ? selectedDriver : 'GenericSource',
                            dropdownColor: AppColors.surface,
                            isExpanded: true,
                            style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                            items: driversDisponiveis.map((d) => DropdownMenuItem(
                              value: d['class'],
                              child: Text(d['class']!, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedDriver = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            _label('URL BASE DO PORTAL'),
            _input(urlController, 'https://www.portal.com.br'),

            const SizedBox(height: 10),
            _label('DESCRIÇÃO / OBSERVAÇÕES'),
            _input(descController, 'Foco em leilões judiciais e extrajudiciais...'),

            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fonte Ativa para Captura Automática', style: TextStyle(color: AppColors.textMain, fontSize: 12)),
              value: ativo,
              activeColor: AppColors.brandLight,
              onChanged: (val) => setState(() => ativo = val),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: saveFonte,
                icon: const Icon(Icons.save, color: Colors.white, size: 16),
                label: Text(isEditing ? 'Salvar Alterações da Fonte' : 'Cadastrar e Conectar Fonte', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _input(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textMain, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
