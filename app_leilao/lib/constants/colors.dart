import 'package:flutter/material.dart';

/// Design Tokens inspirados no Shadcn UI (Zinc Dark Scheme)
class AppColors {
  // Fundo e Superfícies (Zinc)
  static const Color canvas = Color(0xFF09090B);          // zinc-950
  static const Color surface = Color(0xFF18181B);         // zinc-900
  static const Color surfaceElevated = Color(0xFF27272A); // zinc-800
  static const Color surfaceHover = Color(0xFF3F3F46);    // zinc-700

  // Bordas e Divisores
  static const Color border = Color(0xFF27272A);          // zinc-800
  static const Color borderSubtle = Color(0xFF3F3F46);    // zinc-700
  static const Color borderFocus = Color(0xFF38BDF8);     // sky-400

  // Tipografia (Zinc Scale)
  static const Color textMain = Color(0xFFFAFAFA);        // zinc-50
  static const Color textMuted = Color(0xFFA1A1AA);       // zinc-400
  static const Color textDim = Color(0xFF71717A);         // zinc-500

  // Cores de Acento Institucional
  static const Color brand = Color(0xFF0284C7);           // sky-600
  static const Color brandLight = Color(0xFF38BDF8);      // sky-400
  static const Color brandDark = Color(0xFF0369A1);       // sky-700

  // Sucesso & Oportunidade Financeira (Emerald)
  static const Color success = Color(0xFF059669);         // emerald-600
  static const Color successLight = Color(0xFF34D399);    // emerald-400
  static const Color successBg = Color(0x20059669);

  // Desconto & Urgência (Rose)
  static const Color discount = Color(0xFFE11D48);        // rose-600
  static const Color discountLight = Color(0xFFFB7185);   // rose-400
  static const Color discountBg = Color(0x25E11D48);

  // Alerta & Encerramento (Amber)
  static const Color warning = Color(0xFFD97706);         // amber-600
  static const Color warningLight = Color(0xFFFBBF24);    // amber-400
  static const Color warningBg = Color(0x25D97706);
}
