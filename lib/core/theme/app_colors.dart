import 'package:flutter/material.dart';

/// Paleta de la aplicacion.
///
/// inspired en instrumentos de cabina: azul profundo (fuselaje) con acento
/// ambar (luces de navegacion) y verde auxiliar (estado nominal).
class AppColors {
  const AppColors._();

  // Marca
  static const Color navy = Color(0xFF0B2239);
  static const Color navyDeep = Color(0xFF061524);
  static const Color navyLight = Color(0xFF16385A);
  static const Color steel = Color(0xFF2C4A69);

  /// Acento principal.
  static const Color amber = Color(0xFFFF9F1C);
  static const Color amberDark = Color(0xFFD97B00);

  /// Estados.
  static const Color success = Color(0xFF12B886);
  static const Color danger = Color(0xFFE03131);
  static const Color warning = Color(0xFFF59F00);
  static const Color info = Color(0xFF1C7ED6);

  // Superficies
  static const Color canvasLight = Color(0xFFF4F6F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE3E8EF);
  static const Color textPrimaryLight = Color(0xFF1A2231);
  static const Color textSecondaryLight = Color(0xFF64748B);

  static const Color canvasDark = Color(0xFF0A1522);
  static const Color surfaceDark = Color(0xFF12212F);
  static const Color dividerDark = Color(0xFF22384C);
  static const Color textPrimaryDark = Color(0xFFE8EEF5);
  static const Color textSecondaryDark = Color(0xFF93A5B8);

  /// Degradado del panel de marca.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDeep, navy, navyLight],
  );

  /// Degradado del boton primario.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [amberDark, amber],
  );
}
