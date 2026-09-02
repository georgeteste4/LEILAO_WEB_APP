class FonteDados {
  final int? id;
  final String nome;
  final String slug;
  final String driver;
  final String urlBase;
  final String? descricao;
  final bool ativo;
  final int totalColetados;
  final String? ultimaColeta;

  FonteDados({
    this.id,
    required this.nome,
    required this.slug,
    required this.driver,
    required this.urlBase,
    this.descricao,
    this.ativo = true,
    this.totalColetados = 0,
    this.ultimaColeta,
  });

  factory FonteDados.fromMap(Map<String, dynamic> map) {
    return FonteDados(
      id: map['id'],
      nome: map['nome'] ?? 'Fonte',
      slug: map['slug'] ?? 'generic',
      driver: map['driver'] ?? 'GenericSource',
      urlBase: map['url_base'] ?? '',
      descricao: map['descricao'],
      ativo: (map['ativo'] == 1 || map['ativo'] == true),
      totalColetados: map['total_coletados'] ?? 0,
      ultimaColeta: map['ultima_coleta'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'slug': slug,
      'driver': driver,
      'url_base': urlBase,
      'descricao': descricao,
      'ativo': ativo ? 1 : 0,
      'total_coletados': totalColetados,
      'ultima_coleta': ultimaColeta,
    };
  }
}
