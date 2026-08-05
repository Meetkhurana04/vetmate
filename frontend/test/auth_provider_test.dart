import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetmate/features/auth/models/auth_state.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/auth/repository/auth_repository.dart';
import 'package:vetmate/core/constants/app_constants.dart';

class MockAuthRepository extends AuthRepository {
  final Map<String, String> _storage = {};

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userRole,
    required String userName,
    required String userId,
  }) async {
    _storage['accessToken'] = accessToken;
    _storage['refreshToken'] = refreshToken;
    _storage['userRole'] = userRole;
    _storage['userName'] = userName;
    _storage['userId'] = userId;
  }

  @override
  Future<Map<String, String?>> getSession() async {
    return {
      'accessToken': _storage['accessToken'],
      'refreshToken': _storage['refreshToken'],
      'userRole': _storage['userRole'],
      'userName': _storage['userName'],
      'userId': _storage['userId'],
    };
  }

  @override
  Future<void> clearSession() async {
    _storage.clear();
  }

  @override
  Future<AuthState> login({
    required String email,
    required String password,
    required String preSelectedRole,
  }) async {
    final mockUserId = preSelectedRole == 'doctor' ? 'doc_101' : 'user_202';
    final mockUserName = preSelectedRole == 'doctor'
        ? 'Dr. Rahul Sharma'
        : 'Rahul Singh';

    await saveSession(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      userRole: preSelectedRole,
      userName: mockUserName,
      userId: mockUserId,
    );

    return AuthState(
      status: AuthStatus.authenticated,
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      userRole: preSelectedRole,
      userName: mockUserName,
      userId: mockUserId,
    );
  }

  @override
  Future<AuthState> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await saveSession(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      userRole: role,
      userName: name,
      userId: mockUserId,
    );

    return AuthState(
      status: AuthStatus.authenticated,
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      userRole: role,
      userName: name,
      userId: mockUserId,
    );
  }

  @override
  Future<AuthState?> refreshSessionToken() async {
    final session = await getSession();
    if (session['refreshToken'] != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        accessToken: 'mock_refreshed_access_token',
        refreshToken: session['refreshToken']!,
        userRole: session['userRole']!,
        userName: session['userName']!,
        userId: session['userId']!,
      );
    }
    return null;
  }
}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'Initial AuthState is unauthenticated after restoreSession with empty storage',
    () async {
      final notifier = container.read(authProvider.notifier);

      // Trigger session restore
      await notifier.restoreSession();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.accessToken, isNull);
    },
  );

  test(
    'Doctor Login updates status to authenticated and saves credentials',
    () async {
      final notifier = container.read(authProvider.notifier);

      // Login as Doctor
      await notifier.login(
        email: 'doctor@vetmate.com',
        password: '123456',
        role: AppConstants.roleDoctor,
      );

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.userName, 'Dr. Rahul Sharma');
      expect(state.userRole, AppConstants.roleDoctor);
      expect(state.userId, 'doc_101');

      // Verify written to storage mock
      final saved = await mockRepository.getSession();
      expect(saved['accessToken'], isNotNull);
      expect(saved['userRole'], AppConstants.roleDoctor);
    },
  );

  test(
    'Logout clears session credentials and sets status to unauthenticated',
    () async {
      final notifier = container.read(authProvider.notifier);

      // Setup initial login
      await notifier.login(
        email: 'user@vetmate.com',
        password: '123456',
        role: AppConstants.rolePetOwner,
      );

      // Run logout
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.accessToken, isNull);
      expect(state.userId, isNull);

      // Verify storage cleared
      final saved = await mockRepository.getSession();
      expect(saved['accessToken'], isNull);
    },
  );
}
