/// Longitud minima del identificador de usuario.
const int kMinUsernameLength = 3;

/// Longitud minima de la contrasena.
///
/// Limite de UI, no de seguridad: no evita que alguien entre con una contrasena
/// debil, solo que el formulario lo avise.
const int kMinPasswordLength = 8;

/// Valida el nombre de usuario.
///
/// Devuelve `null` (sin error) si el campo esta vacio: el error de "campo
/// obligatorio" se maneja aparte al enviar el formulario, para no mostrar
/// mensajes mientras el usuario apenas esta escribiendo.
String? validateUsername(String? value) {
  final username = value?.trim() ?? '';

  // Vacio: sin error en tiempo real (se valida al enviar).
  if (username.isEmpty) return null;

  if (username.length < kMinUsernameLength) {
    return 'Mínimo $kMinUsernameLength caracteres.';
  }
  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
    return 'Solo letras, dígitos, punto, guion y guion bajo.';
  }
  return null;
}

/// Valida la contrasena. Igual que [validateUsername]: vacio no es error
/// en tiempo real.
String? validatePassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) return null;

  if (password.length < kMinPasswordLength) {
    return 'Mínimo $kMinPasswordLength caracteres.';
  }
  return null;
}

/// Validador de campo obligatorio: solo aplica cuando el form ya fue enviado.
///
/// Se combina con los validadores de contenido para distinguir entre "vacio
/// todavia no es error" y "vacio al enviar si es error".
String? validateRequired(String? value, String fieldName) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Ingresa tu $fieldName.';
  return null;
}
