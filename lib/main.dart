import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Punto de entrada.
///
/// `ProviderScope` envuelve toda la app: da acceso al `Ref` de Riverpod y, si
/// se sobrescribe `authRepositoryProvider` aqui, permite inyectar una
/// implementacion distinta (util en tests o en modo demo).
void main() {
  runApp(const ProviderScope(child: AeroPartsApp()));
}
