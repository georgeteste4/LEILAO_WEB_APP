import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppUpdateSection } from '../../src/components/AppUpdateSection';
import { DatabaseSyncSection } from '../../src/components/DatabaseSyncSection';
import { Card } from '../../src/components/ui/Card';
import { Info, Shield } from 'lucide-react-native';

export default function SettingsScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Painel de Configurações</Text>
        <Text style={styles.headerSubtitle}>Atualizações de APK, base de dados e parâmetros do sistema</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Seção de Atualização de APK */}
        <AppUpdateSection />

        {/* Seção de Base de Dados */}
        <DatabaseSyncSection />

        {/* Informações do App */}
        <Card style={styles.infoCard}>
          <View style={styles.infoHeader}>
            <Info size={16} color="#38bdf8" style={{ marginRight: 6 }} />
            <Text style={styles.infoTitle}>Sobre o Aplicativo</Text>
          </View>
          <Text style={styles.infoText}>
            Aplicativo de Leilões de Imóveis com banco de dados SQLite interno e suporte a múltiplos portais (Caixa, Banco do Brasil, Zukerman, Leilão Imóvel).
          </Text>
        </Card>
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
  infoCard: {
    marginBottom: 14,
  },
  infoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  infoTitle: {
    color: '#f8fafc',
    fontSize: 13,
    fontWeight: '700',
  },
  infoText: {
    color: '#94a3b8',
    fontSize: 12,
    lineHeight: 18,
  },
});
