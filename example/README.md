# NextAuthClient Initialization Example

This is a minimal Flutter project demonstrating how to initialize `NextAuthClient` with proper configuration.

## 🗂️ Project Structure

```
example/
├── lib/
│   ├── main.dart                          # NextAuthClient initialization example code
│   ├── simple_dio_httpclient.dart         # Simple HTTP client implementation using Dio
│   └── providers/
│       └── google_oauth_provider.dart     # Example Google OAuth provider implementation
├── pubspec.yaml                           # Flutter project configuration, includes dio, google_sign_in and flutter_next_auth dependencies
└── README.md                              # Initialization steps and important notes
```

## 🧩 Initialization Steps

### 1. Dependencies

This example project requires `dio` (for HTTP client implementation), `google_sign_in` (for OAuth example), and `flutter_next_auth`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.1.1
  google_sign_in: ^7.2.0
  flutter_next_auth:
    path: ../../flutter_next_auth
```

Note: `dio` is not a dependency of the `flutter_next_auth` package. It's only needed in this example because the demo HTTP client implementation uses Dio. You can use any HTTP client library as long as it implements the `HttpClient` interface.

### 2. HTTP Client Implementation

You need to implement the `HttpClient` interface. It's recommended to integrate directly with Dio, as the enum items are consistent with Dio.

The `SimpleDioHttpClient` class in `lib/simple_dio_httpclient.dart` demonstrates:

- Converting `HttpClientResponseType` to Dio's `ResponseType`
- Handling HTTP options including cookies
- Implementing `get` and `post` methods

### 3. NextAuthClient Configuration

Create a `NextAuthConfig` with the following required parameters:

- **domain**: Your API domain (e.g., `'https://example.com'`)
- **authBasePath**: Authentication base path (e.g., `'/api/auth'`)
- **httpClient**: An instance implementing the `HttpClient` interface

### 4. Cookie Name Configuration

**Important**: Cookie names must match your server-side NextAuth.js configuration.

- **serverSessionCookieName**: Server-side session cookie name (optional)
  - Default value changes dynamically based on protocol:
    - HTTPS: `'__Secure-next-auth.session-token'`
    - HTTP: `'next-auth.session-token'`
  - Must be the same as the one in the server
  - **Recommended**: Specify a fixed value matching your backend configuration
- **serverCSRFTokenCookieName**: Server CSRF cookie name (optional)
  - Default value changes dynamically based on protocol:
    - HTTPS: `'__Host-next-auth.csrf-token'`
    - HTTP: `'next-auth.csrf-token'`
  - Must be the same as the one in the server
  - **Recommended**: Specify a fixed value matching your backend configuration

## 🔌 Integration into Your Project

To integrate NextAuthClient into your project:

1. Add `flutter_next_auth` to your `pubspec.yaml`
2. Implement the `HttpClient` interface (or use the provided `SimpleDioHttpClient` as a reference)
3. Create `NextAuthConfig` with your server configuration
4. Configure cookie names to match your server-side NextAuth.js configuration
5. Initialize `NextAuthClient` with the config
6. Set up event listeners for `SignedInEvent` and `SignedOutEvent` to handle jwt token storage
7. Implement OAuth providers if needed (see `lib/providers/google_oauth_provider.dart` for reference) and register them to the NextAuth instance
8. **It is recommended to directly use a state management library to integrate into your project, such as:**
  - `next_auth_riverpod` - For Riverpod integration ([https://github.com/jcyuan/flutter_next_auth_riverpod](https://github.com/jcyuan/flutter_next_auth_riverpod))
  - `next_auth_bloc` - For BLoC pattern integration ([https://github.com/jcyuan/flutter_next_auth_bloc](https://github.com/jcyuan/flutter_next_auth_bloc))

## 🛠️ Server-Side Configuration

Make sure your NextAuth.js server is configured with matching cookie names. The client-side configuration must align with:

- Cookie names (both session and CSRF tokens)
- Domain settings
- Path settings

For OAuth verification, reference the example code in `/lib/oauth_api/rout.ts` for backend implementation.

### OAuth Provider Implementation

When implementing your own OAuth provider:

1. Implement the `OAuthProvider` interface
2. The `getAuthorizationData()` method should return `OAuthAuthorizationData` containing:
  - `idToken`: The ID token from the OAuth provider (required)
    - Used as the default silent authorization method
    - Only when the idToken expires or the client OAuth package's silent login fails, will it force login to refresh the idToken
  - `authorizationCode`: The authorization code (optional, for server-side token exchange)
3. See `lib/providers/google_oauth_provider.dart` for a complete example
4. Reference `/lib/oauth_api/rout.ts` for backend verification logic

***

## ▶️ Running the Example

1. Navigate to the example directory:
  ```bash
   cd example
  ```
2. Get dependencies:
  ```bash
   flutter pub get
  ```
3. Run the example:
  ```bash
   flutter run
  ```

