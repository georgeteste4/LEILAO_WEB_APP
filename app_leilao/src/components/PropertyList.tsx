import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Imovel } from '../types';
import { Badge } from './ui/Badge';
import { MapPin } from 'lucide-react-native';

interface PropertyListProps {
  imoveis: Imovel[];
  onSelect: (imovel: Imovel) => void;
}

export const PropertyList: React.FC<PropertyListProps> = ({ imoveis, onSelect }) => {
  const formatMoney = (val: number | null | undefined) => {
    if (!val) return '-';
    return `R$ ${val.toLocaleString('pt-BR', { maximumFractionDigits: 0 })}`;
  };

  return (
    <View style={styles.container}>
      {imoveis.map((im, idx) => (
        <TouchableOpacity
          key={im.hash_imovel || `${im.id || idx}`}
          style={styles.item}
          onPress={() => onSelect(im)}
          activeOpacity={0.75}
        >
          <View style={styles.itemHeader}>
            <View style={styles.tagsRow}>
              <Badge variant="accent">{im.tipo}</Badge>
              <Badge variant="default">{im.fonte_slug.toUpperCase()}</Badge>
            </View>
            {im.desconto ? (
              <Text style={styles.discountText}>-{Math.round(im.desconto)}% OFF</Text>
            ) : null}
          </View>

          <Text style={styles.title} numberOfLines={1}>
            {im.titulo}
          </Text>

          <View style={styles.locRow}>
            <MapPin size={12} color="#94a3b8" style={{ marginRight: 4 }} />
            <Text style={styles.locText} numberOfLines={1}>
              {im.cidade ? `${im.cidade}/${im.uf}` : im.endereco || im.uf}
            </Text>
          </View>

          <View style={styles.pricesRow}>
            <Text style={styles.valCut}>{formatMoney(im.valor_avaliacao)}</Text>
            <Text style={styles.valLance}>{formatMoney(im.valor_leilao)}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 12,
  },
  item: {
    backgroundColor: '#0f172a',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#1e293b',
    padding: 12,
    marginBottom: 8,
  },
  itemHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  tagsRow: {
    flexDirection: 'row',
  },
  discountText: {
    color: '#fb7185',
    fontSize: 12,
    fontWeight: '800',
  },
  title: {
    color: '#f8fafc',
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 4,
  },
  locRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  locText: {
    color: '#94a3b8',
    fontSize: 11,
    flex: 1,
  },
  pricesRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: '#1e293b',
    paddingTop: 6,
  },
  valCut: {
    color: '#64748b',
    fontSize: 12,
    textDecorationLine: 'line-through',
  },
  valLance: {
    color: '#34d399',
    fontSize: 14,
    fontWeight: '800',
  },
});
