import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/states.dart';
import '../database/db_helper.dart';
import '../models/filtro.dart';
import 'shad_components.dart';

class FiltroFormModal extends StatefulWidget {
  final FiltroSalvo? filtro;

  const FiltroFormModal({super.key, this.filtro});

  @override
  State<FiltroFormModal> createState() => _FiltroFormModalState();
}

class _FiltroFormModalState extends State<FiltroFormModal> {
  final nomeController = TextEditingController();
  final municipioController = TextEditingController();
  final termoController = TextEditingController();
  String uf = 'MA';
  String tipo = 'todos';
  String? dataFinal;
  List<String> fontesSelecionadas = ['caixa', 'leilaoimovel'];

  static const Map<String, String> fontesDisponiveis = {
    'caixa': 'Caixa Econômica (CSV Oficial)',
    'leilaoimovel': 'Leilão Imóvel (Portal)',
    'bancodobrasil': 'Banco do Brasil (Seu Imóvel BB)',
    'zukerman': 'Portal Zuk (Zukerman)',
    'santander': 'Banco Santander',
    'bradesco': 'Banco Bradesco',
    'itau': 'Banco Itaú',
    'bancointer': 'Banco Inter',
    'sicredi': 'Sicredi',
    'smartleiloescaixa': 'Smart Leilões Caixa',
  };

  static const Map<String, String> tiposDisponiveis = {
    'todos': 'Todos os Tipos',
    'apartamento': 'Apartamento',
    'casa': 'Casa',
    'terreno': 'Terreno',
    'rural': 'Rural / Fazenda',
    'comercial': 'Comercial / Sala',
    'galpao': 'Galpão',
  };

  @override
  void initState() {
    super.initState();
    if (widget.filtro != null) {
      final f = widget.filtro!;
      nomeController.text = f.nome;
      uf = f.uf;
      municipioController.text = f.municipio ?? '';
      termoController.text = f.termoBusca ?? '';
      tipo = f.tipo ?? 'todos';
      dataFinal = f.dataFinal;
      fontesSelecionadas = f.fontesList;
      if (fontesSelecionadas.isEmpty) fontesSelecionadas = ['caixa', 'leilaoimovel'];
    }
  }

  Future openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brand,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => dataFinal = DateFormat('dd/MM/yyyy').format(picked));
    }
  }

  Future saveFiltro() async {
    final nome = nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um nome para a rotina!')));
      return;
    }
    if (fontesSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione ao menos uma fonte de dados!')));
      return;
    }

    final flt = FiltroSalvo(
      id: widget.filtro?.id,
      nome: nome,
      uf: uf.toUpperCase(),
      municipio: municipioController.text.trim().isNotEmpty ? municipioController.text.trim() : null,
      tipo: tipo != 'todos' ? tipo : null,
      termoBusca: termoController.text.trim().isNotEmpty ? termoController.text.trim() : null,
      dataFinal: dataFinal,
      fontesSlugs: fontesSelecionadas.join(','),
      ativo: widget.filtro?.ativo ?? true,
    );

    await DBHelper.instance.insertFiltro(flt);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.filtro != null ? 'Rotina atualizada com sucesso!' : 'Rotina cadastrada com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.filtro != null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Rotina de Captura' : 'Cadastrar Nova Rotina de Captura',
                  style: const TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textDim), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Nome da Rotina
            const Text('Nome da Rotina *', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            TextField(
              controller: nomeController,
              style: const TextStyle(color: AppColors.textMain, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ex: Casas Caixa & BB no Maranhão',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 12),

            // UF e Município
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado (UF) *', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: uf,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            items: kEstadosBrasil.map((e) => DropdownMenuItem(value: e.sigla, child: Text(e.sigla))).toList(),
                            onChanged: (v) => setState(() => uf = v ?? 'MA'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Município (Opcional)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: municipioController,
                        style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ex: São Luís (ou vazio para todo o estado)',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fontes de Dados (Multi-Select com Checkboxes)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fontes de Dados (Uma ou mais) *', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() => fontesSelecionadas = fontesDisponiveis.keys.toList()),
                      child: const Text('Marcar Todas', style: TextStyle(color: AppColors.brandLight, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() => fontesSelecionadas.clear()),
                      child: const Text('Limpar', style: TextStyle(color: AppColors.discountLight, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: fontesDisponiveis.entries.map((e) {
                  final isChecked = fontesSelecionadas.contains(e.key);
                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: AppColors.brand,
                    title: Text(e.value, style: TextStyle(color: isChecked ? AppColors.brandLight : AppColors.textMain, fontSize: 12, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          fontesSelecionadas.add(e.key);
                        } else {
                          fontesSelecionadas.remove(e.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Tipo de Imóvel e Data Final
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de Imóvel', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tipo,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            items: tiposDisponiveis.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setState(() => tipo = v ?? 'todos'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Final do Leilão', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: openDatePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dataFinal != null ? dataFinal! : 'Indiferente', style: TextStyle(color: dataFinal != null ? AppColors.warningLight : AppColors.textDim, fontSize: 12)),
                              if (dataFinal != null)
                                InkWell(onTap: () => setState(() => dataFinal = null), child: const Icon(Icons.close, size: 14, color: AppColors.textDim))
                              else
                                const Icon(Icons.calendar_month, size: 14, color: AppColors.textDim),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Palavra-chave
            const Text('Palavra-chave / Termo de Busca (Opcional)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            TextField(
              controller: termoController,
              style: const TextStyle(color: AppColors.textMain, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ex: Centro, Renascença, Venda Direta...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 18),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: saveFiltro,
                icon: const Icon(Icons.save, color: Colors.white, size: 18),
                label: Text(isEditing ? 'Salvar Alterações da Rotina' : 'Cadastrar e Ativar Rotina', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
