import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import '../database/db_helper.dart';
import '../models/token_pool.dart';

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

  Future saveToken() async {
    if (tokenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira a chave de API!')));
      return;
    }

    final t = TokenPool(
      provedor: provedor,
      token: tokenController.text.trim(),
      limiteMensal: int.tryParse(limitController.text) ?? 1000,
      ativo: true,
    );

    await DBHelper.instance.saveToken(t);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave adicionada com sucesso!')));
    }
  }

  Future testConnection() async {
    final tok = tokenController.text.trim();
    if (tok.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira uma chave antes de testar!')));
      return;
    }

    setState(() => testing = true);
    try {
      final url = 'https://api.scrape.do?token=' + tok + '&url=https://httpbin.org/ip';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conexão realizada com sucesso!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resposta: HTTP ' + res.statusCode.toString())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no teste: ' + e.toString())));
    } finally {
      setState(() => testing = false);
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
          const Text('Adicionar Chave de Scraper ao Pool', style: TextStyle(color: AppColors.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          const Text('PROVEDOR DE API *', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
            child: DropdownButton<String>(
              value: provedor,
              dropdownColor: AppColors.surface,
              underline: const SizedBox(),
              isExpanded: true,
              style: const TextStyle(color: AppColors.textMain, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'scrape.do', child: Text('Scrape.do (Proxy Residencial)')),
                DropdownMenuItem(value: 'firecrawl', child: Text('Firecrawl')),
                DropdownMenuItem(value: 'custom', child: Text('Personalizado / Outro')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => provedor = val);
              },
            ),
          ),

          const SizedBox(height: 10),
          const Text('TOKEN / CHAVE DE API *', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: tokenController,
            obscureText: true,
            style: const TextStyle(color: AppColors.textMain, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cole a chave da API aqui...',
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),

          const SizedBox(height: 10),
          const Text('LIMITE MENSAL DE REQUISIÇÕES', style: TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: limitController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textMain, fontSize: 12),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderSubtle)),
                  onPressed: testing ? null : testConnection,
                  child: Text(testing ? 'Testando...' : 'Testar Conexão', style: const TextStyle(color: AppColors.brandLight, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                  onPressed: saveToken,
                  child: const Text('Salvar Chave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
