import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/imovel.dart';
import '../models/alerta_imovel.dart';

class AlertConfigModal extends StatefulWidget {
  final Imovel imovel;

  const AlertConfigModal({super.key, required this.imovel});

  @override
  State<AlertConfigModal> createState() => _AlertConfigModalState();
}

class _AlertConfigModalState extends State<AlertConfigModal> {
  String selectedType = 'encerramento_24h';
  final noteController = TextEditingController();
  bool hasExisting = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExistingAlert();
  }

  Future loadExistingAlert() async {
    final alerta = await DBHelper.instance.getAlertaByHash(widget.imovel.hashImovel);
    if (alerta != null) {
      setState(() {
        selectedType = alerta.tipoAlerta;
        noteController.text = alerta.anotacao ?? '';
        hasExisting = true;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future saveAlert() async {
    final a = AlertaImovel(
      hashImovel: widget.imovel.hashImovel,
      tituloImovel: widget.imovel.titulo,
      tipoAlerta: selectedType,
      antecedenciaHoras: selectedType == 'encerramento_48h' ? 48 : 24,
      recorrenciaHoras: 24,
      anotacao: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
      ativo: true,
    );

    await DBHelper.instance.saveAlerta(a);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta "Me Avise" configurado com sucesso!')),
      );
    }
  }

  Future removeAlert() async {
    await DBHelper.instance.deleteAlerta(widget.imovel.hashImovel);
    if (mounted) {
      Navigator.pop(context, false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta removido.')),
      );
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
      child: loading
          ? const Center(heightFactor: 4, child: CircularProgressIndicator(color: AppColors.brandLight))
          : Column(
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
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.brandLight, size: 20),
                    const SizedBox(width: 8),
                    const Text('Configurar Alerta "Me Avise"', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.imovel.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),

                const Text('SELECIONE O TIPO DE NOTIFICAÇÃO', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                _typeOption(
                  id: 'encerramento_24h',
                  title: '24 Horas Antes do Fim',
                  subtitle: 'Notificar um dia antes do encerramento do leilão',
                  icon: Icons.timer_outlined,
                ),
                _typeOption(
                  id: 'encerramento_48h',
                  title: '48 Horas Antes do Fim',
                  subtitle: 'Notificar dois dias antes para preparar lance e garantia',
                  icon: Icons.alarm,
                ),
                _typeOption(
                  id: 'diario_24h',
                  title: 'Lembrete Diário (A cada 24h)',
                  subtitle: 'Emitir um alerta diário para acompanhar a disputa',
                  icon: Icons.repeat,
                ),

                const SizedBox(height: 12),
                const Text('ESTRATÉGIA / ANOTAÇÃO PESSOAL (OPCIONAL)', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: r'Ex: Lance máximo de R$ 150.000...',

                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    if (hasExisting) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.discount)),
                          onPressed: removeAlert,
                          child: const Text('Remover Alerta', style: TextStyle(color: AppColors.discount, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                        onPressed: saveAlert,
                        child: Text(hasExisting ? 'Salvar Alterações' : 'Criar Alerta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _typeOption({required String id, required String title, required String subtitle, required IconData icon}) {
    final selected = selectedType == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppColors.brandLight : AppColors.border),
      ),
      child: ListTile(
        onTap: () => setState(() => selectedType = id),
        leading: Icon(icon, color: selected ? AppColors.brandLight : AppColors.textMuted, size: 22),
        title: Text(title, style: TextStyle(color: selected ? Colors.white : AppColors.textMain, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        trailing: selected ? const Icon(Icons.check_circle, color: AppColors.brandLight, size: 20) : null,
      ),
    );
  }
}
