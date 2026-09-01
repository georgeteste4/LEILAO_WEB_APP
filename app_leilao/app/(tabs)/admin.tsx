import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, Alert, TextInput, Modal, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { FiltroSalvo, LogCron } from '../../src/types';
import { getFiltros, salvarFiltro, excluirFiltro } from '../../src/database/filtrosRepository';
import { getLogs } from '../../src/database/logsRepository';
import { executeFiltroCapture } from '../../src/services/syncService';
import { Card } from '../../src/components/ui/Card';
import { Button } from '../../src/components/ui/Button';
import { Play, Plus, Trash2, CheckCircle, Database, Layers, Activity, Clock, X } from 'lucide-react-native';

export default function AdminScreen() {
  const [filtros, setFiltros] = useState<FiltroSalvo[]>([]);
  const [logs, setLogs] = useState<LogCron[]>([]);
  const [runningId, setRunningId] = useState<number | null>(null);
  const [progressText, setProgressText] = useState<string | null>(null);

  // Modal Novo Filtro
  const [newModalVisible, setNewModalVisible] = useState(false);
  const [novoNome, setNovoNome] = useState('');
  const [novaUf, setNovaUf] = useState('MA');
  const [novoMunicipio, setNovoMunicipio] = useState('');
  const [novoTipo, setNovoTipo] = useState('');

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
        setProgressText(`Página ${pag} processada (${novos} novos salvos no SQLite)`);
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

  const handleCriarFiltro = async () => {
    if (!novoNome.trim() || !novaUf.trim()) {
      Alert.alert('Aviso', 'Nome e UF são obrigatórios.');
      return;
    }
    try {
      await salvarFiltro({
        nome: novoNome.trim(),
        uf: novaUf.trim().toUpperCase(),
        municipio: novoMunicipio.trim() || null,
        tipo: novoTipo.trim() || null,
        ativo: 1
      });
      setNewModalVisible(false);
      setNovoNome('');
      setNovoMunicipio('');
      setNovoTipo('');
      await loadData();
    } catch (e: any) {
      Alert.alert('Erro', e.message);
    }
  };

  const handleExcluir = async (id: number) => {
    Alert.alert('Confirmar Exclusão', 'Deseja remover esta rotina de captura?', [
      { text: 'Cancelar', style: 'cancel' },
      {
        text: 'Excluir',
        style: 'destructive',
        onPress: async () => {
          await excluirFiltro(id);
          await loadData();
        }
      }
    ]);
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Painel de Administração & Rotinas</Text>
        <Text style={styles.headerSubtitle}>Gerenciamento de extração e captura de leilões</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Cards de Métricas */}
        <View style={styles.metricsGrid}>
          <Card style={styles.metricCard}>
            <Layers size={16} color="#38bdf8" />
            <Text style={styles.metricValue}>{filtros.length}</Text>
            <Text style={styles.metricLabel}>Rotinas Ativas</Text>
          </Card>
          <Card style={styles.metricCard}>
            <Activity size={16} color="#34d399" />
            <Text style={styles.metricValue}>{logs.length}</Text>
            <Text style={styles.metricLabel}>Execuções Gravadas</Text>
          </Card>
        </View>

        {/* Header de Rotinas */}
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Rotinas de Captura</Text>
          <Button
            title="+ Nova Rotina"
            size="sm"
            variant="secondary"
            onPress={() => setNewModalVisible(true)}
          />
        </View>

        {/* Lista de Rotinas */}
        {filtros.map((f) => (
          <Card key={f.id} style={styles.filtroCard}>
            <View style={styles.filtroHeader}>
              <View style={{ flex: 1 }}>
                <Text style={styles.filtroNome}>{f.nome}</Text>
                <Text style={styles.filtroMeta}>UF: {f.uf} • {f.municipio ? `Cidade: ${f.municipio}` : 'Todos os Municípios'} {f.tipo ? `• Tipo: ${f.tipo}` : ''}</Text>
              </View>
              <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                <Button
                  title={runningId === f.id ? 'Baixando...' : 'Baixar Tudo'}
                  size="sm"
                  variant="primary"
                  loading={runningId === f.id}
                  icon={<Play size={12} color="#ffffff" />}
                  onPress={() => handleExecuteFiltro(f)}
                  style={{ marginRight: 6 }}
                />
                <TouchableOpacity onPress={() => handleExcluir(f.id)} style={{ padding: 6 }}>
                  <Trash2 size={16} color="#fb7185" />
                </TouchableOpacity>
              </View>
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

      {/* Modal Criar Rotina */}
      <Modal visible={newModalVisible} transparent animationType="slide" onRequestClose={() => setNewModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Cadastrar Nova Rotina</Text>
              <TouchableOpacity onPress={() => setNewModalVisible(false)}>
                <X size={20} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            <TextInput
              placeholder="Nome da rotina (ex: São Luís - Casas)"
              placeholderTextColor="#64748b"
              value={novoNome}
              onChangeText={setNovoNome}
              style={styles.input}
            />

            <TextInput
              placeholder="Estado UF (ex: MA, SP, RJ)"
              placeholderTextColor="#64748b"
              value={novaUf}
              onChangeText={setNovaUf}
              style={styles.input}
              maxLength={2}
            />

            <TextInput
              placeholder="Município (Opcional - ex: Sao Luis)"
              placeholderTextColor="#64748b"
              value={novoMunicipio}
              onChangeText={setNovoMunicipio}
              style={styles.input}
            />

            <TextInput
              placeholder="Tipo (Opcional - ex: apartamento, casa)"
              placeholderTextColor="#64748b"
              value={novoTipo}
              onChangeText={setNovoTipo}
              style={styles.input}
            />

            <Button
              title="Salvar Rotina de Captura"
              variant="primary"
              size="md"
              onPress={handleCriarFiltro}
              style={{ marginTop: 10 }}
            />
          </View>
        </View>
      </Modal>
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
  metricsGrid: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 16,
  },
  metricCard: {
    flex: 1,
    alignItems: 'center',
    padding: 12,
  },
  metricValue: {
    color: '#f8fafc',
    fontSize: 20,
    fontWeight: '800',
    marginTop: 4,
  },
  metricLabel: {
    color: '#94a3b8',
    fontSize: 11,
    marginTop: 2,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  sectionTitle: {
    color: '#f8fafc',
    fontSize: 14,
    fontWeight: '700',
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
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'flex-end',
  },
  modalSheet: {
    backgroundColor: '#090d16',
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    padding: 16,
    borderWidth: 1,
    borderColor: '#1e293b',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
  },
  modalTitle: {
    color: '#f8fafc',
    fontSize: 15,
    fontWeight: '700',
  },
  input: {
    backgroundColor: '#0f172a',
    borderWidth: 1,
    borderColor: '#1e293b',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    color: '#f8fafc',
    fontSize: 13,
    marginBottom: 10,
  },
});


