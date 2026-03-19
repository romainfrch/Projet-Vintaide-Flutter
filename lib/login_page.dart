import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'session.dart';

class LoginPage extends StatefulWidget {
  final String appName;

  const LoginPage({super.key, required this.appName});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  void _setError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _onLogin() async {
    final login = _loginCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Champs vides -> message générique (sécurisé)
      if (login.isEmpty || password.isEmpty) {
        debugPrint('[LOGIN] Champs vides');
        _setError('Utilisateur ou mot de passe incorrect.');
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(login).get();

      if (!doc.exists) {
        debugPrint('[LOGIN] Utilisateur inexistant: $login');
        _setError('Utilisateur ou mot de passe incorrect.');
        return;
      }

      final dbPassword = doc.data()?['password'];

      if (dbPassword == password) {
        debugPrint('[LOGIN] Connexion OK: $login');
        Session.setLogin(login); // ✅ on mémorise l’utilisateur connecté

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home'); // ✅ vers US#2
      } else {
        debugPrint('[LOGIN] Mot de passe incorrect pour: $login');
        _setError('Utilisateur ou mot de passe incorrect.');
      }
    } catch (e) {
      debugPrint('[LOGIN] Erreur technique: $e');
      _setError('Erreur technique. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);

    return Scaffold(
      // ✅ HeaderBar : bleu #11114E + logo centré
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 76,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final logoW = (maxW * 0.40).clamp(120.0, 220.0);

            return Image.asset(
              'assets/logo.png',
              width: logoW,
              fit: BoxFit.contain,
            );
          },
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _loginCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Login',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onLogin,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
