// Genera el par `salt` + `hash` para una contrasena, listo para pegar en
// `lib/features/auth/data/datasources/mock_credential_store.dart`.
//
// La contrasena NUNCA se escribe en el repositorio: solo su derivacion.
//
// Uso (recomendado, no deja la contrasena en el historial de PowerShell):
//   dart run tool/hash_password.dart
//
// Uso (util si ya la tienes en el portapapeles, pero queda en el historial):
//   dart run tool/hash_password.dart --password "MiClave"

import 'dart:convert';
import 'dart:io';

import 'package:aviation_inventory/core/security/password_hasher.dart';

void main(List<String> args) {
  final password = _readPassword(args);
  if (password == null) return;

  final hasher = const PasswordHasher();
  final salt = hasher.generateSalt();
  final hash = hasher.hash(password: password, salt: salt);

  // Verificacion de ida y vuelta para descartar errores de copia/pegado.
  final ok = hasher.matches(
    password: password,
    params: Pbkdf2Params(
      salt: salt,
      iterations: hasher.iterations,
      keyLength: hasher.keyLength,
      hash: hash,
    ),
  );
  if (!ok) {
    stderr.writeln('ERROR: la verificacion fallo, no uses esta salida.');
    exitCode = 1;
    return;
  }

  stdout
    ..writeln()
    ..writeln('// Algoritmo: $kPasswordAlgorithm')
    ..writeln('// Iteraciones: ${hasher.iterations}')
    ..writeln('// Longitud de clave: ${hasher.keyLength} bytes')
    ..writeln()
    ..writeln("final String kSalt = '$salt';")
    ..writeln("final String kPasswordHash = '$hash';")
    ..writeln()
    ..writeln('Verificacion: OK')
    ..writeln();
}

String? _readPassword(List<String> args) {
  final flagIndex = args.indexOf('--password');
  if (flagIndex != -1 && args.length > flagIndex + 1) {
    return args[flagIndex + 1];
  }

  stdout.write('Contrasena: ');
  final line = stdin.readLineSync(encoding: utf8);
  if (line == null || line.trim().isEmpty) {
    stderr.writeln('ERROR: contrasena vacia.');
    exitCode = 1;
    return null;
  }
  return line.trim();
}
