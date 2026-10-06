/// Longitud minima del identificador de usuario.
const int kMinUsernameLength = 3;

/// Longitud minima de la contrasena.
///
/// Limite de UI, no de seguridad: no evita que alguien entre con una contrasena
/// debil, solo que el formulario lo avise. En demo se reduce a 1 para permitir
/// la contrasena '1234'.
const int kMinPasswordLength = 1;

/// Valida el nombre de usuario.
///
/// Acepta letras, digitos, punto, guion y guion bajo. Sin espacios, para que no
/// haya sorpresas al normalizar a minusculas.
String? validateUsername(String? value) {
  final username = value?.trim() ?? '';

  if (username.isEmpty) {
    return 'Ingresa tu usuario.';
  }
  if (username.length < kMinUsernameLength) {
    return 'El usuario debe tener al menos $kMinUsernameLength caracteres.';
  }
  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
    return 'Solo letras, digitos, punto, guion y guion bajo.';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return 'Ingresa tu contrasena.';
  }
  if (password.length < kMinPasswordLength) {
    return 'La contrasena debe tener al menos $kMinPasswordLength caracteres.';
  }
  return null;
}
