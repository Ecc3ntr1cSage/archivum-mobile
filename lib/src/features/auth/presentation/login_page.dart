import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  void _login() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login pressed (UI only)')));
  }

  void _sso(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SSO: $provider (UI only)')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextFormField(controller: _email, decoration: const InputDecoration(hintText: 'Email')),
          const SizedBox(height: 8),
          TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(hintText: 'Password')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _login, child: const Text('Sign in')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ElevatedButton(onPressed: () => _sso('google'), child: const Text('Google')),
            ElevatedButton(onPressed: () => _sso('github'), child: const Text('GitHub')),
            ElevatedButton(onPressed: () => _sso('facebook'), child: const Text('Facebook')),
          ])
        ],
      ),
    );
  }
}
