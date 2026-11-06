import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final auth = Provider.of<AuthService>(context, listen: false);
    final result = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    setState(() => _isLoading = false);
    if (!result) {
      setState(() => _errorMsg = 'Invalid credentials');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMsg != null)
              Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Log In'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // TODO: navigate to sign‑up screen
              },
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
