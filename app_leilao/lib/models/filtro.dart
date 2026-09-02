class FiltroSalvo {
  final int? id;
  final String nome;
  final String uf;
  final String? municipio;
  final String? tipo;
  final String? dataFinal;
  final String? termoBusca;
  final String? fontesSlugs;
  final bool ativo;

  FiltroSalvo({
    this.id,
    required this.nome,
    required this.uf,
    this.municipio,
    this.tipo,
    this.dataFinal,
    this.termoBusca,
    this.fontesSlugs,
    this.ativo = true,
  });

  String? get dataFinalLeilao => dataFinal;

  List<String> get fontesList {
    if (fontesSlugs == null || fontesSlugs!.trim().isEmpty) {
      return ['caixa', 'leilaoimovel'];
    }
    return fontesSlugs!.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
  }

  factory FiltroSalvo.fromMap(Map<String, dynamic> map) {
    return FiltroSalvo(
      id: map['id'],
      nome: map['nome'] ?? 'Rotina',
      uf: (map['uf'] ?? 'MA').toString().toUpperCase(),
      municipio: map['municipio'],
      tipo: map['tipo'],
      dataFinal: map['data_final'] ?? map['data_final_leilao'],
      termoBusca: map['termo_busca'],
      fontesSlugs: map['fontes_slugs'] ?? map['fontes'],
      ativo: (map['ativo'] == 1 || map['ativo'] == true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'uf': uf,
      'municipio': municipio,
      'tipo': tipo,
      'data_final': dataFinal,
      'termo_busca': termoBusca,
      'fontes_slugs': fontesSlugs,
      'ativo': ativo ? 1 : 0,
    };
  }
}
