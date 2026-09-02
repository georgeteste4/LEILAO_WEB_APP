class LogCron {
  final int? id;
  final int? filtroId;
  final String filtroNome;
  final String status;
  final int totalPaginas;
  final int totalImoveis;
  final int novos;
  final int atualizados;
  final int tempoSegundos;
  final String executadoEm;

  LogCron({
    this.id,
    this.filtroId,
    required this.filtroNome,
    required this.status,
    required this.totalPaginas,
    required this.totalImoveis,
    required this.novos,
    required this.atualizados,
    required this.tempoSegundos,
    required this.executadoEm,
  });

  factory LogCron.fromMap(Map<String, dynamic> map) {
    return LogCron(
      id: map['id'],
      filtroId: map['filtro_id'],
      filtroNome: map['filtro_nome'] ?? 'Rotina Manual',
      status: map['status'] ?? 'sucesso',
      totalPaginas: map['total_paginas'] ?? 0,
      totalImoveis: map['total_imoveis'] ?? 0,
      novos: map['novos'] ?? 0,
      atualizados: map['atualizados'] ?? 0,
      tempoSegundos: map['tempo_segundos'] ?? 0,
      executadoEm: map['executado_em'] ?? DateTime.now().toIso8601String(),
    );
  }
}
