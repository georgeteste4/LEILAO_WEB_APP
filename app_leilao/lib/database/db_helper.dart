import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/imovel.dart';
import '../models/filtro.dart';
import '../models/log_cron.dart';
import '../models/alerta_imovel.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('leilao_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS imoveis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_imovel TEXT UNIQUE,
        fonte_slug TEXT NOT NULL,
        filtro_id INTEGER,
        titulo TEXT NOT NULL,
        tipo TEXT NOT NULL,
        endereco TEXT,
        cidade TEXT,
        uf TEXT NOT NULL,
        valor_avaliacao REAL,
        valor_leilao REAL,
        desconto REAL,
        modalidade TEXT,
        data_encerramento TEXT,
        data_inclusao TEXT,
        edital TEXT,
        link_matricula TEXT,
        numero_matricula TEXT,
        link_leiloeiro TEXT,
        nome_leiloeiro TEXT,
        link_original TEXT NOT NULL,
        imagem TEXT,
        status TEXT DEFAULT 'ativo',
        criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
        atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS filtros_salvos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        uf TEXT NOT NULL,
        municipio TEXT,
        tipo TEXT,
        termo_busca TEXT,
        ativo INTEGER DEFAULT 1,
        criado_em TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS logs_cron (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filtro_id INTEGER,
        status TEXT DEFAULT 'sucesso',
        total_paginas INTEGER DEFAULT 0,
        total_imoveis INTEGER DEFAULT 0,
        novos INTEGER DEFAULT 0,
        atualizados INTEGER DEFAULT 0,
        tempo_segundos INTEGER DEFAULT 0,
        executado_em TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await _createFavoritesAndAlertsTables(db);
    await _seedInitialData(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFavoritesAndAlertsTables(db);
    }
  }

  Future _createFavoritesAndAlertsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favoritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_imovel TEXT UNIQUE NOT NULL,
        criado_em TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS alertas_imoveis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash_imovel TEXT NOT NULL,
        titulo_imovel TEXT NOT NULL,
        tipo_alerta TEXT NOT NULL,
        antecedencia_horas INTEGER DEFAULT 24,
        recorrencia_horas INTEGER DEFAULT 24,
        anotacao TEXT,
        ativo INTEGER DEFAULT 1,
        ultimo_disparo TEXT,
        criado_em TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  Future _seedInitialData(Database db) async {
    try {
      final String seedJson = await rootBundle.loadString('assets/seed_imoveis.json');
      final List<dynamic> list = jsonDecode(seedJson);

      final batch = db.batch();
      for (var item in list) {
        final imovel = Imovel.fromMap(item as Map<String, dynamic>);
        batch.insert('imoveis', imovel.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);

      final String filtrosJson = await rootBundle.loadString('assets/seed_filtros.json');
      final List<dynamic> fList = jsonDecode(filtrosJson);
      final fBatch = db.batch();
      for (var f in fList) {
        fBatch.insert('filtros_salvos', {
          'nome': f['nome'],
          'uf': f['uf'],
          'municipio': f['municipio'],
          'tipo': f['tipo'],
          'termo_busca': f['termo_busca'],
          'ativo': 1
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await fBatch.commit(noResult: true);
    } catch (e) {
      // Ignorar erros de seed duplicado
    }
  }

  // ==========================================
  // FAVORITOS
  // ==========================================
  Future<bool> toggleFavorito(String hashImovel) async {
    final db = await instance.database;
    final exists = await db.query('favoritos', where: 'hash_imovel = ?', whereArgs: [hashImovel], limit: 1);
    if (exists.isNotEmpty) {
      await db.delete('favoritos', where: 'hash_imovel = ?', whereArgs: [hashImovel]);
      return false;
    } else {
      await db.insert('favoritos', {'hash_imovel': hashImovel});
      return true;
    }
  }

  Future<bool> isFavorito(String hashImovel) async {
    final db = await instance.database;
    final res = await db.query('favoritos', where: 'hash_imovel = ?', whereArgs: [hashImovel], limit: 1);
    return res.isNotEmpty;
  }

  Future<Set<String>> getFavoritosHashes() async {
    final db = await instance.database;
    final res = await db.query('favoritos');
    return res.map((e) => e['hash_imovel'] as String).toSet();
  }

  Future<List<Imovel>> getImoveisFavoritos() async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT i.* FROM imoveis i
      INNER JOIN favoritos f ON f.hash_imovel = i.hash_imovel
      ORDER BY f.id DESC
    ''');
    return res.map((e) => Imovel.fromMap(e)).toList();
  }

  // ==========================================
  // ALERTAS "ME AVISE"
  // ==========================================
  Future<int> saveAlerta(AlertaImovel alerta) async {
    final db = await instance.database;
    final existing = await db.query('alertas_imoveis', where: 'hash_imovel = ?', whereArgs: [alerta.hashImovel], limit: 1);
    if (existing.isNotEmpty) {
      return await db.update('alertas_imoveis', alerta.toMap(), where: 'hash_imovel = ?', whereArgs: [alerta.hashImovel]);
    } else {
      return await db.insert('alertas_imoveis', alerta.toMap());
    }
  }

  Future<int> deleteAlerta(String hashImovel) async {
    final db = await instance.database;
    return await db.delete('alertas_imoveis', where: 'hash_imovel = ?', whereArgs: [hashImovel]);
  }

  Future<AlertaImovel?> getAlertaByHash(String hashImovel) async {
    final db = await instance.database;
    final res = await db.query('alertas_imoveis', where: 'hash_imovel = ?', whereArgs: [hashImovel], limit: 1);
    if (res.isNotEmpty) {
      return AlertaImovel.fromMap(res.first);
    }
    return null;
  }

  Future<List<AlertaImovel>> getAlertasAtivos() async {
    final db = await instance.database;
    final res = await db.query('alertas_imoveis', where: 'ativo = 1', orderBy: 'id DESC');
    return res.map((e) => AlertaImovel.fromMap(e)).toList();
  }

  // ==========================================
  // CONSULTAS GERAIS DE IMÓVEIS
  // ==========================================
  Future<List<Imovel>> getImoveis({
    required String uf,
    List<String>? municipios,
    String? tipo,
    String? fonte,
    String? busca,
    bool apenasFavoritos = false,
    String ordem = 'desconto_desc',
    int limit = 50,
  }) async {
    final db = await instance.database;
    List<String> whereClauses = ["uf = ? AND status = 'ativo'"];
    List<dynamic> whereArgs = [uf.toUpperCase()];

    if (apenasFavoritos) {
      whereClauses.add("hash_imovel IN (SELECT hash_imovel FROM favoritos)");
    }

    if (fonte != null && fonte != 'todas') {
      whereClauses.add("fonte_slug = ?");
      whereArgs.add(fonte.toLowerCase());
    }

    if (tipo != null && tipo.isNotEmpty && tipo != 'todos') {
      whereClauses.add("tipo LIKE ?");
      whereArgs.add('%' + tipo + '%');
    }

    if (municipios != null && municipios.isNotEmpty) {
      final mClauses = municipios.map((_) => "cidade LIKE ?").join(" OR ");
      whereClauses.add("(" + mClauses + ")");
      for (var m in municipios) {
        whereArgs.add('%' + m + '%');
      }
    }

    if (busca != null && busca.trim().isNotEmpty) {
      whereClauses.add("(titulo LIKE ? OR endereco LIKE ? OR cidade LIKE ? OR nome_leiloeiro LIKE ?)");
      final b = '%' + busca.trim() + '%';
      whereArgs.addAll([b, b, b, b]);
    }

    String orderBy = 'COALESCE(desconto, 0) DESC, id DESC';
    switch (ordem) {
      case 'desconto_asc': orderBy = 'COALESCE(desconto, 0) ASC, id DESC'; break;
      case 'valor_asc': orderBy = 'COALESCE(valor_leilao, 999999999) ASC, id DESC'; break;
      case 'valor_desc': orderBy = 'COALESCE(valor_leilao, 0) DESC, id DESC'; break;
      case 'avaliacao_desc': orderBy = 'COALESCE(valor_avaliacao, 0) DESC, id DESC'; break;
      case 'recentes': orderBy = 'id DESC'; break;
    }

    final result = await db.query(
      'imoveis',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );

    return result.map((json) => Imovel.fromMap(json)).toList();
  }

  Future<List<String>> getCidadesByUf(String uf) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      "SELECT DISTINCT cidade FROM imoveis WHERE uf = ? AND cidade IS NOT NULL AND cidade != '' ORDER BY cidade ASC",
      [uf.toUpperCase()],
    );
    return res.map((r) => r['cidade'] as String).toList();
  }

  Future<int> countImoveis() async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM imoveis');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<String> upsertImovel(Imovel imovel) async {
    final db = await instance.database;
    final hash = imovel.hashImovel.isNotEmpty
        ? imovel.hashImovel
        : 'hash_' + imovel.linkOriginal.hashCode.abs().toString();

    final existing = await db.query('imoveis', where: 'hash_imovel = ?', whereArgs: [hash], limit: 1);
    if (existing.isNotEmpty) {
      await db.update('imoveis', imovel.toMap(), where: 'hash_imovel = ?', whereArgs: [hash]);
      return 'updated';
    } else {
      final map = imovel.toMap();
      map['hash_imovel'] = hash;
      await db.insert('imoveis', map);
      return 'inserted';
    }
  }

  Future<List<FiltroSalvo>> getFiltros() async {
    final db = await instance.database;
    final res = await db.query('filtros_salvos', orderBy: 'id DESC');
    return res.map((e) => FiltroSalvo.fromMap(e)).toList();
  }

  Future<int> insertFiltro(FiltroSalvo f) async {
    final db = await instance.database;
    return await db.insert('filtros_salvos', f.toMap());
  }

  Future<int> deleteFiltro(int id) async {
    final db = await instance.database;
    return await db.delete('filtros_salvos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LogCron>> getLogs() async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT l.*, COALESCE(f.nome, 'Rotina Manual') as filtro_nome
      FROM logs_cron l
      LEFT JOIN filtros_salvos f ON f.id = l.filtro_id
      ORDER BY l.id DESC LIMIT 30
    ''');
    return res.map((e) => LogCron.fromMap(e)).toList();
  }

  Future<int> insertLog(LogCron log) async {
    final db = await instance.database;
    return await db.insert('logs_cron', {
      'filtro_id': log.filtroId,
      'status': log.status,
      'total_paginas': log.totalPaginas,
      'total_imoveis': log.totalImoveis,
      'novos': log.novos,
      'atualizados': log.atualizados,
      'tempo_segundos': log.tempoSegundos,
    });
  }

  Future resetDatabase() async {
    final db = await instance.database;
    await db.delete('imoveis');
    await db.delete('favoritos');
    await db.delete('alertas_imoveis');
    await _seedInitialData(db);
  }
}
