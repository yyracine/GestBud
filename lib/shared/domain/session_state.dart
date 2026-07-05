sealed class SessionState {
  const SessionState();
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();

  @override
  bool operator ==(Object other) => other is SessionUnauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({required this.token});

  final String token;

  @override
  bool operator ==(Object other) =>
      other is SessionAuthenticated && other.token == token;

  @override
  int get hashCode => token.hashCode;
}
