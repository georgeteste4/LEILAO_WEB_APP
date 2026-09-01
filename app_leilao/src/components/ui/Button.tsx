import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ActivityIndicator, ViewStyle } from 'react-native';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'outline' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
  icon?: React.ReactNode;
  style?: ViewStyle;
}

export const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled = false,
  icon,
  style
}) => {
  return (
    <TouchableOpacity
      activeOpacity={0.75}
      onPress={onPress}
      disabled={disabled || loading}
      style={[
        styles.base,
        styles[variant],
        styles[`size_${size}`],
        disabled && styles.disabled,
        style
      ]}
    >
      {loading ? (
        <ActivityIndicator color={variant === 'outline' || variant === 'ghost' ? '#f8fafc' : '#ffffff'} size="small" />
      ) : (
        <>
          {icon && <>{icon}</>}
          <Text style={[styles.text, styles[`text_${variant}`], styles[`textSize_${size}`], icon ? { marginLeft: 6 } : null]}>
            {title}
          </Text>
        </>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  base: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
  },
  primary: {
    backgroundColor: '#0284c7',
  },
  secondary: {
    backgroundColor: '#1e293b',
    borderWidth: 1,
    borderColor: '#334155',
  },
  outline: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#334155',
  },
  danger: {
    backgroundColor: '#e11d48',
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  size_sm: {
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  size_md: {
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  size_lg: {
    paddingHorizontal: 18,
    paddingVertical: 14,
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    fontWeight: '600',
  },
  text_primary: { color: '#ffffff' },
  text_secondary: { color: '#f8fafc' },
  text_outline: { color: '#f8fafc' },
  text_danger: { color: '#ffffff' },
  text_ghost: { color: '#94a3b8' },
  textSize_sm: { fontSize: 12 },
  textSize_md: { fontSize: 13 },
  textSize_lg: { fontSize: 15 },
});
