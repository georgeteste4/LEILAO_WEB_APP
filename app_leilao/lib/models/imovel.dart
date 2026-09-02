class Imovel {
  final int? id;
  final String hashImovel;
  final String fonteSlug;
  final int? filtroId;
  final String titulo;
  final String tipo;
  final String endereco;
  final String cidade;
  final String uf;
  final double? valorAvaliacao;
  final double? valorLeilao;
  final double? desconto;
  final String modalidade;
  final String? dataEncerramento;
  final String? dataInclusao;
  final String? edital;
  final String? linkMatricula;
  final String? numeroMatricula;
  final String? linkLeiloeiro;
  final String? nomeLeiloeiro;
  final String linkOriginal;
  final String imagem;
  final String status;

  Imovel({
    this.id,
    required this.hashImovel,
    required this.fonteSlug,
    this.filtroId,
    required this.titulo,
    required this.tipo,
    required this.endereco,
    required this.cidade,
    required this.uf,
    this.valorAvaliacao,
    this.valorLeilao,
    this.desconto,
    required this.modalidade,
    this.dataEncerramento,
    this.dataInclusao,
    this.edital,
    this.linkMatricula,
    this.numeroMatricula,
    this.linkLeiloeiro,
    this.nomeLeiloeiro,
    required this.linkOriginal,
    required this.imagem,
    this.status = 'ativo',
  });

  factory Imovel.fromMap(Map<String, dynamic> map) {
    return Imovel(
      id: map['id'],
      hashImovel: map['hash_imovel'] ?? '',
      fonteSlug: map['fonte_slug'] ?? 'leilaoimovel',
      filtroId: map['filtro_id'],
      titulo: map['titulo'] ?? 'Imóvel sem título',
      tipo: map['tipo'] ?? 'Imóvel',
      endereco: map['endereco'] ?? '',
      cidade: map['cidade'] ?? '',
      uf: (map['uf'] ?? 'MA').toString().toUpperCase(),
      valorAvaliacao: map['valor_avaliacao'] != null ? (map['valor_avaliacao'] as num).toDouble() : null,
      valorLeilao: map['valor_leilao'] != null ? (map['valor_leilao'] as num).toDouble() : null,
      desconto: map['desconto'] != null ? (map['desconto'] as num).toDouble() : null,
      modalidade: map['modalidade'] ?? 'Leilão',
      dataEncerramento: map['data_encerramento'],
      dataInclusao: map['data_inclusao'],
      edital: map['edital'],
      linkMatricula: map['link_matricula'],
      numeroMatricula: map['numero_matricula'],
      linkLeiloeiro: map['link_leiloeiro'],
      nomeLeiloeiro: map['nome_leiloeiro'],
      linkOriginal: map['link_original'] ?? map['link'] ?? '',
      imagem: map['imagem'] ?? '',
      status: map['status'] ?? 'ativo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hash_imovel': hashImovel,
      'fonte_slug': fonteSlug,
      'filtro_id': filtroId,
      'titulo': titulo,
      'tipo': tipo,
      'endereco': endereco,
      'cidade': cidade,
      'uf': uf,
      'valor_avaliacao': valorAvaliacao,
      'valor_leilao': valorLeilao,
      'desconto': desconto,
      'modalidade': modalidade,
      'data_encerramento': dataEncerramento,
      'data_inclusao': dataInclusao,
      'edital': edital,
      'link_matricula': linkMatricula,
      'numero_matricula': numeroMatricula,
      'link_leiloeiro': linkLeiloeiro,
      'nome_leiloeiro': nomeLeiloeiro,
      'link_original': linkOriginal,
      'imagem': imagem,
      'status': status,
    };
  }
}
