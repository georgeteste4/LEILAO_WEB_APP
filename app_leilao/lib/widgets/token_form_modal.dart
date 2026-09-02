import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/token_pool.dart';
import '../services/scraper_service.dart';

class TokenFormModal extends StatefulWidget {
  const TokenFormModal({super.key});

  @override
  State<TokenFormModal> createState() => _TokenFormModalState();
}

class _TokenFormModalState extends State<TokenFormModal> {
  final tokenController = TextEditingController();
  final limitController = TextEditingController(text: '1000');
  String provedor = 'scrape.do';
  bool testing = false;
  String? testResult;
  bool testSuccess = false;

  Future saveToken() async {
    final tok = tokenController.text.trim();
    if (tok.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira a chave de API!')));
      return;
    }

    final t = TokenPool(
      provedor: provedor,
      token: tok,
      limiteMensal: int.tryParse(limitController.text) ?? 1000,
      ativo: true,
    );

    await DBHelper.instance.saveToken(t);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave adicionada com sucesso ao pool!')));
    }
  }

  Future testConnection() async {
    final tok = tokenController.text.trim();
    if (tok.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira uma chave antes de testar!')));
      return;
    }

    setState(() {
      testing = true;
      testResult = null;
    });

    final res = await ScraperService.testarChave(provedor, tok);
    setState(() {
      testing = false;
      testSuccess = res['success'] == true;
      testResult = res['message'] + (res['latency_ms'] != null ? ' (' + res['latency_ms'].toString() + 'ms)' : '');
    });
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Adicionar Chave de Scraping', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textDim), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            const Text('Provedor', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provedor,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(value: 'scrape.do', child: Text('Scrape.do (Recomendado)')),
                    DropdownMenuItem(value: 'firecrawl', child: Text('Firecrawl API')),
                    DropdownMenuItem(value: 'custom', child: Text('Provedor Personalizado')),
                  ],
                  onChanged: (v) => setState(() => provedor = v ?? 'scrape.do'),
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text('Chave de API (Token)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                hintText: 'Cole a chave da API (ex: 40a83... ou fc-...)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 12),

            const Text('Limite Mensal Estimado', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ex: 1000',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 14),

            if (testResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: testSuccess ? AppColors.success.withOpacity(0.15) : AppColors.discount.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: testSuccess ? AppColors.successLight : AppColors.discountLight),
                ),
                child: Row(
                  children: [
                    Icon(testSuccess ? Icons.check_circle : Icons.error, color: testSuccess ? AppColors.successLight : AppColors.discountLight, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(testResult!, style: TextStyle(color: testSuccess ? AppColors.successLight : AppColors.discountLight, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandLight)),
                    onPressed: testing ? null : testConnection,
                    icon: testing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLight))
                        : const Icon(Icons.speed, color: AppColors.brandLight, size: 18),
                    label: Text(testing ? 'Testando...' : 'Testar Conexão', style: const TextStyle(color: AppColors.brandLight)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                    onPressed: saveToken,
                    child: const Text('Salvar Chave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
