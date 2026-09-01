import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'accent' | 'discount' | 'warning' | 'success';
}

export const Badge: React.FC<BadgeProps> = ({ children, variant = 'default' }) => {
  return (
    <View style={[styles.base, styles[variant]]}>
      <Text style={[styles.text, styles[`${variant}Text`]]}>{children}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  base: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    alignSelf: 'flex-start',
    borderWidth: 1,
    marginRight: 4,
    marginBottom: 4,
  },
  default: {
    backgroundColor: 'rgba(148, 163, 184, 0.1)',
    borderColor: 'rgba(148, 163, 184, 0.2)',
  },
  accent: {
    backgroundColor: 'rgba(2, 132, 199, 0.12)',
    borderColor: 'rgba(2, 132, 199, 0.3)',
  },
  discount: {
    backgroundColor: 'rgba(225, 29, 72, 0.12)',
    borderColor: 'rgba(225, 29, 72, 0.3)',
  },
  warning: {
    backgroundColor: 'rgba(217, 119, 6, 0.12)',
    borderColor: 'rgba(217, 119, 6, 0.3)',
  },
  success: {
    backgroundColor: 'rgba(5, 150, 105, 0.12)',
    borderColor: 'rgba(5, 150, 105, 0.3)',
  },
  text: {
    fontSize: 11,
    fontWeight: '600',
  },
  defaultText: { color: '#cbd5e1' },
  accentText: { color: '#38bdf8' },
  discountText: { color: '#fb7185' },
  warningText: { color: '#fbbf24' },
  successText: { color: '#34d399' },
});
