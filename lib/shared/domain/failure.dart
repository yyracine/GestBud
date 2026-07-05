sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure() : super('Pas de connexion réseau');
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}
