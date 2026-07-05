import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/domain/secure_storage.dart';
import 'package:gestbud/shared/domain/session_state.dart';
import 'package:gestbud/shared/providers/session_provider.dart';

class FakeSecureStorage implements SecureStorage {
  final Map<String, String> _data;

  FakeSecureStorage([Map<String, String>? initial])
      : _data = Map.from(initial ?? {});

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }
}

ProviderContainer _container({Map<String, String>? storageData}) {
  return ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(
        FakeSecureStorage(storageData),
      ),
    ],
  );
}

void main() {
  group('sessionStateProvider', () {
    test('returns unauthenticated when storage is empty', () async {
      final container = _container();
      addTearDown(container.dispose);

      final state = await container.read(sessionStateProvider.future);
      expect(state, isA<SessionUnauthenticated>());
    });

    test('returns authenticated when valid token exists in storage', () async {
      final container = _container(storageData: {'session_token': 'tok_abc'});
      addTearDown(container.dispose);

      final state = await container.read(sessionStateProvider.future);
      expect(state, isA<SessionAuthenticated>());
      expect((state as SessionAuthenticated).token, 'tok_abc');
    });

    test('authenticate() stores token and transitions to authenticated', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container.read(sessionStateProvider.future);
      await container
          .read(sessionStateProvider.notifier)
          .authenticate('new_tok');

      final state = container.read(sessionStateProvider).requireValue;
      expect(state, isA<SessionAuthenticated>());
      expect((state as SessionAuthenticated).token, 'new_tok');
    });

    test('signOut() removes token and transitions to unauthenticated', () async {
      final container =
          _container(storageData: {'session_token': 'existing_tok'});
      addTearDown(container.dispose);

      await container.read(sessionStateProvider.future);
      await container.read(sessionStateProvider.notifier).signOut();

      final state = container.read(sessionStateProvider).requireValue;
      expect(state, isA<SessionUnauthenticated>());
    });
  });
}
