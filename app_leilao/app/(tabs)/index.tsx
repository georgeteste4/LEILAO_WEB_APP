import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, FlatList, TextInput, TouchableOpacity, StyleSheet, Modal, ScrollView, RefreshControl } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Imovel } from '../../src/types';
import { getImoveisOffline } from '../../src/database/imoveisRepository';
import { PropertyCard } from '../../src/components/PropertyCard';
import { PropertyTable } from '../../src/components/PropertyTable';
import { PropertyList } from '../../src/components/PropertyList';
import { PropertyDetailModal } from '../../src/components/PropertyDetailModal';
import { ESTADOS_LISTA } from '../../src/constants/states';
import { Button } from '../../src/components/ui/Button';
import { Search, LayoutGrid, Table, List, Globe, Database, Filter, ArrowUpDown, X, Check } from 'lucide-react-native';

export default function CatalogScreen() {
  const [imoveis, setImoveis] = useState<Imovel[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedImovel, setSelectedImovel] = useState<Imovel | null>(null);
  const [total, setTotal] = useState(0);

  const [viewMode, setViewMode] = useState<'grid' | 'table' | 'list'>('grid');
  const [uf, setUf] = useState('MA');
  const [tipo, setTipo] = useState('');
  const [fonte, setFonte] = useState('todas');
  const [termoBusca, setTermoBusca] = useState('');
  const [ordem, setOrdem] = useState('desconto_desc');
  const [pagina, setPagina] = useState(1);
  const [modoOnline, setModoOnline] = useState(false);

  // Modais de Filtro
  const [stateModalVisible, setStateModalVisible] = useState(false);
  const [sortModalVisible, setSortModalVisible] = useState(false);
  const [filterModalVisible, setFilterModalVisible] = useState(false);

  const loadProperties = useCallback(async (pageToLoad = 1) => {
    setLoading(true);
    try {
      const res = await getImoveisOffline({
        uf,
        tipo: tipo || undefined,
        fonte: fonte !== 'todas' ? fonte : undefined,
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
  }, [uf, tipo, fonte, termoBusca, ordem, imoveis]);

  useEffect(() => {
    loadProperties(1);
  }, [uf, tipo, fonte, ordem]);

  const onRefresh = () => {
    setRefreshing(true);
    loadProperties(1);
  };

  const getOrdemLabel = () => {
    switch (ordem) {
      case 'desconto_desc': return 'Maior Desconto';
      case 'valor_asc': return 'Menor Preço';
      case 'valor_desc': return 'Maior Preço';
      case 'avaliacao_desc': return 'Maior Avaliação';
      case 'recentes': return 'Mais Recentes';
      default: return 'Ordenação';
    }
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
            <Text style={styles.headerSubtitle}>{total} imóveis no SQLite</Text>
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

      {/* Barra de Busca & View Switcher */}
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

        {/* Botões de Visualização */}
        <View style={styles.viewSwitcher}>
          <TouchableOpacity
            style={[styles.viewBtn, viewMode === 'grid' && styles.viewBtnActive]}
            onPress={() => setViewMode('grid')}
          >
            <LayoutGrid size={15} color={viewMode === 'grid' ? '#38bdf8' : '#94a3b8'} />
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.viewBtn, viewMode === 'table' && styles.viewBtnActive]}
            onPress={() => setViewMode('table')}
          >
            <Table size={15} color={viewMode === 'table' ? '#38bdf8' : '#94a3b8'} />
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.viewBtn, viewMode === 'list' && styles.viewBtnActive]}
            onPress={() => setViewMode('list')}
          >
            <List size={15} color={viewMode === 'list' ? '#38bdf8' : '#94a3b8'} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Botões de Filtros Rápidos (Chips) */}
      <View style={styles.chipsRow}>
        <TouchableOpacity style={styles.chip} onPress={() => setStateModalVisible(true)}>
          <Text style={styles.chipText}>UF: <Text style={{ color: '#38bdf8', fontWeight: '800' }}>{uf}</Text></Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.chip} onPress={() => setSortModalVisible(true)}>
          <ArrowUpDown size={12} color="#94a3b8" style={{ marginRight: 4 }} />
          <Text style={styles.chipText}>{getOrdemLabel()}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.chip} onPress={() => setFilterModalVisible(true)}>
          <Filter size={12} color="#94a3b8" style={{ marginRight: 4 }} />
          <Text style={styles.chipText}>{tipo || fonte !== 'todas' ? 'Filtros (Ativos)' : 'Filtrar'}</Text>
        </TouchableOpacity>
      </View>

      {/* Conteúdo Conforme Visualização */}
      {viewMode === 'grid' ? (
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
                <Text style={styles.emptySubtitle}>Ajuste os filtros ou sincronize a base em Configurações.</Text>
              </View>
            ) : null
          }
        />
      ) : (
        <ScrollView
          contentContainerStyle={styles.listContent}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#38bdf8" />}
        >
          {viewMode === 'table' ? (
            <PropertyTable imoveis={imoveis} onSelect={(im) => setSelectedImovel(im)} />
          ) : (
            <PropertyList imoveis={imoveis} onSelect={(im) => setSelectedImovel(im)} />
          )}
        </ScrollView>
      )}

      {/* Modal de Seleção de Estado (UF) */}
      <Modal visible={stateModalVisible} transparent animationType="slide" onRequestClose={() => setStateModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Selecione o Estado (UF)</Text>
              <TouchableOpacity onPress={() => setStateModalVisible(false)}>
                <X size={20} color="#94a3b8" />
              </TouchableOpacity>
            </View>
            <ScrollView style={{ maxHeight: 400 }}>
              {ESTADOS_LISTA.map((est) => (
                <TouchableOpacity
                  key={est.sigla}
                  style={[styles.modalItem, uf === est.sigla && styles.modalItemActive]}
                  onPress={() => {
                    setUf(est.sigla);
                    setStateModalVisible(false);
                  }}
                >
                  <Text style={[styles.modalItemText, uf === est.sigla && styles.modalItemTextActive]}>
                    {est.nomeCompleto}
                  </Text>
                  {uf === est.sigla ? <Check size={16} color="#38bdf8" /> : null}
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        </View>
      </Modal>

      {/* Modal de Ordenação */}
      <Modal visible={sortModalVisible} transparent animationType="slide" onRequestClose={() => setSortModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Ordenar Imóveis</Text>
              <TouchableOpacity onPress={() => setSortModalVisible(false)}>
                <X size={20} color="#94a3b8" />
              </TouchableOpacity>
            </View>
            {[
              { id: 'desconto_desc', label: 'Maior Desconto %' },
              { id: 'valor_asc', label: 'Menor Preço de Leilão' },
              { id: 'valor_desc', label: 'Maior Preço de Leilão' },
              { id: 'avaliacao_desc', label: 'Maior Avaliação' },
              { id: 'encerramento_asc', label: 'Encerramento Mais Próximo' },
              { id: 'recentes', label: 'Mais Recentes' },
            ].map((opt) => (
              <TouchableOpacity
                key={opt.id}
                style={[styles.modalItem, ordem === opt.id && styles.modalItemActive]}
                onPress={() => {
                  setOrdem(opt.id);
                  setSortModalVisible(false);
                }}
              >
                <Text style={[styles.modalItemText, ordem === opt.id && styles.modalItemTextActive]}>
                  {opt.label}
                </Text>
                {ordem === opt.id ? <Check size={16} color="#38bdf8" /> : null}
              </TouchableOpacity>
            ))}
          </View>
        </View>
      </Modal>

      {/* Modal de Filtros (Tipo & Fonte) */}
      <Modal visible={filterModalVisible} transparent animationType="slide" onRequestClose={() => setFilterModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Filtros Avançados</Text>
              <TouchableOpacity onPress={() => setFilterModalVisible(false)}>
                <X size={20} color="#94a3b8" />
              </TouchableOpacity>
            </View>

            <Text style={styles.filterSectionTitle}>Tipo de Imóvel</Text>
            <View style={styles.filterOptionsGrid}>
              {['', 'apartamento', 'casa', 'terreno', 'rural', 'comercial'].map((t) => (
                <TouchableOpacity
                  key={t || 'todos'}
                  style={[styles.filterChip, tipo === t && styles.filterChipActive]}
                  onPress={() => setTipo(t)}
                >
                  <Text style={[styles.filterChipText, tipo === t && styles.filterChipTextActive]}>
                    {t ? t.toUpperCase() : 'TODOS'}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.filterSectionTitle}>Portal / Fonte</Text>
            <View style={styles.filterOptionsGrid}>
              {[
                { id: 'todas', label: 'TODAS' },
                { id: 'leilaoimovel', label: 'Leilão Imóvel' },
                { id: 'caixa', label: 'Caixa Econômica' },
                { id: 'smartleiloescaixa', label: 'Smart Leilões' },
                { id: 'bancodobrasil', label: 'Banco do Brasil' },
                { id: 'zukerman', label: 'Portal Zuk' }
              ].map((f) => (
                <TouchableOpacity
                  key={f.id}
                  style={[styles.filterChip, fonte === f.id && styles.filterChipActive]}
                  onPress={() => setFonte(f.id)}
                >
                  <Text style={[styles.filterChipText, fonte === f.id && styles.filterChipTextActive]}>
                    {f.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Button
              title="Aplicar Filtros"
              variant="primary"
              size="md"
              onPress={() => setFilterModalVisible(false)}
              style={{ marginTop: 16 }}
            />
          </View>
        </View>
      </Modal>

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
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 6,
  },
  searchBox: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0f172a',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#1e293b',
    paddingHorizontal: 10,
    height: 38,
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    color: '#f8fafc',
    fontSize: 13,
  },
  viewSwitcher: {
    flexDirection: 'row',
    backgroundColor: '#0f172a',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#1e293b',
    padding: 2,
  },
  viewBtn: {
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 6,
  },
  viewBtnActive: {
    backgroundColor: '#1e293b',
  },
  chipsRow: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingBottom: 10,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0f172a',
    borderWidth: 1,
    borderColor: '#1e293b',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
    marginRight: 8,
  },
  chipText: {
    color: '#cbd5e1',
    fontSize: 11,
    fontWeight: '600',
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
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
    paddingBottom: 8,
  },
  modalTitle: {
    color: '#f8fafc',
    fontSize: 15,
    fontWeight: '700',
  },
  modalItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  modalItemActive: {
    backgroundColor: 'rgba(2, 132, 199, 0.1)',
  },
  modalItemText: {
    color: '#cbd5e1',
    fontSize: 13,
  },
  modalItemTextActive: {
    color: '#38bdf8',
    fontWeight: '700',
  },
  filterSectionTitle: {
    color: '#94a3b8',
    fontSize: 12,
    fontWeight: '700',
    marginTop: 10,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  filterOptionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  filterChip: {
    backgroundColor: '#0f172a',
    borderWidth: 1,
    borderColor: '#1e293b',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
    marginRight: 6,
    marginBottom: 6,
  },
  filterChipActive: {
    backgroundColor: '#0284c7',
    borderColor: '#0284c7',
  },
  filterChipText: {
    color: '#cbd5e1',
    fontSize: 11,
    fontWeight: '600',
  },
  filterChipTextActive: {
    color: '#ffffff',
    fontWeight: '700',
  },
});
