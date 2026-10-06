import 'package:flutter/foundation.dart';

/// Rol del usuario dentro del almacen.
enum UserRole {
  /// Acceso total.
  admin('Administrador'),

  /// Gestion de inventario sin configuracion de usuarios.
  warehouse('Almacen'),

  /// Solo lectura.
  viewer('Consulta');

  const UserRole(this.label);

  final String label;
}

/// Usuario de la aplicacion (datos de perfil, sin secretos).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;

  /// Iniciales para el avatar, ej. "AC" -> "AC".
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters1();
    return '${parts.first.characters1()}${parts.last.characters1()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.username == username &&
          other.displayName == displayName &&
          other.role == role;

  @override
  int get hashCode => Object.hash(id, username, displayName, role);

  @override
  String toString() => 'AppUser($username, ${role.name})';
}

extension on String {
  /// Primera letra en mayuscula, segura para emojis/surrogates.
  String characters1() => substring(0, 1).toUpperCase();
}
