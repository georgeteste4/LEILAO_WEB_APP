import 'dart:async';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/alerta_imovel.dart';

class NotificationService {
  static List<String> activeAlertMessages = [];

  static Future<List<String>> checkAlerts() async {
    final alertas = await DBHelper.instance.getAlertasAtivos();
    final List<String> messages = [];

    for (var a in alertas) {
      if (a.tipoAlerta == 'diario_24h') {
        messages.add('⏰ Lembrete Diário: Acompanhe o leilão de "${a.tituloImovel}"');
      } else {
        messages.add('🔔 Atenção: O leilão de "${a.tituloImovel}" está próximo do encerramento (${a.descricaoTipo})');
      }
    }

    activeAlertMessages = messages;
    return messages;
  }
}
