import '../../../../core/errors/auth_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.apiClient,
    required this.localDataSource,
    this.sessionConfig = const SessionConfig(),
  });

  final ApiClient apiClient;
  final AuthLocalDataSource localDataSource;
  final SessionConfig sessionConfig;

  UserRole _mapRole(String? role) {
    final lower = role?.toLowerCase().trim();
    if (lower == 'admin') return UserRole.admin;
    if (lower == 'warehouse') return UserRole.warehouse;
    return UserRole.viewer;
  }

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim();
    if (normalized.isEmpty || password.isEmpty) {
      throw const InvalidCredentialsFailure();
    }

    try {
      final tokenResponse = await apiClient.post(
        '/api/auth/login/json',
        body: {'username': normalized, 'password': password},
        requiresAuth: false,
      );

      final token = tokenResponse['access_token'] as String;

      final userResponse = await apiClient.get(
        '/api/auth/me',
        requiresAuth: false,
        tokenOverride: token,
      );

      final user = AppUser(
        id: userResponse['id'].toString(),
        username: userResponse['username'] as String,
        displayName: (userResponse['full_name'] as String?)?.isNotEmpty == true
            ? userResponse['full_name'] as String
            : userResponse['username'] as String,
        role: _mapRole(userResponse['role'] as String?),
      );

      final session = AuthSession(
        token: token,
        user: user,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(sessionConfig.ttl),
      );

      await localDataSource.saveSession(session);
      return session;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 400 || e.statusCode == 422) {
        throw InvalidCredentialsFailure(e.message);
      }
      throw UnexpectedAuthFailure(e.message);
    } catch (e) {
      throw UnexpectedAuthFailure('Error de conexión: $e');
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await localDataSource.readSession();
    if (session == null) return null;

    try {
      final userResponse = await apiClient.get(
        '/api/auth/me',
        tokenOverride: session.token,
      );

      final user = AppUser(
        id: userResponse['id'].toString(),
        username: userResponse['username'] as String,
        displayName: (userResponse['full_name'] as String?)?.isNotEmpty == true
            ? userResponse['full_name'] as String
            : userResponse['username'] as String,
        role: _mapRole(userResponse['role'] as String?),
      );

      return AuthSession(
        token: session.token,
        user: user,
        issuedAt: session.issuedAt,
        expiresAt: session.expiresAt,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await localDataSource.clearSession();
        return null;
      }
      return session;
    } catch (_) {
      return session;
    }
  }

  @override
  Future<void> signOut() async {
    await localDataSource.clearSession();
  }
}
