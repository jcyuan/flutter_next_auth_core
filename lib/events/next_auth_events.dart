import 'package:flutter_next_auth_core/cache/token.dart';
import 'package:flutter_next_auth_core/models/session_status.dart';

/// Base class for all NextAuth events
abstract class NextAuthEvent {}

/// Event fired when user signs in successfully
class SignedInEvent extends NextAuthEvent {
  final Token accessToken;

  SignedInEvent(this.accessToken);
}

/// Event fired when user signs out
class SignedOutEvent extends NextAuthEvent {}

/// Event fired when session status changes
class StatusChangedEvent extends NextAuthEvent {
  final SessionStatus status;

  StatusChangedEvent(this.status);
}

/// Event fired when session data changes
class SessionChangedEvent<T> extends NextAuthEvent {
  final T? session;

  SessionChangedEvent(this.session);
}
