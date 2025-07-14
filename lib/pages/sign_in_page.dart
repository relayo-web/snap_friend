import 'package:flutter/material.dart';
import 'package:snap_friend/services/auth_service.dart';

class SignInPage extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignedIn;

  const SignInPage({
    super.key,
    required this.authService,
    required this.onSignedIn,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isRegister) {
        await widget.authService.registerWithEmail(email: email, password: password);
      } else {
        await widget.authService.signInWithEmail(email: email, password: password);
      }

      widget.onSignedIn(); // ログイン成功後のコールバック
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ エラー: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? '新規登録' : 'ログイン'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: Text(_isRegister ? '登録する' : 'ログイン'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister
                  ? 'ログインに切り替える'
                  : 'アカウントをお持ちでない方はこちら'),
            ),
          ],
        ),
      ),
    );
  }
}
