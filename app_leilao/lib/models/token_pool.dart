class TokenPool {
  final int? id;
  final String provedor; // 'scrape.do', 'firecrawl', 'custom'
  final String token;
  final int limiteMensal;
  final int requisicoesUsadas;
  final bool ativo;
  final String? criadoEm;

  TokenPool({
    this.id,
    required this.provedor,
    required this.token,
    this.limiteMensal = 1000,
    this.requisicoesUsadas = 0,
    this.ativo = true,
    this.criadoEm,
  });

  String get tokenMascarado {
    if (token.length <= 8) return '****';
    return token.substring(0, 4) + '...' + token.substring(token.length - 4);
  }

  factory TokenPool.fromMap(Map<String, dynamic> map) {
    return TokenPool(
      id: map['id'],
      provedor: map['provedor'] ?? 'scrape.do',
      token: map['token'] ?? '',
      limiteMensal: map['limite_mensal'] ?? 1000,
      requisicoesUsadas: map['requisicoes_usadas'] ?? 0,
      ativo: (map['ativo'] == 1 || map['ativo'] == true),
      criadoEm: map['criado_em'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'provedor': provedor,
      'token': token,
      'limite_mensal': limiteMensal,
      'requisicoes_usadas': requisicoesUsadas,
      'ativo': ativo ? 1 : 0,
    };
  }
}
