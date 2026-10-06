import 'package:flutter/foundation.dart';

/// Fallos de autenticacion.
///
/// Son tipos cerrados a proposito: la capa de presentacion decide como
/// mostrarlos, y asi evitamos filtrar mensajes internos del backend
/// directamente a la UI.
@immutable
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  /// Texto seguro para mostrar al usuario.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Credenciales incorrectas.
///
/// Se usa tambien cuando el usuario no existe, para no revelar que cuentas
/// estan registradas.
final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Usuario o contrasena incorrectos.',
  ]);
}

/// Demasiados intentos fallidos: cuenta bloqueada temporalmente.
///
/// No es `const` a proposito: el mensaje depende de un calculo con los
/// segundos restantes, que no puede resolverse en tiempo de compilacion.
final class TooManyAttemptsFailure extends AuthFailure {
  TooManyAttemptsFailure(this.secondsRemaining)
      : super('Demasiados intentos fallidos. Intenta de nuevo en '
            '${_formatSeconds(secondsRemaining)}.');

  final int secondsRemaining;

  static String _formatSeconds(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }
}

/// La sesion guardada ya no es valida.
final class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure() : super('Tu sesion expiro. Vuelve a entrar.');
}

/// Problema de almacenamiento seguro (Keychain / Keystore / WebCrypto).
final class SecureStorageFailure extends AuthFailure {
  const SecureStorageFailure([
    super.message = 'No se pudo acceder al almacenamiento seguro del '
        'dispositivo.',
  ]);
}

/// Fallo inesperado de la capa de datos.
final class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure([
    super.message = 'Ocurrio un error inesperado. Intenta de nuevo.',
  ]);
}
