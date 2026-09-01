import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, FlatList, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, RefreshControl } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Imovel } from '../../src/types';
import { getImoveisOffline } from '../../src/database/imoveisRepository';
import { PropertyCard } from '../../src/components/PropertyCard';
import { PropertyDetailModal } from '../../src/components/PropertyDetailModal';
import { ESTADOS_LISTA } from '../../src/constants/states';
import { Search, SlidersHorizontal, Database, Globe, RefreshCw } from 'lucide-react-native';

export default function CatalogScreen() {
  const [imoveis, setImoveis] = useState<Imovel[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedImovel, setSelectedImovel] = useState<Imovel | null>(null);
  const [total, setTotal] = useState(0);

  const [uf, setUf] = useState('MA');
  const [termoBusca, setTermoBusca] = useState('');
  const [ordem, setOrdem] = useState('desconto_desc');
  const [pagina, setPagina] = useState(1);
  const [modoOnline, setModoOnline] = useState(false);

  const loadProperties = useCallback(async (pageToLoad = 1) => {
    setLoading(true);
    try {
      const res = await getImoveisOffline({
        uf,
        termoBusca: termoBusca.trim() || undefined,
        ordem,
        pagina: pageToLoad,
        limit: 20
      });
      if (res.success) {
        setImoveis(pageToLoad === 1 ? res.data : [...imoveis, ...res.data]);
        setTotal(res.total);
        setPagina(pageToLoad);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [uf, termoBusca, ordem, imoveis]);

  useEffect(() => {
    loadProperties(1);
  }, [uf, ordem]);

  const onRefresh = () => {
    setRefreshing(true);
    loadProperties(1);
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerTitleRow}>
          <View style={styles.logoBadge}>
            <Text style={styles.logoBadgeText}>L</Text>
          </View>
          <View>
            <Text style={styles.headerTitle}>Leilão de Imóveis</Text>
            <Text style={styles.headerSubtitle}>{total} imóveis na base local SQLite</Text>
          </View>
        </View>

        {/* Toggle Modo */}
        <TouchableOpacity
          style={[styles.modeToggle, modoOnline && styles.modeToggleOnline]}
          onPress={() => setModoOnline(!modoOnline)}
        >
          {modoOnline ? <Globe size={13} color="#38bdf8" /> : <Database size={13} color="#34d399" />}
          <Text style={[styles.modeToggleText, modoOnline ? { color: '#38bdf8' } : { color: '#34d399' }]}>
            {modoOnline ? 'ONLINE' : 'OFFLINE'}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Barra de Busca e Filtros */}
      <View style={styles.filterBar}>
        <View style={styles.searchBox}>
          <Search size={15} color="#94a3b8" style={{ marginRight: 6 }} />
          <TextInput
            placeholder="Buscar por cidade, endereço, leiloeiro..."
            placeholderTextColor="#64748b"
            value={termoBusca}
            onChangeText={setTermoBusca}
            onSubmitEditing={() => loadProperties(1)}
            style={styles.searchInput}
          />
        </View>
      </View>

      {/* Lista de Imóveis */}
      <FlatList
        data={imoveis}
        keyExtractor={(item, index) => item.hash_imovel || `${item.id || index}`}
        renderItem={({ item }) => (
          <PropertyCard imovel={item} onPress={(im) => setSelectedImovel(im)} />
        )}
        contentContainerStyle={styles.listContent}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#38bdf8" />}
        ListEmptyComponent={
          !loading ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyTitle}>Nenhum imóvel encontrado</Text>
              <Text style={styles.emptySubtitle}>Tente ajustar os filtros ou baixar a base atualizada em Configurações.</Text>
            </View>
          ) : null
        }
      />

      {/* Modal de Detalhes */}
      <PropertyDetailModal
        imovel={selectedImovel}
        visible={Boolean(selectedImovel)}
        onClose={() => setSelectedImovel(null)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#090d16',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  headerTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logoBadge: {
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  logoBadgeText: {
    color: '#090d16',
    fontWeight: '900',
    fontSize: 16,
  },
  headerTitle: {
    color: '#f8fafc',
    fontSize: 16,
    fontWeight: '800',
  },
  headerSubtitle: {
    color: '#94a3b8',
    fontSize: 11,
  },
  modeToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(5, 150, 105, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(5, 150, 105, 0.3)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  modeToggleOnline: {
    backgroundColor: 'rgba(2, 132, 199, 0.15)',
    borderColor: 'rgba(2, 132, 199, 0.3)',
  },
  modeToggleText: {
    fontSize: 11,
    fontWeight: '700',
    marginLeft: 4,
  },
  filterBar: {
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0f172a',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#1e293b',
    paddingHorizontal: 10,
    height: 40,
  },
  searchInput: {
    flex: 1,
    color: '#f8fafc',
    fontSize: 13,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingBottom: 24,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    marginTop: 40,
  },
  emptyTitle: {
    color: '#f8fafc',
    fontSize: 15,
    fontWeight: '700',
  },
  emptySubtitle: {
    color: '#64748b',
    fontSize: 12,
    textAlign: 'center',
    marginTop: 4,
  },
});
