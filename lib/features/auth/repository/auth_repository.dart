import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/network/bff_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(bffClientProvider));
});

class AuthRepository {
  const AuthRepository(this._bff);
  final BffClient _bff;

  Future<Failure?> sendOtp(String phone) async {
    try {
      await _bff.post('/otp/send', body: {'phone': phone});
      return null;
    } on SocketException {
      return const NetworkFailure();
    } on TimeoutException {
      return const NetworkFailure();
    } on BffException catch (e) {
      return AuthFailure(e.body);
    }
  }

  Future<(String?, Failure?)> verifyOtp(String phone, String code) async {
    try {
      final res = await _bff.post(
        '/otp/verify',
        body: {'phone': phone, 'code': code},
      );
      final token = res['token'] as String;
      return (token, null);
    } on SocketException {
      return (null, const NetworkFailure());
    } on TimeoutException {
      return (null, const NetworkFailure());
    } on BffException catch (e) {
      String message;
      try {
        final parsed = jsonDecode(e.body) as Map<String, dynamic>;
        message = parsed['error'] as String? ?? e.body;
      } catch (_) {
        message = e.body;
      }
      return (null, AuthFailure(message));
    }
  }
}
