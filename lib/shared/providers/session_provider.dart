import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/flutter_secure_storage_adapter.dart';
import '../domain/secure_storage.dart';
import '../domain/session_state.dart';

const _kSessionTokenKey = 'session_token';

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => const FlutterSecureStorageAdapter(),
);

final sessionStateProvider =
    AsyncNotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

class SessionNotifier extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: _kSessionTokenKey);
    if (token == null || token.isEmpty) {
      return const SessionUnauthenticated();
    }
    return SessionAuthenticated(token: token);
  }

  Future<void> authenticate(String token) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _kSessionTokenKey, value: token);
    state = AsyncValue.data(SessionAuthenticated(token: token));
  }

  Future<void> signOut() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _kSessionTokenKey);
    state = const AsyncValue.data(SessionUnauthenticated());
  }
}
