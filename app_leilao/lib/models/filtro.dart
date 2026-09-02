class FiltroSalvo {
  final int? id;
  final String nome;
  final String uf;
  final String? municipio;
  final String? tipo;
  final String? termoBusca;
  final bool ativo;

  FiltroSalvo({
    this.id,
    required this.nome,
    required this.uf,
    this.municipio,
    this.tipo,
    this.termoBusca,
    this.ativo = true,
  });

  factory FiltroSalvo.fromMap(Map<String, dynamic> map) {
    return FiltroSalvo(
      id: map['id'],
      nome: map['nome'] ?? 'Rotina',
      uf: (map['uf'] ?? 'MA').toString().toUpperCase(),
      municipio: map['municipio'],
      tipo: map['tipo'],
      termoBusca: map['termo_busca'],
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
      'termo_busca': termoBusca,
      'ativo': ativo ? 1 : 0,
    };
  }
}
