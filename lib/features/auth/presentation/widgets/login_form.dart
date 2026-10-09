import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_validators.dart';
import '../providers/auth_providers.dart';

/// Formulario de acceso.
///
/// ## Decisiones
///
/// * El error del servidor se muestra aqui, no en un `SnackBar`: el usuario
///   esta mirando el campo, no la parte superior de la pantalla.
/// * Durante el envio los campos se bloquean. Un doble toque generaba dos
///   llamadas a PBKDF2 y una excepcion de "setState tras dispose".
/// * `autofillHints` permite que el gestor de contrasenas del sistema
///   complete los campos.
/// * Tras un fallo se limpia el campo de contrasena y se devuelve el foco a el.
///   Conservar una contrasena invalida en pantalla es una mala practica.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
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

      // El cambio de estado a autenticado lo gestiona `AppRouter`. Si seguimos
      // vivos, el envio fallo en algun punto posterior.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final degraded = ref.watch(isStorageDegradedProvider);

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              enabled: !_isSubmitting,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                hintText: 'admin',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: validateUsername,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_isSubmitting,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Contrasena',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscurePassword
                      ? 'Mostrar contrasena'
                      : 'Ocultar contrasena',
                ),
              ),
              validator: validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _ErrorBanner(message: _errorMessage!),
                    ),
            ),
            if (degraded) ...[
              const SizedBox(height: AppSpacing.md),
              _DegradedStorageNotice(isDark: isDark),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : _showRegisterDialog,
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'API: fastapi.inventarios.proyecto.lol',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRegisterDialog() async {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'admin';
    bool registering = false;
    String? regError;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar nuevo usuario'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Mínimo 3 caracteres'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Correo inválido'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'warehouse',
                          child: Text('Almacén'),
                        ),
                        DropdownMenuItem(
                          value: 'viewer',
                          child: Text('Consulta'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => role = val);
                      },
                    ),
                    if (regError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        regError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: registering ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: registering
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        registering = true;
                        regError = null;
                      });
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        await apiClient.post(
                          '/api/auth/register',
                          requiresAuth: false,
                          body: {
                            'username': usernameCtrl.text.trim(),
                            'full_name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'password': passCtrl.text,
                            'role': role,
                          },
                        );

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                        _usernameController.text = usernameCtrl.text.trim();
                        _passwordController.text = passCtrl.text;
                        await _submit();
                      } catch (e) {
                        setDialogState(() {
                          registering = false;
                          regError = e.toString();
                        });
                      }
                    },
              child: registering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DegradedStorageNotice extends StatelessWidget {
  const _DegradedStorageNotice({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Almacenamiento seguro no disponible en este dispositivo. '
              'La sesion no se conservara al cerrar la app.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
