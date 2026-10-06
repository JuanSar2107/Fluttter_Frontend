import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Envoltura de `flutter_secure_storage` con respaldo en memoria.
///
/// ### Por que el respaldo
///
/// El almacenamiento seguro no esta disponible en todas partes:
///
/// * Web: requiere HTTPS y WebCrypto, ausente en navegadores antiguos.
/// * Linux: requiere `libsecret` instalado.
/// * Emuladores Android sin keystore configurado.
///
/// Sin este respaldo la app crashearia al abrir el login en uno de esos
/// entornos. El fallback es **solo en memoria**: la sesion se pierde al
/// reiniciar, que es preferible a persistir el token en texto plano.
///
/// Lo que se guarda aqui es el **token de sesion**, nunca la contrasena.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  /// Almacenamiento puramente en memoria.
  ///
  /// Para tests: los canales de plataforma no existen, y `flutter_secure_storage`
  /// acabaria cayendo al respaldoautomaticamente, ensuciando la salida con
  /// avisos y haciendo el test dependiente del fallback en vez del repositorio.
  SecureStore.inMemory() : _storage = _defaultStorage, _usingFallback = true;

  /// En v11 `AndroidOptions()` ya usa AES-GCM + RSA-OAEP por defecto.
  /// `first_unlock_this_device` evita que el token viaje en un backup a otro
  /// dispositivo.
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(dbName: 'aero_parts_secure'),
  );

  final FlutterSecureStorage _storage;

  final Map<String, String> _memory = <String, String>{};
  bool _usingFallback = false;

  /// `true` si el almacenamiento seguro no esta disponible y se esta usando el
  /// respaldo en memoria. La UI puede avisar al usuario en ese caso.
  bool get isFallbackActive => _usingFallback;

  Future<String?> read(String key) async {
    if (_usingFallback) return _memory[key];
    try {
      return await _storage.read(key: key);
    } catch (error) {
      debugPrint('SecureStore.read -> respaldo en memoria: $error');
      _usingFallback = true;
      return _memory[key];
    }
  }

  Future<void> write(String key, String value) async {
    _memory[key] = value;
    if (_usingFallback) return;
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      debugPrint('SecureStore.write -> respaldo en memoria: $error');
      _usingFallback = true;
    }
  }

  Future<void> delete(String key) async {
    _memory.remove(key);
    if (_usingFallback) return;
    try {
      await _storage.delete(key: key);
    } catch (error) {
      debugPrint('SecureStore.delete -> respaldo en memoria: $error');
      _usingFallback = true;
    }
  }

  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}

/// Token de sesion aleatorio en base64url.
///
/// Generado con `Random.secure()`. En un cliente no aporta seguridad real (el
/// atacante puede leerlo igualmente); sirve como identificador de sesion unico
/// para cuadrar con el backend cuando exista.
String generateOpaqueToken({int length = 32}) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64UrlEncode(bytes);
}
