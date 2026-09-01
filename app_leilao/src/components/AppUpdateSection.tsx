import React, { useState } from 'react';
import { View, Text, StyleSheet, Alert } from 'react-native';
import { Button } from './ui/Button';
import { Card } from './ui/Card';
import { CURRENT_VERSION, checkAppUpdate, downloadAndInstallApk } from '../services/updateService';
import { AppReleaseInfo } from '../types';
import { RefreshCw, DownloadCloud, CheckCircle2, AlertCircle } from 'lucide-react-native';

export const AppUpdateSection: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [releaseInfo, setReleaseInfo] = useState<AppReleaseInfo | null>(null);
  const [statusMsg, setStatusMsg] = useState<string | null>(null);

  const handleCheckUpdate = async () => {
    setLoading(true);
    setStatusMsg(null);
    try {
      const info = await checkAppUpdate();
      setReleaseInfo(info);
      if (!info.has_update) {
        setStatusMsg('Seu aplicativo já está na versão mais recente!');
      }
    } catch (e: any) {
      Alert.alert('Erro ao buscar atualização', e.message || 'Verifique sua conexão com a internet.');
    } finally {
      setLoading(false);
    }
  };

  const handleInstallApk = async () => {
    if (!releaseInfo?.apk_url) {
      Alert.alert('Aviso', 'Nenhum arquivo APK direto encontrado nesta release.');
      return;
    }

    setDownloading(true);
    setProgress(0);
    try {
      await downloadAndInstallApk(releaseInfo.apk_url, (percent) => {
        setProgress(percent);
      });
    } catch (e: any) {
      Alert.alert('Erro ao baixar/instalar APK', e.message);
    } finally {
      setDownloading(false);
    }
  };

  return (
    <Card style={styles.card}>
      <View style={styles.header}>
        <View style={styles.iconBox}>
          <RefreshCw size={18} color="#38bdf8" />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Atualização do Aplicativo (APK)</Text>
          <Text style={styles.subtitle}>Versão Instalada: <Text style={styles.versionTag}>{CURRENT_VERSION}</Text></Text>
        </View>
      </View>

      <View style={styles.actionRow}>
        <Button
          title={loading ? 'Buscando...' : 'Buscar Atualização'}
          variant="secondary"
          size="sm"
          loading={loading}
          icon={<RefreshCw size={14} color="#f8fafc" />}
          onPress={handleCheckUpdate}
        />

        {releaseInfo?.has_update && releaseInfo.apk_url ? (
          <Button
            title={downloading ? `Baixando (${progress}%)` : 'Baixar e Atualizar APK'}
            variant="primary"
            size="sm"
            loading={downloading}
            style={{ marginLeft: 8 }}
            icon={<DownloadCloud size={14} color="#ffffff" />}
            onPress={handleInstallApk}
          />
        ) : null}
      </View>

      {statusMsg ? (
        <View style={styles.statusBox}>
          <CheckCircle2 size={14} color="#34d399" style={{ marginRight: 6 }} />
          <Text style={styles.statusText}>{statusMsg}</Text>
        </View>
      ) : null}

      {releaseInfo?.has_update ? (
        <View style={styles.updateAvailableBox}>
          <View style={styles.updateHeader}>
            <AlertCircle size={16} color="#fbbf24" style={{ marginRight: 6 }} />
            <Text style={styles.updateTitle}>Nova versão disponível: {releaseInfo.version}</Text>
          </View>
          <Text style={styles.changelog}>{releaseInfo.body}</Text>
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
    backgroundColor: 'rgba(2, 132, 199, 0.15)',
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
  versionTag: {
    color: '#38bdf8',
    fontWeight: '700',
  },
  actionRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  statusBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(5, 150, 105, 0.1)',
    padding: 8,
    borderRadius: 6,
    marginTop: 10,
    borderWidth: 1,
    borderColor: 'rgba(5, 150, 105, 0.2)',
  },
  statusText: {
    color: '#34d399',
    fontSize: 12,
    fontWeight: '500',
  },
  updateAvailableBox: {
    backgroundColor: '#1e293b',
    borderRadius: 8,
    padding: 10,
    marginTop: 10,
    borderWidth: 1,
    borderColor: 'rgba(217, 119, 6, 0.3)',
  },
  updateHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  updateTitle: {
    color: '#fbbf24',
    fontSize: 13,
    fontWeight: '700',
  },
  changelog: {
    color: '#cbd5e1',
    fontSize: 12,
    lineHeight: 16,
  },
});
