# flutter_next_auth

This is a Flutter client library for **quickly integrating with NextAuth v4.x backend authorization APIs**.

It wraps common NextAuth client capabilities (`csrf` / `session` / `signin` / `signout` / custom `oauth`) into a Flutter-friendly `NextAuthClient`, and provides local token/cookie recovery so you can plug an existing NextAuth backend into mobile apps with minimal glue code.

- Sign in (`email` / `credentials` / custom OAuth provider)
- Fetch / refresh session
- Local token/cookie recovery (via `flutter_secure_storage`)
- Event notifications (`eventBus`: SignedIn/SignedOut/StatusChanged/SessionChanged)

> Note: this package only defines an abstract `HttpClient`. You must implement it in your app (using `dio`, `http`, etc).

---

## 📦 Installation

### Option 1: Add via CLI (recommended)

```bash
flutter pub add flutter_next_auth
```

### Option 2: Edit `pubspec.yaml` manually

```yaml
dependencies:
  flutter_next_auth: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 📥 Import

```dart
import 'package:flutter_next_auth/next_auth.dart';
```

---

## 🧪 Example (minimal)

See `/example` (a runnable Flutter app):

- **How to run**: `example/README.md`
- **Entry**: `example/lib/main.dart`
- **Dio HttpClient**: `example/lib/simple_dio_httpclient.dart`
- **Google OAuth provider example**: `example/lib/providers/google_oauth_provider.dart`
- **OAuth backend verification / code-exchange example**: `example/lib/oauth_api/route.ts`

---

## ⚠️ Notes

- **Cookie names must match your backend**: `NextAuthConfig.serverSessionCookieName` / `serverCSRFTokenCookieName` must match the cookie names configured on your NextAuth server.
- **Recover session on app start**: call `client.recoverLoginStatusFromCache()` to restore tokens from secure storage and attempt to fetch session (recommended: use the integrated state management libraries below).
- **OAuth provider ids**: for OAuth sign-in, implement your own `OAuthProvider` and register it on `NextAuthClient` (see the full example under `example/`).

---

## 🧠 Recommended state management libraries

Strongly recommended for real projects. They wire `NextAuthClient` **session/status changes** into your app state so you don’t have to hand-roll listeners and synchronization.

- Call `recoverLoginStatusFromCache()` on app startup to attempt session recovery
- Listen to `eventBus` (SignedIn/SignedOut/StatusChanged/SessionChanged)
- Expose auth state to UI (Provider / BLoC state) and centralize side-effects (recover, refetch session, sign out, etc)

**Riverpod integration**: [https://github.com/jcyuan/flutter_next_auth_riverpod](https://github.com/jcyuan/flutter_next_auth_riverpod)  
**BLoC integration**: [https://github.com/jcyuan/flutter_next_auth_bloc](https://github.com/jcyuan/flutter_next_auth_bloc)

---

## 📚 NextAuthClient API Reference

The following APIs are consistent with the NextAuth.js client API behavior.

### Properties

- **config**: `NextAuthConfig<T>` - Get the configuration object
  ```dart
  final config = nextAuthClient.config;
  ```
- **status**: `SessionStatus` - Get current session status
  - Possible values: `initial`, `loading`, `authenticated`, `unauthenticated`
  ```dart
  final status = nextAuthClient.status;
  ```
- **session**: `T?` - Get current session data (null if not authenticated)
  ```dart
  final session = nextAuthClient.session;
  ```
- **eventBus**: `EventBus` - Event bus for listening to authentication events
  - Available events:
    - `SignedInEvent`: Fired when user signs in successfully
      - Contains `accessToken` (Token object with jwt token string and expiration)
      - **IMPORTANT**: Save the jwt token from `event.accessToken.token` for backend API authorization
    - `SignedOutEvent`: Fired when user signs out
    - `StatusChangedEvent`: Fired when session status changes
    - `SessionChangedEvent`: Fired when session data changes

### Event Handling

Listen to authentication events:

```dart
final eventBus = nextAuthClient.eventBus;

// Listen to SignIn event - save jwt token for backend API authorization
eventBus.on<SignedInEvent>().listen((event) {
  // event.accessToken is a Token object containing:
  // - token: String (jwt token string)
  // - expiration: int? (expiration timestamp in milliseconds)
  // - isValid: bool (checks if token is valid and not expired)
  final jwtToken = event.accessToken.token;
  // IMPORTANT: Save this jwtToken to secure storage for later use with your backend API
});

// Listen to SignOut event
eventBus.on<SignedOutEvent>().listen((event) {
  // IMPORTANT: Clear the saved jwtToken here
});
```

### Methods

- **recoverLoginStatusFromCache()**: `Future<void>` - Initialize session from cache
  - Mainly for state management libraries like `next_auth_riverpod`/`next_auth_bloc` (suggested)
  - To recover login status from cache when app booting up
  - Can also be called manually if needed
  ```dart
  await nextAuthClient.recoverLoginStatusFromCache();
  ```
- **refetchSession()**: `Future<void>` - Refetch session from server
  - Useful for refreshing local session data
  ```dart
  await nextAuthClient.refetchSession();
  ```
- **signIn(String provider, {...})**: `Future<SignInResponse>` - Sign in with email, credentials or OAuth
  - `provider`: `'email'`, `'credentials'`, or OAuth provider id (e.g., `'google'`, `'apple'`)
  - **Must be called in a user interaction context** (e.g. button press, tap, etc.)
  - Returns `SignInResponse` with `ok` status and error information if failed
  ```dart
  await nextAuthClient.signIn('credentials', credentialsOptions: CredentialsSignInOptions(...));
  await nextAuthClient.signIn('email', emailOptions: EmailSignInOptions(...));
  await nextAuthClient.signIn('google', oauthOptions: OAuthSignInOptions(...));
  ```
- **signOut()**: `Future<void>` - Sign out current user
  - Clears session and fires `SignedOutEvent`
  ```dart
  await nextAuthClient.signOut();
  ```
- **updateSession(T data)**: `Future<T?>` - Update session data on server
  - Returns updated session data or null if update failed
  ```dart
  await nextAuthClient.updateSession({'user': {'name': 'John Doe'}});
  ```
- **getCSRFToken({bool forceNew = false})**: `Future<String?>` - Get CSRF token
  - `forceNew`: If true, force fetch a new token from server instead of using cached token
  - Returns CSRF token string or null if failed
  ```dart
  final csrfToken = await nextAuthClient.getCSRFToken();
  final newCsrfToken = await nextAuthClient.getCSRFToken(forceNew: true);
  ```
- **setLogger(Logger logger)**: `void` - Set custom logger instance
  ```dart
  nextAuthClient.setLogger(MyCustomLogger());
  ```
- **registerOAuthProvider(String providerId, OAuthProvider provider)**: `void` - Register OAuth provider
  - `providerId`: Unique identifier for the provider (e.g., `'google'`, `'apple'`)
  - `provider`: OAuthProvider implementation
  - **IMPORTANT**: You need to implement your own OAuth client provider
  - The provider is mainly used to provide `idToken` or `authorizationCode` returned from the OAuth client package (like `google_sign_in`, `apple_sign_in`, etc) for server-side verification and to return your server's session information
  - For backend verification logic, please see the example code in `/lib/oauth_api/rout.ts`
  ```dart
  import 'package:next_auth_client_example/providers/google_oauth_provider.dart';
  nextAuthClient.registerOAuthProvider('google', GoogleOAuthProvider());
  ```
- **removeOAuthProvider(String providerId)**: `void` - Remove registered OAuth provider
  ```dart
  nextAuthClient.removeOAuthProvider('google');
  ```

## ⚠️ Important Notes

### Cookie Name Matching

The cookie names configured in `NextAuthConfig` must exactly match your server-side NextAuth.js configuration. Mismatched cookie names will cause authentication failures.

Example server-side NextAuth.js configuration:

```javascript
export default NextAuth({
  cookies: {
    sessionToken: {
      name: 'next-auth.session-token', // or your custom name
      options: {
        // cookie options
      }
    },
    csrfToken: {
      name: 'next-auth.csrf-token', // or your custom name
      options: {
        // cookie options
      }
    }
  }
})
```
