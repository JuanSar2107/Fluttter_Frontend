import 'package:flutter/foundation.dart';

import 'app_user.dart';

/// Sesion activa del usuario.
///
/// Contiene un token opaco y su expiracion. Nunca la contrasena.
@immutable
class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String token;
  final AppUser user;
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// `true` si la sesion ya paso su fecha de expiracion.
  ///
  /// Recibe el instante actual por parametro en vez de llamar a
  /// `DateTime.now()` dentro. Asi el reloj queda inyectable y los tests pueden
  /// simular el paso del tiempo sin esperar horas.
  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);

  bool get isExpired => isExpiredAt(DateTime.now());

  /// Tiempo restante, o `Duration.zero` si ya expiro.
  Duration remainingAt(DateTime now) {
    if (isExpiredAt(now)) return Duration.zero;
    return expiresAt.difference(now);
  }

  Duration get remaining => remainingAt(DateTime.now());

  @override
  String toString() =>
      'AuthSession(${user.username}, expira ${expiresAt.toIso8601String()})';
}

/// Configuracion de la sesion.
class SessionConfig {
  const SessionConfig({this.ttl = const Duration(hours: 8)});

  /// Tiempo de vida de la sesion.
  final Duration ttl;
}
