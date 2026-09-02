class AlertaImovel {
  final int? id;
  final String hashImovel;
  final String tituloImovel;
  final String tipoAlerta; // 'encerramento_24h', 'encerramento_48h', 'diario_24h'
  final int antecedenciaHoras;
  final int recorrenciaHoras;
  final String? anotacao;
  final bool ativo;
  final String? ultimoDisparo;
  final String? criadoEm;

  AlertaImovel({
    this.id,
    required this.hashImovel,
    required this.tituloImovel,
    required this.tipoAlerta,
    this.antecedenciaHoras = 24,
    this.recorrenciaHoras = 24,
    this.anotacao,
    this.ativo = true,
    this.ultimoDisparo,
    this.criadoEm,
  });

  factory AlertaImovel.fromMap(Map<String, dynamic> map) {
    return AlertaImovel(
      id: map['id'],
      hashImovel: map['hash_imovel'] ?? '',
      tituloImovel: map['titulo_imovel'] ?? 'Imóvel',
      tipoAlerta: map['tipo_alerta'] ?? 'encerramento_24h',
      antecedenciaHoras: map['antecedencia_horas'] ?? 24,
      recorrenciaHoras: map['recorrencia_horas'] ?? 24,
      anotacao: map['anotacao'],
      ativo: (map['ativo'] == 1 || map['ativo'] == true),
      ultimoDisparo: map['ultimo_disparo'],
      criadoEm: map['criado_em'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hash_imovel': hashImovel,
      'titulo_imovel': tituloImovel,
      'tipo_alerta': tipoAlerta,
      'antecedencia_horas': antecedenciaHoras,
      'recorrencia_horas': recorrenciaHoras,
      'anotacao': anotacao,
      'ativo': ativo ? 1 : 0,
      'ultimo_disparo': ultimoDisparo,
    };
  }

  String get descricaoTipo {
    switch (tipoAlerta) {
      case 'encerramento_48h':
        return '48h antes do encerramento';
      case 'diario_24h':
        return 'Lembrete diário a cada 24 horas';
      case 'encerramento_24h':
      default:
        return '24h antes do encerramento';
    }
  }
}
