import React from 'react';
import { View, Text, Image, Modal, ScrollView, TouchableOpacity, StyleSheet, Linking } from 'react-native';
import { Imovel } from '../types';
import { Button } from './ui/Button';
import { Badge } from './ui/Badge';
import { X, FileText, ExternalLink, ShieldCheck, MapPin, Calendar } from 'lucide-react-native';

interface PropertyDetailModalProps {
  imovel: Imovel | null;
  visible: boolean;
  onClose: () => void;
}

export const PropertyDetailModal: React.FC<PropertyDetailModalProps> = ({ imovel, visible, onClose }) => {
  if (!imovel) return null;

  const formatMoney = (val: number | null | undefined) => {
    if (!val) return '-';
    return `R$ ${val.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  const economia = imovel.valor_avaliacao && imovel.valor_leilao && imovel.valor_avaliacao > imovel.valor_leilao
    ? imovel.valor_avaliacao - imovel.valor_leilao
    : 0;

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.headerTitle} numberOfLines={1}>Ficha Técnica do Imóvel</Text>
            <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
              <X size={20} color="#94a3b8" />
            </TouchableOpacity>
          </View>

          <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
            {imovel.imagem ? (
              <Image source={{ uri: imovel.imagem }} style={styles.coverImage} resizeMode="cover" />
            ) : null}

            <View style={styles.badgesRow}>
              <Badge variant="accent">{imovel.tipo}</Badge>
              <Badge variant="default">{imovel.fonte_slug.toUpperCase()}</Badge>
              {imovel.desconto ? <Badge variant="discount">-{Math.round(imovel.desconto)}% DESCONTO</Badge> : null}
            </View>

            <Text style={styles.title}>{imovel.titulo}</Text>

            <View style={styles.addressRow}>
              <MapPin size={14} color="#94a3b8" style={{ marginTop: 2, marginRight: 4 }} />
              <Text style={styles.addressText}>{imovel.endereco || `${imovel.cidade}/${imovel.uf}`}</Text>
            </View>

            <View style={styles.financialCard}>
              <View style={styles.finCol}>
                <Text style={styles.finLabel}>Avaliação Oficial</Text>
                <Text style={styles.finValCut}>{formatMoney(imovel.valor_avaliacao)}</Text>
              </View>
              <View style={styles.finCol}>
                <Text style={styles.finLabel}>Lance Mínimo</Text>
                <Text style={styles.finValLeilao}>{formatMoney(imovel.valor_leilao)}</Text>
              </View>
            </View>

            {economia > 0 ? (
              <View style={styles.savingBox}>
                <Text style={styles.savingBoxText}>
                  Economia Estimada: <Text style={{ fontWeight: '800' }}>{formatMoney(economia)}</Text>
                </Text>
              </View>
            ) : null}

            <View style={styles.detailsCard}>
              <View style={styles.detailItem}>
                <Text style={styles.detailKey}>Modalidade:</Text>
                <Text style={styles.detailVal}>{imovel.modalidade || 'Leilão'}</Text>
              </View>
              {imovel.data_encerramento ? (
                <View style={styles.detailItem}>
                  <Text style={styles.detailKey}>Data Encerramento:</Text>
                  <Text style={styles.detailVal}>{imovel.data_encerramento}</Text>
                </View>
              ) : null}
              {imovel.numero_matricula ? (
                <View style={styles.detailItem}>
                  <Text style={styles.detailKey}>Número da Matrícula:</Text>
                  <Text style={styles.detailVal}>{imovel.numero_matricula}</Text>
                </View>
              ) : null}
              {imovel.nome_leiloeiro ? (
                <View style={styles.detailItem}>
                  <Text style={styles.detailKey}>Leiloeiro:</Text>
                  <Text style={styles.detailVal}>{imovel.nome_leiloeiro}</Text>
                </View>
              ) : null}
            </View>

            <View style={styles.docsSection}>
              <Text style={styles.sectionTitle}>Documentação & Links Oficiais</Text>
              
              {imovel.edital ? (
                <Button
                  title="Acessar Edital Oficial"
                  variant="secondary"
                  size="sm"
                  style={{ marginBottom: 8 }}
                  icon={<FileText size={14} color="#38bdf8" />}
                  onPress={() => Linking.openURL(imovel.edital!)}
                />
              ) : null}

              {imovel.link_matricula ? (
                <Button
                  title="Baixar Certidão de Matrícula (PDF)"
                  variant="secondary"
                  size="sm"
                  style={{ marginBottom: 8 }}
                  icon={<ShieldCheck size={14} color="#34d399" />}
                  onPress={() => Linking.openURL(imovel.link_matricula!)}
                />
              ) : null}

              {imovel.link ? (
                <Button
                  title="Ver Anúncio Original"
                  variant="primary"
                  size="sm"
                  icon={<ExternalLink size={14} color="#ffffff" />}
                  onPress={() => Linking.openURL(imovel.link)}
                />
              ) : null}
            </View>
          </ScrollView>

          <View style={styles.footer}>
            <Button title="Fechar" variant="outline" size="sm" onPress={onClose} style={{ width: '100%' }} />
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    justifyContent: 'flex-end',
  },
  container: {
    backgroundColor: '#090d16',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '90%',
    borderWidth: 1,
    borderColor: '#1e293b',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  headerTitle: {
    color: '#f8fafc',
    fontSize: 16,
    fontWeight: '700',
    flex: 1,
  },
  closeBtn: {
    padding: 4,
  },
  scrollContent: {
    padding: 16,
  },
  coverImage: {
    width: '100%',
    height: 180,
    borderRadius: 10,
    marginBottom: 12,
  },
  badgesRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 8,
  },
  title: {
    color: '#f8fafc',
    fontSize: 16,
    fontWeight: '800',
    lineHeight: 22,
    marginBottom: 8,
  },
  addressRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 14,
  },
  addressText: {
    color: '#94a3b8',
    fontSize: 13,
    flex: 1,
  },
  financialCard: {
    flexDirection: 'row',
    backgroundColor: '#0f172a',
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: '#1e293b',
    marginBottom: 8,
  },
  finCol: {
    flex: 1,
  },
  finLabel: {
    color: '#94a3b8',
    fontSize: 11,
    marginBottom: 4,
  },
  finValCut: {
    color: '#64748b',
    fontSize: 14,
    textDecorationLine: 'line-through',
    fontWeight: '600',
  },
  finValLeilao: {
    color: '#34d399',
    fontSize: 16,
    fontWeight: '800',
  },
  savingBox: {
    backgroundColor: 'rgba(225, 29, 72, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(225, 29, 72, 0.3)',
    borderRadius: 8,
    padding: 10,
    marginBottom: 14,
  },
  savingBoxText: {
    color: '#fb7185',
    fontSize: 13,
  },
  detailsCard: {
    backgroundColor: '#0f172a',
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: '#1e293b',
    marginBottom: 14,
  },
  detailItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 5,
    borderBottomWidth: 1,
    borderBottomColor: '#1e293b',
  },
  detailKey: {
    color: '#94a3b8',
    fontSize: 12,
  },
  detailVal: {
    color: '#f8fafc',
    fontSize: 12,
    fontWeight: '600',
  },
  docsSection: {
    marginBottom: 10,
  },
  sectionTitle: {
    color: '#f8fafc',
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 8,
  },
  footer: {
    padding: 14,
    borderTopWidth: 1,
    borderTopColor: '#1e293b',
  },
});
