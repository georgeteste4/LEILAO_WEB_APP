import React, { useState } from 'react';
import { View, Text, StyleSheet, Alert } from 'react-native';
import { Button } from './ui/Button';
import { Card } from './ui/Card';
import { syncDatabaseFromGitHub, restoreDefaultSeed } from '../database/dbSyncManager';
import { Database, Download, RotateCcw } from 'lucide-react-native';

interface DatabaseSyncSectionProps {
  onSyncComplete?: () => void;
}

export const DatabaseSyncSection: React.FC<DatabaseSyncSectionProps> = ({ onSyncComplete }) => {
  const [loading, setLoading] = useState(false);
  const [progressMsg, setProgressMsg] = useState<string | null>(null);

  const handleSyncFromGitHub = async () => {
    setLoading(true);
    setProgressMsg('Conectando ao repositório GitHub...');
    try {
      const res = await syncDatabaseFromGitHub((current, total) => {
        setProgressMsg(`Importando imóveis: ${current}/${total}`);
      });
      Alert.alert(
        'Sincronização Concluída!',
        `Base atualizada com sucesso!\nTotal: ${res.total} imóveis\nNovos: ${res.novos}\nAtualizados: ${res.atualizados}`
      );
      if (onSyncComplete) onSyncComplete();
    } catch (e: any) {
      Alert.alert('Erro ao importar base', e.message);
    } finally {
      setLoading(false);
      setProgressMsg(null);
    }
  };

  const handleRestore = async () => {
    Alert.alert(
      'Restaurar Base Padrão',
      'Deseja recarregar o banco de dados inicial com os 373 imóveis embutidos?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Restaurar',
          style: 'destructive',
          onPress: async () => {
            setLoading(true);
            try {
              await restoreDefaultSeed();
              Alert.alert('Sucesso', 'Base restaurada para o padrão inicial!');
              if (onSyncComplete) onSyncComplete();
            } catch (e: any) {
              Alert.alert('Erro', e.message);
            } finally {
              setLoading(false);
            }
          }
        }
      ]
    );
  };

  return (
    <Card style={styles.card}>
      <View style={styles.header}>
        <View style={styles.iconBox}>
          <Database size={18} color="#34d399" />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Gestão da Base de Dados SQLite</Text>
          <Text style={styles.subtitle}>Sincronize com o GitHub ou restaure a base local.</Text>
        </View>
      </View>

      <View style={styles.actionsGrid}>
        <Button
          title={loading ? 'Sincronizando...' : 'Baixar do GitHub'}
          variant="secondary"
          size="sm"
          loading={loading}
          icon={<Download size={14} color="#38bdf8" />}
          onPress={handleSyncFromGitHub}
          style={{ marginBottom: 6 }}
        />

        <Button
          title="Restaurar Base Inicial"
          variant="outline"
          size="sm"
          icon={<RotateCcw size={14} color="#f8fafc" />}
          onPress={handleRestore}
        />
      </View>

      {progressMsg ? (
        <View style={styles.progressBox}>
          <Text style={styles.progressText}>{progressMsg}</Text>
        </View>
      ) : null}
    </Card>
  );
};

const styles = StyleSheet.create({
  card: {
    marginBottom: 14,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  iconBox: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: 'rgba(5, 150, 105, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  title: {
    color: '#f8fafc',
    fontSize: 14,
    fontWeight: '700',
  },
  subtitle: {
    color: '#94a3b8',
    fontSize: 12,
    marginTop: 2,
  },
  actionsGrid: {
    marginTop: 4,
  },
  progressBox: {
    backgroundColor: '#1e293b',
    padding: 8,
    borderRadius: 6,
    marginTop: 8,
  },
  progressText: {
    color: '#38bdf8',
    fontSize: 12,
    textAlign: 'center',
  },
});
