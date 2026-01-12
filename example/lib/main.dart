import 'package:flutter/material.dart';
import 'package:flutter_next_auth/next_auth.dart';

import 'dio_http_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_next_auth example',
      home: const AuthDemoPage(),
    );
  }
}

class AuthDemoPage extends StatefulWidget {
  const AuthDemoPage({super.key});

  @override
  State<AuthDemoPage> createState() => _AuthDemoPageState();
}

class _AuthDemoPageState extends State<AuthDemoPage> {
  late final NextAuthClient<Map<String, dynamic>> client;

  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: '123456');
  final _turnstileController = TextEditingController(text: 'your-turnstile-token');

  String logText = '';

  @override
  void initState() {
    super.initState();

    client = NextAuthClient<Map<String, dynamic>>(
      NextAuthConfig<Map<String, dynamic>>(
        // TODO: Replace with your NextAuth server domain.
        domain: 'https://your-nextauth-domain.com',
        // authBasePath: '/api/auth', // default
        httpClient: DioHttpClient(),

        // TODO: ⚠️ These cookie names MUST match your server.
        serverSessionCookieName: '__Secure-authjs.session-token',
        serverCSRFTokenCookieName: '__Host-authjs.csrf-token',
      ),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await client.recoverLoginStatusFromCache();
    _refreshLog('bootstrap');
  }

  void _refreshLog(String from) {
    setState(() {
      logText = '[$from]\n'
          'status=${client.status}\n'
          'session=${client.session}\n';
    });
  }

  Future<void> _signInCredentials() async {
    final resp = await client.signIn(
      'credentials',
      credentialsOptions: CredentialsSignInOptions(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        turnstileToken: _turnstileController.text.trim(),
      ),
    );

    setState(() {
      logText = '[signIn]\n'
          'ok=${resp.ok}, status=${resp.status}, error=${resp.error?.code}\n'
          'session=${client.session}\n';
    });
  }

  Future<void> _refetchSession() async {
    await client.refetchSession();
    _refreshLog('refetchSession');
  }

  Future<void> _signOut() async {
    await client.signOut();
    _refreshLog('signOut');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _turnstileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_next_auth example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _turnstileController,
            decoration: const InputDecoration(labelText: 'Turnstile token'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _signInCredentials,
            child: const Text('Sign in (credentials)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _refetchSession,
            child: const Text('Refetch session'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _signOut,
            child: const Text('Sign out'),
          ),
          const SizedBox(height: 16),
          const Text('Log'),
          const SizedBox(height: 8),
          SelectableText(logText),
        ],
      ),
    );
  }
}

