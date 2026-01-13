import 'dart:io';

import 'package:flutter_next_auth/config/next_auth_config.dart';
import 'package:flutter_next_auth/core/next_auth_client.dart';
import 'package:flutter_next_auth/events/next_auth_events.dart';
import 'package:next_auth_client_example/simple_dio_httpclient.dart';

// NextAuthClient initialization example
void main() {
  // create configuration with cookie name comments
  final config = NextAuthConfig<Map<String, dynamic>>(
    domain: 'https://example.com',
    authBasePath: '/api/auth',
    httpClient: SimpleDioHttpClient(),
    // cookie name configuration notes:
    // - serverSessionCookieName: server-side session cookie name (optional)
    //   default value changes dynamically based on protocol:
    //   - HTTPS: '__Secure-next-auth.session-token'
    //   - HTTP: 'next-auth.session-token'
    //   must be the same as the one in the server
    //   recommended to specify a fixed value matching your backend configuration
    serverSessionCookieName: 'next-auth.session-token',
    // - serverCSRFTokenCookieName: server CSRF cookie name (optional)
    //   default value changes dynamically based on protocol:
    //   - HTTPS: '__Host-next-auth.csrf-token'
    //   - HTTP: 'next-auth.csrf-token'
    //   must be the same as the one in the server
    //   recommended to specify a fixed value matching your backend configuration
    serverCSRFTokenCookieName: 'next-auth.csrf-token',
  );

  final nextAuthClient = NextAuthClient<Map<String, dynamic>>(config);

  // ============================================================================
  // NextAuthClient API Reference
  // ============================================================================
  // the following APIs are consistent with the NextAuth.js client API behavior

  // Properties:
  // - config: NextAuthConfig<T> - get the configuration object
  //   example: final config = nextAuthClient.config;

  // - status: SessionStatus - get current session status (initial, loading, authenticated, unauthenticated)
  //   example: final status = nextAuthClient.status;

  // - session: T? - get current session data (null if not authenticated)
  //   example: final session = nextAuthClient.session;

  // - eventBus: EventBus - event bus for listening to authentication events
  //   available events:
  //   - SignedInEvent: fired when user signs in successfully
  //     contains accessToken (Token object with jwt token string and expiration)
  //   - SignedOutEvent: fired when user signs out
  //   - StatusChangedEvent: fired when session status changes
  //   - SessionChangedEvent: fired when session data changes
  final eventBus = nextAuthClient.eventBus;
  
  // listen to SignIn event - save jwt token for backend API authorization
  eventBus.on<SignedInEvent>().listen((event) {
    // event.accessToken is a Token object containing:
    // - token: String (jwt token string)
    // - expiration: int? (expiration timestamp in milliseconds)
    // - isValid: bool (checks if token is valid and not expired)
    // final jwtToken = event.accessToken;
    // IMPORTANT: you may save this jwtToken for backend API authorization later
  });

  // listen to SignOut event
  eventBus.on<SignedOutEvent>().listen((event) {
    // IMPORTANT: you may clear the saved jwtToken here
  });

  // Methods:
  // - recoverLoginStatusFromCache(): Future<void> - initialize session from cache, mainly for state management libraries like next_auth_riverpod/next_auth_bloc (suggested)
  //   to recover login status from cache when app booting up
  //   but it can also be called manually if needed
  // await nextAuthClient.recoverLoginStatusFromCache();

  // - refetchSession(): Future<void> - refetch session from server
  //   useful for refreshing local session data
  // await nextAuthClient.refetchSession();

  // - signIn(String provider, {...}): Future<SignInResponse> - sign in with email, credentials or OAuth
  //   provider: 'email', 'credentials', or OAuth provider id (e.g., 'google', 'apple')
  //   must be called in a user interaction context (e.g. button press, tap, etc.)
  //   returns SignInResponse with ok status and error information if failed
  // await nextAuthClient.signIn('credentials', credentialsOptions: CredentialsSignInOptions(...));
  // await nextAuthClient.signIn('email', emailOptions: EmailSignInOptions(...));
  // await nextAuthClient.signIn('google', oauthOptions: OAuthSignInOptions(...));

  // - signOut(): Future<void> - sign out current user
  //   clears session and fires SignedOutEvent
  // await nextAuthClient.signOut();

  // - updateSession(T data): Future<T?> - update session data on server
  //   returns updated session data or null if update failed
  // await nextAuthClient.updateSession({'user': {'name': 'John Doe'}});

  // - getCSRFToken({bool forceNew = false}): Future<String?> - get CSRF token
  //   forceNew: if true, force fetch a new token from server instead of using cached token
  //   returns CSRF token string or null if failed
  // final csrfToken = await nextAuthClient.getCSRFToken();
  // final newCsrfToken = await nextAuthClient.getCSRFToken(forceNew: true);

  // - setLogger(Logger logger): void - set custom logger instance
  // nextAuthClient.setLogger(MyCustomLogger());

  // - registerOAuthProvider(String providerId, OAuthProvider provider): void - register OAuth provider
  //   providerId: unique identifier for the provider (e.g., 'google', 'apple')
  //   provider: OAuthProvider implementation
  //   IMPORTANT: you need to implement your own OAuth client provider
  //   the provider is mainly used to provide idToken or authorizationCode returned from the OAuth client package (like google_sign_in
  //   , apple_sign_in, etc) for server-side verification and to return your server's session information
  //   for backend verification logic, please see the example code in /lib/oauth_api/rout.ts
  //   example: import 'package:next_auth_client_example/providers/google_oauth_provider.dart';
  //            nextAuthClient.registerOAuthProvider('google', GoogleOAuthProvider());

  // - removeOAuthProvider(String providerId): void - remove registered OAuth provider
  // nextAuthClient.removeOAuthProvider('google');

  // ============================================================================
  // State Management Libraries
  // ============================================================================
  // for state management libraries, you can currently choose between
  // - next_auth_riverpod (https://github.com/jcyuan/flutter_next_auth_riverpod)
  // - next_auth_bloc (https://github.com/jcyuan/flutter_next_auth_bloc)
  
  exit(0);
}
