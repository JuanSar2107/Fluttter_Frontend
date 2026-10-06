import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Espaciado y radios usados en toda la app.
///
/// Centralizarlo evita que cada pantalla invente sus propias medidas.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Tema de la aplicacion.
///
/// Se apoya en `ColorScheme` en lugar de fijar colores en cada widget, para
/// que el modo oscuro funcione sin condicionales por pantalla.
class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Roboto';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.amber : AppColors.navy,
      onPrimary: isDark ? AppColors.navyDeep : Colors.white,
      primaryContainer: isDark ? AppColors.navyLight : AppColors.navy,
      onPrimaryContainer: isDark ? Colors.white : Colors.white,
      secondary: AppColors.amber,
      onSecondary: AppColors.navyDeep,
      secondaryContainer: isDark ? AppColors.steel : AppColors.amber,
      onSecondaryContainer: isDark ? AppColors.navyDeep : AppColors.navyDeep,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: isDark
          ? AppColors.danger.withValues(alpha: 0.20)
          : AppColors.danger.withValues(alpha: 0.10),
      onErrorContainer: isDark ? const Color(0xFFFFB4B4) : const Color(0xFF7A1010),
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      onSurfaceVariant:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      outline: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      outlineVariant:
          isDark ? AppColors.dividerDark : AppColors.dividerLight,
      surfaceContainerHighest:
          isDark ? AppColors.canvasDark : AppColors.canvasLight,
      inverseSurface: isDark ? AppColors.navyDeep : AppColors.navy,
      onInverseSurface: isDark ? AppColors.textPrimaryDark : Colors.white,
      inversePrimary: isDark ? AppColors.navyLight : AppColors.amber,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor:
          isDark ? AppColors.canvasDark : AppColors.canvasLight,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: _inputTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(base.textTheme, isDark),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(scheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.amber : AppColors.navy,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.amber : AppColors.navy,
        linearTrackColor: scheme.outline,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static TextTheme _textTheme(TextTheme base, bool isDark) {
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return base
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: primary,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: primary,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: primary,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: primary,
          ),
          bodyLarge: base.bodyLarge?.copyWith(color: primary, height: 1.45),
          bodyMedium: base.bodyMedium?.copyWith(color: secondary, height: 1.45),
          bodySmall: base.bodySmall?.copyWith(color: secondary, height: 1.4),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: primary, displayColor: primary);
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: 1.2),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.brightness == Brightness.dark
          ? AppColors.canvasDark
          : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      focusedBorder: border(scheme.primary),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      errorStyle: TextStyle(
        color: scheme.error,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }

  static ButtonStyle _filledButtonStyle(TextTheme textTheme, bool isDark) {
    final base = textTheme.labelLarge?.copyWith(
      fontSize: 15,
      letterSpacing: 0.2,
    );

    return ButtonStyle(
      // `Size.fromHeight(52)` daria `width: Infinity` y reventaria cualquier
      // boton colocado dentro de un `Row`. Un tamano minimo con altura fija y
      // ancho minimo pequeno deja que el boton crezca solo a lo ancho.
      minimumSize: const WidgetStatePropertyAll(Size(120, 52)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return (isDark ? AppColors.steel : AppColors.textSecondaryLight)
              .withValues(alpha: 0.4);
        }
        return isDark ? AppColors.amber : AppColors.navy;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return (isDark ? AppColors.navyDeep : Colors.white).withValues(alpha: 0.6);
        }
        return isDark ? AppColors.navyDeep : Colors.white;
      }),
      textStyle: WidgetStatePropertyAll(base),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      overlayColor: WidgetStatePropertyAll(
        Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  static ButtonStyle _outlinedButtonStyle(ColorScheme scheme) {
    return ButtonStyle(
      // Mismo motivo que en el boton primario: nada de `Size.fromHeight`.
      minimumSize: const WidgetStatePropertyAll(Size(120, 48)),
      foregroundColor: WidgetStatePropertyAll(scheme.primary),
      side: WidgetStatePropertyAll(BorderSide(color: scheme.outline, width: 1.4)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
    );
  }
}
