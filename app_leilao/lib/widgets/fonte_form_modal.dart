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
    if (nomeController.text.trim().isEmpty || slugController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome e slug!')));
      return;
    }

    final f = FonteDados(
      id: widget.fonte?.id,
      nome: nomeController.text.trim(),
      slug: slugController.text.trim().toLowerCase().replaceAll(' ', '-'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.fonte != null ? 'Editar Fonte de Dados' : 'Conectar Nova Fonte', style: const TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
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
                        child: DropdownButton<String>(
                          value: selectedDriver,
                          dropdownColor: AppColors.surface,
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'GenericSource', child: Text('GenericSource')),
                            DropdownMenuItem(value: 'LeilaoImovelSource', child: Text('LeilaoImovelSource')),
                            DropdownMenuItem(value: 'CaixaSource', child: Text('CaixaSource')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedDriver = val);
                          },
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
            _label('DESCRIÇÃO'),
            _input(descController, 'Foco em imóveis de bancos...'),

            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fonte Ativa para Captura', style: TextStyle(color: AppColors.textMain, fontSize: 12)),
              value: ativo,
              activeColor: AppColors.brandLight,
              onChanged: (val) => setState(() => ativo = val),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                onPressed: saveFonte,
                child: const Text('Salvar Fonte de Dados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      child: Text(text, style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _input(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textMain, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }
}
