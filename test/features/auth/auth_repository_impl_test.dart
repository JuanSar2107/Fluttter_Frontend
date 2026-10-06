import 'package:aviation_inventory/core/errors/auth_failure.dart';
import 'package:aviation_inventory/core/security/password_hasher.dart';
import 'package:aviation_inventory/core/storage/secure_store.dart';
import 'package:aviation_inventory/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aviation_inventory/features/auth/data/datasources/mock_credential_store.dart';
import 'package:aviation_inventory/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aviation_inventory/features/auth/domain/entities/app_user.dart';
import 'package:aviation_inventory/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // La contrasena de la demo. En un test es aceptable que aparezca en claro:
  // aqui justamente se verifica que el hash guardado corresponde a ella.
  const demoPassword = 'Aero#Parts-2026!';

  late SecureStore store;
  late AuthLocalDataSource localDataSource;
  late DateTime now;

  setUp(() {
    // `inMemory` a proposito: los canales de plataforma de secure_storage no
    // existen en un test, y el fallback automatico haria que el test probara el
    // fallback en lugar del repositorio.
    store = SecureStore.inMemory();
    now = DateTime.now();
    localDataSource = AuthLocalDataSource(store, clock: () => now);
  });

  LocalAuthRepository buildRepository({
    Duration networkLatency = Duration.zero,
    int maxAttempts = 5,
    Duration lockoutDuration = const Duration(seconds: 30),
    SessionConfig sessionConfig = const SessionConfig(),
  }) {
    return LocalAuthRepository(
      localDataSource: localDataSource,
      networkLatency: networkLatency,
      maxAttempts: maxAttempts,
      lockoutDuration: lockoutDuration,
      sessionConfig: sessionConfig,
      clock: () => now,
    );
  }

  group('credenciales de la demo', () {
    test('el usuario se llama admin y es administrador', () {
      expect(MockCredential.admin.username, 'admin');
      expect(MockCredential.admin.role, UserRole.admin);
    });

    test('el hash guardado corresponde a la contrasena de la demo', () {
      expect(
        deriveForTest(password: demoPassword, credential: MockCredential.admin),
        isTrue,
        reason: 'Si falla, regenera las credenciales con '
            '`dart run tool/hash_password.dart`',
      );
    });

    test('el hash NO corresponde a otras contrasenas', () {
      for (final wrong in ['', 'admin', 'password', 'aero', demoPassword + 'x']) {
        expect(
          deriveForTest(password: wrong, credential: MockCredential.admin),
          isFalse,
          reason: 'la contrasena "$wrong" no deberia validar',
        );
      }
    });

    test('el hash tiene el tamano y algoritmo esperados', () {
      expect(MockCredential.admin.keyLength, 32);
      expect(MockCredential.admin.iterations, greaterThanOrEqualTo(10_000));
      expect(MockCredential.algorithm, 'pbkdf2-hmac-sha256');
    });

    test('el salt es unico por credencial', () {
      final salts = MockCredential.all.map((c) => c.salt).toSet();
      expect(salts.length, MockCredential.all.length);
    });
  });

  group('signIn con credenciales validas', () {
    test('devuelve sesion con el rol correcto', () async {
      final repository = buildRepository();

      final session = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );

      expect(session.user.username, 'admin');
      expect(session.user.role, UserRole.admin);
      expect(session.token, isNotEmpty);
      expect(session.isExpired, isFalse);
    });

    test('el usuario es case-insensitive', () async {
      final repository = buildRepository();

      for (final variant in ['admin', 'ADMIN', 'AdMiN', '  admin  ']) {
        final session = await repository.signIn(
          username: variant,
          password: demoPassword,
        );
        expect(session.user.username, 'admin', reason: 'variante: $variant');
      }
    });

    test('expira segun la configuracion de sesion', () async {
      final repository = buildRepository(
        sessionConfig: const SessionConfig(ttl: Duration(hours: 2)),
      );

      final session = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );

      expect(session.expiresAt, now.add(const Duration(hours: 2)));
    });

    test('genera un token distinto en cada inicio de sesion', () async {
      final repository = buildRepository();

      final first = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );
      final second = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );

      expect(first.token, isNot(second.token));
    });
  });

  group('signIn con credenciales invalidas', () {
    test('contrasena incorrecta lanza InvalidCredentialsFailure', () async {
      final repository = buildRepository();

      await expectLater(
        repository.signIn(username: 'admin', password: 'incorrecta'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('usuario inexistente lanza InvalidCredentialsFailure', () async {
      final repository = buildRepository();

      await expectLater(
        repository.signIn(username: 'intruso', password: demoPassword),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('no revela si el usuario existe (mismo error y mensaje)', () async {
      final repository = buildRepository();

      Object? userFail;
      Object? passFail;

      try {
        await repository.signIn(username: 'intruso', password: demoPassword);
      } catch (error) {
        userFail = error;
      }
      try {
        await repository.signIn(username: 'admin', password: 'incorrecta');
      } catch (error) {
        passFail = error;
      }

      expect(userFail.runtimeType, passFail.runtimeType);
      expect((userFail! as AuthFailure).message, (passFail! as AuthFailure).message);
    });

    test('campos vacios fallan sin lanzar error de tipo', () async {
      final repository = buildRepository();

      await expectLater(
        repository.signIn(username: '', password: demoPassword),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await expectLater(
        repository.signIn(username: 'admin', password: ''),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('no persiste sesion cuando falla', () async {
      final repository = buildRepository();

      await expectLater(
        repository.signIn(username: 'admin', password: 'incorrecta'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );

      expect(await repository.restoreSession(), isNull);
    });
  });

  group('limite de intentos', () {
    test('bloquea tras maxAttempts fallos', () async {
      final repository = buildRepository(maxAttempts: 3);

      for (var i = 0; i < 3; i++) {
        await expectLater(
          repository.signIn(username: 'admin', password: 'incorrecta'),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
      }

      // Cuarto intento: ya esta bloqueado, aunque la contrasena sea correcta.
      await expectLater(
        repository.signIn(username: 'admin', password: demoPassword),
        throwsA(isA<TooManyAttemptsFailure>()),
      );
    });

    test('el bloqueo expira y permite reintentar', () async {
      final repository = buildRepository(
        maxAttempts: 2,
        lockoutDuration: const Duration(seconds: 30),
      );

      for (var i = 0; i < 2; i++) {
        await expectLater(
          repository.signIn(username: 'admin', password: 'incorrecta'),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
      }
      await expectLater(
        repository.signIn(username: 'admin', password: demoPassword),
        throwsA(isA<TooManyAttemptsFailure>()),
      );

      // Avanza el reloj mas alla del bloqueo.
      now = now.add(const Duration(seconds: 31));

      final session = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );
      expect(session.user.username, 'admin');
    });

    test('un acierto resetea el contador', () async {
      final repository = buildRepository(maxAttempts: 3);

      // Dos fallos: cerca del limite, pero sin bloqueo.
      await expectLater(
        repository.signIn(username: 'admin', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await expectLater(
        repository.signIn(username: 'admin', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );

      // Un acierto: el contador vuelve a cero.
      await repository.signIn(username: 'admin', password: demoPassword);

      // Por tanto dos fallos mas NO bloquean, aunque en total ya sean 4.
      await expectLater(
        repository.signIn(username: 'admin', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await expectLater(
        repository.signIn(username: 'admin', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );

      expect(
        await repository.signIn(username: 'admin', password: demoPassword),
        isA<AuthSession>(),
      );
    });

    test('el mensaje incluye el tiempo restante', () async {
      final repository = buildRepository(
        maxAttempts: 1,
        lockoutDuration: const Duration(seconds: 45),
      );

      await expectLater(
        repository.signIn(username: 'admin', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await expectLater(
        repository.signIn(username: 'admin', password: demoPassword),
        throwsA(
          isA<TooManyAttemptsFailure>().having(
            (f) => f.message,
            'message',
            contains('45 s'),
          ),
        ),
      );
    });
  });

  group('persistencia de sesion', () {
    test('restoreSession devuelve la sesion guardada', () async {
      final repository = buildRepository();

      final signedIn = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );
      final restored = await repository.restoreSession();

      expect(restored, isNotNull);
      expect(restored!.token, signedIn.token);
      expect(restored.user.username, 'admin');
      expect(restored.expiresAt, signedIn.expiresAt);
    });

    test('restoreSession devuelve null si nunca hubo sesion', () async {
      expect(await buildRepository().restoreSession(), isNull);
    });

    test('una sesion expirada se descarta y borra', () async {
      final repository = buildRepository(
        sessionConfig: const SessionConfig(ttl: Duration(hours: 1)),
      );

      await repository.signIn(username: 'admin', password: demoPassword);
      expect(await repository.restoreSession(), isNotNull);

      now = now.add(const Duration(hours: 2));

      expect(await repository.restoreSession(), isNull);
      // Y no queda rastro: una segunda lectura tambien devuelve null.
      expect(await repository.restoreSession(), isNull);
    });

    test('signOut borra la sesion', () async {
      final repository = buildRepository();

      await repository.signIn(username: 'admin', password: demoPassword);
      await repository.signOut();

      expect(await repository.restoreSession(), isNull);
    });

    test('signOut limpia tambien el bloqueo de intentos', () async {
      final repository = buildRepository(maxAttempts: 1);

      await expectLater(
        repository.signIn(username: 'admin', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await expectLater(
        repository.signIn(username: 'admin', password: demoPassword),
        throwsA(isA<TooManyAttemptsFailure>()),
      );

      await repository.signOut();

      final session = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );
      expect(session.user.username, 'admin');
    });
  });

  group('validacion de endpoints', () {
    test('rechaza URLs que no son HTTPS', () {
      expect(
        LocalAuthRepository.isSecureEndpoint(Uri.parse('https://api.aeroparts.io')),
        isTrue,
      );
      expect(
        LocalAuthRepository.isSecureEndpoint(Uri.parse('http://api.aeroparts.io')),
        isFalse,
      );
    });
  });

  group('InMemoryAuthRepository', () {
    test('funciona sin almacenamiento local', () async {
      final repository = InMemoryAuthRepository();

      final session = await repository.signIn(
        username: 'admin',
        password: demoPassword,
      );
      expect(session.user.role, UserRole.admin);
      expect(await repository.restoreSession(), isNotNull);

      await repository.signOut();
      expect(await repository.restoreSession(), isNull);
    });

    test('rechaza contrasena incorrecta', () async {
      final repository = InMemoryAuthRepository();

      await expectLater(
        repository.signIn(username: 'admin', password: 'incorrecta'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });
  });
}

/// Verifica un hash usando los parametros de la credencial.
bool deriveForTest({
  required String password,
  required MockCredential credential,
}) {
  return constantTimeEquals(
    derive(
      password: password,
      salt: credential.salt,
      iterations: credential.iterations,
      keyLength: credential.keyLength,
    ),
    credential.passwordHash,
  );
}
