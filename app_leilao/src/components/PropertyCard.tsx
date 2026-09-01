import React from 'react';
import { View, Text, Image, TouchableOpacity, StyleSheet } from 'react-native';
import { Imovel } from '../types';
import { Badge } from './ui/Badge';
import { MapPin, Calendar } from 'lucide-react-native';

interface PropertyCardProps {
  imovel: Imovel;
  onPress: (imovel: Imovel) => void;
}

export const PropertyCard: React.FC<PropertyCardProps> = ({ imovel, onPress }) => {
  const formatMoney = (val: number | null | undefined) => {
    if (val === null || val === undefined) return '-';
    return `R$ ${val.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  const economia = imovel.valor_avaliacao && imovel.valor_leilao && imovel.valor_avaliacao > imovel.valor_leilao
    ? imovel.valor_avaliacao - imovel.valor_leilao
    : 0;

  return (
    <TouchableOpacity
      activeOpacity={0.85}
      onPress={() => onPress(imovel)}
      style={styles.card}
    >
      <View style={styles.imageWrapper}>
        {imovel.imagem ? (
          <Image source={{ uri: imovel.imagem }} style={styles.image} resizeMode="cover" />
        ) : (
          <View style={[styles.image, styles.noImage]}>
            <Text style={styles.noImageText}>Sem foto</Text>
          </View>
        )}

        {imovel.desconto ? (
          <View style={styles.discountTag}>
            <Text style={styles.discountTagText}>-{Math.round(imovel.desconto)}% OFF</Text>
          </View>
        ) : null}

        <View style={styles.sourceTag}>
          <Text style={styles.sourceTagText}>{imovel.fonte_slug.toUpperCase()}</Text>
        </View>
      </View>

      <View style={styles.content}>
        <View style={styles.tagsRow}>
          <Badge variant="default">{imovel.tipo}</Badge>
          <Badge variant="accent">{imovel.modalidade || 'Leilão'}</Badge>
        </View>

        <Text style={styles.title} numberOfLines={2}>
          {imovel.titulo}
        </Text>

        <View style={styles.locationRow}>
          <MapPin size={13} color="#94a3b8" style={{ marginTop: 2, marginRight: 4 }} />
          <Text style={styles.locationText} numberOfLines={1}>
            {imovel.cidade ? `${imovel.cidade}/${imovel.uf}` : imovel.endereco || imovel.uf}
          </Text>
        </View>

        <View style={styles.financialSection}>
          <View style={styles.financialCol}>
            <Text style={styles.labelMuted}>Avaliação:</Text>
            <Text style={styles.valuationPrice}>{formatMoney(imovel.valor_avaliacao)}</Text>
          </View>
          <View style={styles.financialCol}>
            <Text style={styles.labelMuted}>Lance Inicial:</Text>
            <Text style={styles.auctionPrice}>{formatMoney(imovel.valor_leilao)}</Text>
          </View>
        </View>

        {economia > 0 ? (
          <View style={styles.savingRow}>
            <Text style={styles.savingText}>
              Economia de <Text style={{ fontWeight: '700' }}>{formatMoney(economia)}</Text>
            </Text>
          </View>
        ) : null}

        {imovel.data_encerramento ? (
          <View style={styles.footerRow}>
            <Calendar size={12} color="#fbbf24" style={{ marginRight: 4 }} />
            <Text style={styles.footerText}>Até: {imovel.data_encerramento}</Text>
          </View>
        ) : null}
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#0f172a',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#1e293b',
    overflow: 'hidden',
    marginBottom: 12,
  },
  imageWrapper: {
    height: 160,
    width: '100%',
    backgroundColor: '#1e293b',
    position: 'relative',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  noImage: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#1e293b',
  },
  noImageText: {
    color: '#64748b',
    fontSize: 12,
  },
  discountTag: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: '#e11d48',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  discountTagText: {
    color: '#ffffff',
    fontWeight: '800',
    fontSize: 11,
  },
  sourceTag: {
    position: 'absolute',
    bottom: 8,
    left: 8,
    backgroundColor: 'rgba(15, 23, 42, 0.85)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: 'rgba(148, 163, 184, 0.2)',
  },
  sourceTagText: {
    color: '#cbd5e1',
    fontSize: 9,
    fontWeight: '700',
  },
  content: {
    padding: 12,
  },
  tagsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 6,
  },
  title: {
    color: '#f8fafc',
    fontSize: 14,
    fontWeight: '700',
    lineHeight: 19,
    marginBottom: 6,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  locationText: {
    color: '#94a3b8',
    fontSize: 12,
    flex: 1,
  },
  financialSection: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#1e293b',
    padding: 8,
    borderRadius: 8,
    marginBottom: 6,
  },
  financialCol: {
    flex: 1,
  },
  labelMuted: {
    color: '#94a3b8',
    fontSize: 10,
    marginBottom: 2,
  },
  valuationPrice: {
    color: '#64748b',
    fontSize: 12,
    textDecorationLine: 'line-through',
    fontWeight: '600',
  },
  auctionPrice: {
    color: '#34d399',
    fontSize: 13,
    fontWeight: '800',
  },
  savingRow: {
    marginBottom: 6,
  },
  savingText: {
    color: '#fb7185',
    fontSize: 11,
  },
  footerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: '#1e293b',
    paddingTop: 6,
  },
  footerText: {
    color: '#fbbf24',
    fontSize: 11,
    fontWeight: '500',
  },
});
