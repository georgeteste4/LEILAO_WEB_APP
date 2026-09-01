import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, Alert, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { FiltroSalvo, LogCron } from '../../src/types';
import { getFiltros } from '../../src/database/filtrosRepository';
import { getLogs } from '../../src/database/logsRepository';
import { executeFiltroCapture } from '../../src/services/syncService';
import { Card } from '../../src/components/ui/Card';
import { Button } from '../../src/components/ui/Button';
import { Play, RotateCcw, Clock, CheckCircle, Database } from 'lucide-react-native';

export default function AdminScreen() {
  const [filtros, setFiltros] = useState<FiltroSalvo[]>([]);
  const [logs, setLogs] = useState<LogCron[]>([]);
  const [runningId, setRunningId] = useState<number | null>(null);
  const [progressText, setProgressText] = useState<string | null>(null);

  const loadData = async () => {
    try {
      const flts = await getFiltros();
      const lgs = await getLogs();
      setFiltros(flts);
      setLogs(lgs);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleExecuteFiltro = async (filtro: FiltroSalvo) => {
    setRunningId(filtro.id);
    setProgressText(`Executando captura para ${filtro.nome}...`);
    try {
      const res = await executeFiltroCapture(filtro, (pag, novos) => {
        setProgressText(`Página ${pag} processada (${novos} novos)`);
      });
      Alert.alert(
        'Execução Concluída!',
        `Rotina finalizada em ${res.tempo_segundos}s!\nNovos: ${res.novos}\nAtualizados: ${res.atualizados}`
      );
      await loadData();
    } catch (e: any) {
      Alert.alert('Erro ao executar', e.message);
    } finally {
      setRunningId(null);
      setProgressText(null);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Painel de Administração & Rotinas</Text>
        <Text style={styles.headerSubtitle}>Gerencie e execute rotinas de captura de imóveis</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Filtros de Captura */}
        <Text style={styles.sectionTitle}>Rotinas de Captura Cadastradas</Text>
        {filtros.map((f) => (
          <Card key={f.id} style={styles.filtroCard}>
            <View style={styles.filtroHeader}>
              <View style={{ flex: 1 }}>
                <Text style={styles.filtroNome}>{f.nome}</Text>
                <Text style={styles.filtroMeta}>UF: {f.uf} • {f.municipio ? `Cidade: ${f.municipio}` : 'Todos os Municípios'}</Text>
              </View>
              <Button
                title={runningId === f.id ? 'Baixando...' : 'Baixar Tudo'}
                size="sm"
                variant="primary"
                loading={runningId === f.id}
                icon={<Play size={13} color="#ffffff" />}
                onPress={() => handleExecuteFiltro(f)}
              />
            </View>
          </Card>
        ))}

        {progressText ? (
          <View style={styles.runningBox}>
            <Text style={styles.runningText}>{progressText}</Text>
          </View>
        ) : null}

        {/* Histórico de Logs */}
        <Text style={[styles.sectionTitle, { marginTop: 20 }]}>Histórico de Execuções</Text>
        {logs.slice(0, 10).map((l) => (
          <Card key={l.id} style={styles.logCard}>
            <View style={styles.logRow}>
              <CheckCircle size={14} color="#34d399" style={{ marginRight: 6 }} />
              <Text style={styles.logFiltro}>{l.filtro_nome}</Text>
              <Text style={styles.logTime}>{l.tempo_segundos}s</Text>
            </View>
            <Text style={styles.logDetails}>
              {l.novos} novos • {l.atualizados} atualizados • {l.total_paginas} páginas
            </Text>
          </Card>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#090d16',
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  headerTitle: {
    color: '#f8fafc',
    fontSize: 16,
    fontWeight: '800',
  },
  headerSubtitle: {
    color: '#94a3b8',
    fontSize: 11,
    marginTop: 2,
  },
  scrollContent: {
    padding: 16,
  },
  sectionTitle: {
    color: '#f8fafc',
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 10,
  },
  filtroCard: {
    marginBottom: 10,
  },
  filtroHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  filtroNome: {
    color: '#f8fafc',
    fontSize: 14,
    fontWeight: '700',
  },
  filtroMeta: {
    color: '#94a3b8',
    fontSize: 12,
    marginTop: 2,
  },
  runningBox: {
    backgroundColor: '#1e293b',
    padding: 10,
    borderRadius: 8,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#38bdf8',
  },
  runningText: {
    color: '#38bdf8',
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
  },
  logCard: {
    marginBottom: 6,
    padding: 10,
  },
  logRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logFiltro: {
    color: '#f8fafc',
    fontSize: 12,
    fontWeight: '600',
    flex: 1,
  },
  logTime: {
    color: '#94a3b8',
    fontSize: 11,
  },
  logDetails: {
    color: '#64748b',
    fontSize: 11,
    marginTop: 4,
  },
});
