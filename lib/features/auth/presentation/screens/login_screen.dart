import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/utils/input_validators.dart';
import '../providers/auth_providers.dart';

/// Pantalla de acceso con diseño de referencia (panel de marca + formulario).
///
/// Funciona en Web, Android y Windows sin cambios.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  /// A partir de este ancho disponible se muestra el panel de marca a la
  /// izquierda; debajo se muestra solo el formulario (movil/tablet vertical).
  static const double breakpoint = 900;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showBrandPanel = constraints.maxWidth >= LoginScreen.breakpoint;

            return Row(
              children: [
                if (showBrandPanel)
                  Expanded(flex: 50, child: const _BrandPanel())
                else
                  const SizedBox.shrink(),
                Expanded(flex: 50, child: const _FormPanel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// COLORES DE REFERENCIA (muestreo real de la imagen de diseno)
// ============================================================================

const Color _kBrandBg = Color(0xFF18293D);
const Color _kGridLine = Color(0xFF2A3B4F);
const Color _kFormBg = Color(0xFF101727);
const Color _kCardBg = Color(0xFF151E2D);
const Color _kCardBorder = Color(0xFF242B3B);
const Color _kInputBg = Color(0xFF1F2E40);
const Color _kInputBorderFocus = Color(0xFF9A8E78);
const Color _kInputBorderNormal = Color(0xFF585756);
const Color _kButtonAmber = Color(0xFFED9D26);
const Color _kButtonText = Color(0xFF1F1408);
const Color _kFooterBar = Color(0xFF161E2D);
const Color _kApkButtonFill = Color(0xFF2E2821);
const Color _kApkButtonBorder = Color(0xFF9A9892);
const Color _kApkButtonText = Color(0xFFD8C9AE);

// ============================================================================
// PANEL IZQUIERDO — MARCA
// ============================================================================

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kBrandBg,
      child: Stack(
        children: [
          // Rejilla tecnica (blueprint) sobre todo el panel.
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: _kGridLine,
                spacing: 16.5,
                strokeWidth: 1.0,
              ),
            ),
          ),
          // Ilustracion tecnica de avion (detras del texto).
          Positioned.fill(child: _AirplanePainter()),

          SingleChildScrollView(
            padding: const EdgeInsets.all(70),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  // Título en 2 líneas.
                  _BrandTitle(),
                  SizedBox(height: 18),
                  // Subtítulo en 3 líneas.
                  _BrandSubtitle(),
                  SizedBox(height: 60),
                  // Lista de 4 características.
                  _FeatureList(),
                  SizedBox(height: 18),
                  // Texto inferior.
                  _BrandFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
        ),
        children: [
          TextSpan(text: 'Inventario de repuestos\n'),
          TextSpan(text: 'aeronáuticos'),
        ],
      ),
    );
  }
}

class _BrandSubtitle extends StatelessWidget {
  const _BrandSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Gestión integral de stock, trazabilidad completa de\n'
      'componentes y certificados para flotas de aviación\n'
      'comercial y militar.',
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFC0CAD6),
        height: 1.12,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contenedor del icono: cuadrado 30x30, fondo ámbar translúcido.
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF57452D).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: const Color(0xFF514A40).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 15,
                color: const Color(0xFFDEB577),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB7C0CC),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _FeatureItem(
          icon: Icons.inventory_2_outlined,
          title: 'Existencias por Pieza',
          description:
              'Estado en tiempo real y alertas de stock bajo.',
        ),
        _FeatureItem(
          icon: Icons.qr_code_2_outlined,
          title: 'Trazabilidad Total',
          description: 'Seguimiento completo de componentes y lotes.',
        ),
        _FeatureItem(
          icon: Icons.verified_outlined,
          title: 'Certificados de Conformidad',
          description:
              'Acceso y gestión de Form 8130-3 / EASA Form 1.',
        ),
        _FeatureItem(
          icon: Icons.timeline_outlined,
          title: 'Historial Detallado',
          description:
              'Registro completo de movimientos e inspecciones.',
        ),
      ],
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Entorno de demostración v1.2',
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9CA6B5),
      ),
    );
  }
}

// ============================================================================
// PANEL DERECHO — FORMULARIO
// ============================================================================

class _FormPanel extends ConsumerStatefulWidget {
  const _FormPanel();

  @override
  ConsumerState<_FormPanel> createState() => _FormPanelState();
}

class _FormPanelState extends ConsumerState<_FormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            username: _usernameController.text,
            password: _passwordController.text,
          );

      if (!mounted) return;
      _passwordController.clear();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _errorMessage = failure.message;
        _passwordController.clear();
        _isSubmitting = false;
      });
      _passwordFocus.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = describeAuthError(error);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kFormBg,
      child: Column(
        children: [
          // Body con la tarjeta centrada.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400, // tarjeta mas grande
                  ),
                  child: _LoginCard(
                    formKey: _formKey,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    passwordFocus: _passwordFocus,
                    obscurePassword: _obscurePassword,
                    isSubmitting: _isSubmitting,
                    errorMessage: _errorMessage,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _submit,
                  ),
                ),
              ),
            ),
          ),

          // Barra inferior (footer strip) solo en el panel derecho.
          _FooterBar(),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  static const double _kRadius = 11.0;
  static const double _kCardWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCardWidth,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título.
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Subtítulo.
          const Text(
            'Ingresa tus credenciales para acceder al panel de gestión.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFFB6C0CC),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 30),

          // Campo: Usuario.
          _InputLabel(text: 'Usuario'),
          const SizedBox(height: 8),
          _EmailField(
            controller: usernameController,
            focusNode: passwordFocus,
            enabled: !isSubmitting,
            errorMessage: errorMessage,
          ),
          const SizedBox(height: 20),

          // Campo: Contraseña.
          _InputLabel(text: 'Contraseña'),
          const SizedBox(height: 8),
          _PasswordField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscurePassword: obscurePassword,
            onToggle: onTogglePassword,
            enabled: !isSubmitting,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 14),

          // Fila: Recordarme + ¿Olvidaste tu contraseña?
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: isSubmitting ? null : (_) {},
                checkColor: Colors.black,
                activeColor: _kButtonAmber,
                side: const BorderSide(
                  color: Color(0xFF4C5661),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              const Text(
                'Recordarme',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF7FBFF),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: isSubmitting ? null : () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFD9BC96),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Botón Entrar con spinner de 8 puntos.
          SizedBox(
            width: double.infinity,
            height: 46,
            child: _EnterButton(
              isSubmitting: isSubmitting,
              onPressed: isSubmitting ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFFD7DFEA),
        letterSpacing: 0.2,
        height: 1.2,
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    this.errorMessage,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofillHints: const [AutofillHints.username],
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: 'admin',
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8794A8),
          letterSpacing: 0.1,
        ),
        prefixIcon: const Icon(
          Icons.person_outline,
          size: 19,
          color: Color(0xFF93A2B8),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 46,
        ),
        suffixIcon: hasError
            ? const Icon(
                Icons.error_outline,
                size: 18,
                color: Color(0xFFE03131),
              )
            : null,
        filled: true,
        fillColor: _kInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE03131) : _kInputBorderNormal,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE03131) : _kInputBorderNormal,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFE03131) : _kInputBorderFocus,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xFFE03131),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xFFE03131),
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11.5,
          color: Color(0xFFE03131),
          height: 1.3,
        ),
        errorMaxLines: 2,
      ),
      validator: validateUsername,
      onFieldSubmitted: (_) => focusNode.requestFocus(),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscurePassword,
    required this.onToggle,
    required this.enabled,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscurePassword;
  final VoidCallback onToggle;
  final bool enabled;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscurePassword,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        hintText: 'Ingresa tu contraseña',
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8794A8),
          letterSpacing: 0.1,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          size: 19,
          color: Color(0xFF93A2B8),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 46,
        ),
        suffixIcon: IconButton(
          onPressed: enabled ? onToggle : null,
          icon: Icon(
            obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 19,
            color: const Color(0xFF9EACC0),
          ),
          tooltip: obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
        filled: true,
        fillColor: _kInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: _kInputBorderNormal,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: _kInputBorderNormal,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: _kInputBorderFocus,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xFFE03131),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xFFE03131),
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11.5,
          color: Color(0xFFE03131),
          height: 1.3,
        ),
        errorMaxLines: 2,
      ),
      validator: validatePassword,
      onFieldSubmitted: onSubmitted ?? (_) {},
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kButtonAmber,
          foregroundColor: _kButtonText,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Entrando',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF1F1408),
                    ),
                  ),
                  SizedBox(width: 8),
                  _DotLoader(),
                ],
              )
            : const Text(
                'Entrar',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF1F1408),
                ),
              ),
      ),
    );
  }
}

/// Loader de 8 puntos (estilo "sunburst") sobre el botón Entrar.
class _DotLoader extends StatelessWidget {
  const _DotLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: _DotLoaderPainterWidget(),
    );  }
}

class _DotLoaderPainterWidget extends StatelessWidget {
  const _DotLoaderPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotLoaderPainter(),
      size: const Size(16, 16),
    );
  }
}

class _DotLoaderPainter extends CustomPainter {
  _DotLoaderPainter();

  static const int _dotCount = 8;
  static const double _dotSize = 2.6;
  static const double _ringRadius = 5.2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = const Color(0xFFF2A73A)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < _dotCount; i++) {
      final angle = (i * 2 * 3.14159265 / _dotCount);
      final x = center.dx + _ringRadius * cos(angle);
      final y = center.dy + _ringRadius * sin(angle);
      canvas.drawCircle(Offset(x, y), _dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(_DotLoaderPainter oldDelegate) => false;
}

// ============================================================================
// BARRA INFERIOR (footer strip) — solo panel derecho
// ============================================================================

class _FooterBar extends StatelessWidget {
  const _FooterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: _kFooterBar,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón Descargar App Android (APK) — estilo ghost/contorno.
            Container(
              width: 177,
              height: 28,
              decoration: BoxDecoration(
                color: _kApkButtonFill,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _kApkButtonBorder,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text(
                  'Descargar App Android (APK)',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: _kApkButtonText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

/// Rejilla tecnica (blueprint) con linea vertical y horizontal.
class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.color,
    required this.spacing,
    required this.strokeWidth,
  });

  final Color color;
  final double spacing;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    final xMax = size.width.ceilToDouble();
    final yMax = size.height.ceilToDouble();

    for (var x = 0.0; x <= xMax; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, yMax), paint);
    }
    for (var y = 0.0; y <= yMax; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(xMax, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color ||
      old.spacing != spacing ||
      old.strokeWidth != strokeWidth;
}

/// Ilustracion tecnica de un avion tipo plano (fuselaje, ala, bahias de carga).
/// Dibujado detras del texto del panel de marca.
class _AirplanePainter extends StatelessWidget {
  const _AirplanePainter();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _AirplanePathPainter(),
        ),
      ),
    );
  }
}

class _AirplanePathPainter extends CustomPainter {
  _AirplanePathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF2C3E52)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF57452D)
      ..style = PaintingStyle.fill;

    // Fuselaje (linea diagonal principal del avion).
    final fuselage = Path()
      ..moveTo(size.width * 0.06, size.height * 0.12)
      ..lineTo(size.width * 0.42, size.height * 0.55)
      ..lineTo(size.width * 0.52, size.height * 0.60)
      ..lineTo(size.width * 0.08, size.height * 0.48)
      ..close();
    canvas.drawPath(fuselage, linePaint);

    // Ala superior.
    final ala = Path()
      ..moveTo(size.width * 0.22, size.height * 0.38)
      ..lineTo(size.width * 0.36, size.height * 0.30)
      ..lineTo(size.width * 0.40, size.height * 0.36)
      ..lineTo(size.width * 0.26, size.height * 0.44)
      ..close();
    canvas.drawPath(ala, fillPaint);
    canvas.drawPath(ala, linePaint);

    // Ala inferior / timones.
    final timon = Path()
      ..moveTo(size.width * 0.30, size.height * 0.46)
      ..lineTo(size.width * 0.44, size.height * 0.40)
      ..lineTo(size.width * 0.48, size.height * 0.46)
      ..lineTo(size.width * 0.34, size.height * 0.52)
      ..close();
    canvas.drawPath(timon, fillPaint);
    canvas.drawPath(timon, linePaint);

    // Detalle de bahia de carga (poligono relleno).
    final bahia = Path()
      ..moveTo(size.width * 0.15, size.height * 0.58)
      ..lineTo(size.width * 0.28, size.height * 0.50)
      ..lineTo(size.width * 0.32, size.height * 0.56)
      ..lineTo(size.width * 0.19, size.height * 0.64)
      ..close();
    canvas.drawPath(bahia, fillPaint);
    canvas.drawPath(bahia, linePaint);

    // Lineas de detalle del fuselaje (ventanas/paneles).
    final detalle1 = Path()
      ..moveTo(size.width * 0.12, size.height * 0.30)
      ..lineTo(size.width * 0.24, size.height * 0.24);
    canvas.drawPath(detalle1, linePaint);

    final detalle2 = Path()
      ..moveTo(size.width * 0.16, size.height * 0.42)
      ..lineTo(size.width * 0.28, size.height * 0.36);
    canvas.drawPath(detalle2, linePaint);

    final detalle3 = Path()
      ..moveTo(size.width * 0.20, size.height * 0.54)
      ..lineTo(size.width * 0.32, size.height * 0.48);
    canvas.drawPath(detalle3, linePaint);
  }

  @override
  bool shouldRepaint(_AirplanePathPainter old) => false;
}
