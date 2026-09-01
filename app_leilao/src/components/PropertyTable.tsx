import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Imovel } from '../types';

interface PropertyTableProps {
  imoveis: Imovel[];
  onSelect: (imovel: Imovel) => void;
}

export const PropertyTable: React.FC<PropertyTableProps> = ({ imoveis, onSelect }) => {
  const formatMoney = (val: number | null | undefined) => {
    if (!val) return '-';
    return `R$ ${val.toLocaleString('pt-BR', { maximumFractionDigits: 0 })}`;
  };

  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={true} style={styles.container}>
      <View>
        {/* Table Header */}
        <View style={styles.headerRow}>
          <Text style={[styles.headerCell, { width: 180 }]}>Imóvel</Text>
          <Text style={[styles.headerCell, { width: 80 }]}>Fonte</Text>
          <Text style={[styles.headerCell, { width: 90 }]}>Tipo</Text>
          <Text style={[styles.headerCell, { width: 110 }]}>Cidade/UF</Text>
          <Text style={[styles.headerCell, { width: 100, textAlign: 'right' }]}>Avaliação</Text>
          <Text style={[styles.headerCell, { width: 100, textAlign: 'right' }]}>Lance</Text>
          <Text style={[styles.headerCell, { width: 70, textAlign: 'center' }]}>Desc %</Text>
        </View>

        {/* Table Body */}
        {imoveis.map((im, idx) => (
          <TouchableOpacity
            key={im.hash_imovel || `${im.id || idx}`}
            style={[styles.row, idx % 2 === 1 && styles.rowAlt]}
            onPress={() => onSelect(im)}
            activeOpacity={0.7}
          >
            <Text style={[styles.cell, { width: 180, fontWeight: '700' }]} numberOfLines={1}>
              {im.titulo}
            </Text>
            <Text style={[styles.cell, { width: 80, color: '#38bdf8' }]} numberOfLines={1}>
              {im.fonte_slug.toUpperCase()}
            </Text>
            <Text style={[styles.cell, { width: 90 }]} numberOfLines={1}>
              {im.tipo}
            </Text>
            <Text style={[styles.cell, { width: 110 }]} numberOfLines={1}>
              {im.cidade ? `${im.cidade}/${im.uf}` : im.uf}
            </Text>
            <Text style={[styles.cell, { width: 100, textAlign: 'right', color: '#64748b', textDecorationLine: 'line-through' }]}>
              {formatMoney(im.valor_avaliacao)}
            </Text>
            <Text style={[styles.cell, { width: 100, textAlign: 'right', color: '#34d399', fontWeight: '800' }]}>
              {formatMoney(im.valor_leilao)}
            </Text>
            <Text style={[styles.cell, { width: 70, textAlign: 'center', color: '#fb7185', fontWeight: '800' }]}>
              {im.desconto ? `-${Math.round(im.desconto)}%` : '-'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#0f172a',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#1e293b',
    marginBottom: 12,
  },
  headerRow: {
    flexDirection: 'row',
    backgroundColor: '#1e293b',
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#334155',
  },
  headerCell: {
    color: '#94a3b8',
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  row: {
    flexDirection: 'row',
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
    alignItems: 'center',
  },
  rowAlt: {
    backgroundColor: 'rgba(30, 41, 59, 0.4)',
  },
  cell: {
    color: '#f8fafc',
    fontSize: 12,
  },
});
