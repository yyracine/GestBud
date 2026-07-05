import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/features/auth/repository/auth_repository.dart';
import 'package:gestbud/shared/domain/failure.dart';
import 'package:gestbud/shared/network/bff_client.dart';

class _FakeBffClient extends BffClient {
  _FakeBffClient(this._send);
  final Future<Map<String, dynamic>> Function() _send;

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? authToken,
  }) =>
      _send();
}

void main() {
  group('AuthRepository.verifyOtp', () {
    test('retourne (token, null) sur succès BFF', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async => {'token': 'session_abc123'},
        ),
      );

      final (token, failure) = await repo.verifyOtp('+22507000000', '123456');

      expect(failure, isNull);
      expect(token, 'session_abc123');
    });

    test('retourne (null, NetworkFailure) sur SocketException', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async => throw const SocketException('no network'),
        ),
      );

      final (token, failure) = await repo.verifyOtp('+22507000000', '123456');

      expect(token, isNull);
      expect(failure, isA<NetworkFailure>());
      expect(failure!.message, 'Pas de connexion réseau');
    });

    test('retourne (null, NetworkFailure) sur TimeoutException', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async => throw TimeoutException('timeout'),
        ),
      );

      final (token, failure) = await repo.verifyOtp('+22507000000', '123456');

      expect(token, isNull);
      expect(failure, isA<NetworkFailure>());
    });

    test('retourne (null, AuthFailure) avec message parsé sur BffException 400', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async => throw const BffException(
            400,
            '{"error":"Ce code a expiré. Demande-en un nouveau."}',
          ),
        ),
      );

      final (token, failure) = await repo.verifyOtp('+22507000000', '000000');

      expect(token, isNull);
      expect(failure, isA<AuthFailure>());
      expect(failure!.message, 'Ce code a expiré. Demande-en un nouveau.');
    });
  });

  group('AuthRepository.sendOtp', () {
    test('retourne null sur succès BFF', () async {
      final repo = AuthRepository(
        _FakeBffClient(() async => {'success': true}),
      );

      final result = await repo.sendOtp('+22507000000');

      expect(result, isNull);
    });

    test('retourne NetworkFailure sur SocketException', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async => throw const SocketException('no network'),
        ),
      );

      final result = await repo.sendOtp('+22507000000');

      expect(result, isA<NetworkFailure>());
      expect(result!.message, 'Pas de connexion réseau');
    });

    test('retourne NetworkFailure sur TimeoutException', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async => throw TimeoutException('timeout'),
        ),
      );

      final result = await repo.sendOtp('+22507000000');

      expect(result, isA<NetworkFailure>());
    });

    test('retourne AuthFailure sur BffException (4xx)', () async {
      final repo = AuthRepository(
        _FakeBffClient(
          () async =>
              throw const BffException(400, '{"error":"phone is required"}'),
        ),
      );

      final result = await repo.sendOtp('+22507000000');

      expect(result, isA<AuthFailure>());
    });
  });
}
