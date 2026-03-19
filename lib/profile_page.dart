import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'session.dart';
import 'widgets/vintaide_app_bar.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _passwordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  DateTime? _birthday;

  bool _loading = true;
  bool _saving = false;

  String get _login => Session.currentLogin ?? '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_login.isEmpty) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    _postalCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_login).get();

      if (!doc.exists) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      _passwordCtrl.text = (data['password'] ?? '').toString();
      _addressCtrl.text = (data['address'] ?? '').toString();
      _postalCtrl.text = (data['postalCode'] ?? '').toString();
      _cityCtrl.text = (data['city'] ?? '').toString();

      final b = data['birthday'];
      if (b is Timestamp) _birthday = b.toDate();

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    await FirebaseFirestore.instance.collection('users').doc(_login).set({
      'password': _passwordCtrl.text,
      'address': _addressCtrl.text.trim(),
      'postalCode': _postalCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'birthday': _birthday == null ? null : Timestamp.fromDate(_birthday!),
    }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil mis à jour ✅')),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 18);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) setState(() => _birthday = picked);
  }

  void _logout() {
    Session.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF11114E);

    return Scaffold(
      appBar: const VintaideAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil',
                    style: TextStyle(
                      color: primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _login,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Login'),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 16),

                          InkWell(
                            onTap: _pickBirthday,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Anniversaire'),
                              child: Row(
                                children: [
                                  Text(_formatDate(_birthday)),
                                  const Spacer(),
                                  Icon(Icons.calendar_today, size: 18, color: primary.withOpacity(0.8)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(labelText: 'Adresse'),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _postalCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Code postal'),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(labelText: 'Ville'),
                          ),
                          const SizedBox(height: 18),

                          // ✅ US#6 : bouton depuis profil
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pushNamed('/add'),
                              style: ButtonStyle(
                                side: MaterialStateProperty.all(
                                  BorderSide(color: primary.withOpacity(0.7)),
                                ),
                                foregroundColor: MaterialStateProperty.all(primary),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              child: const Text('Ajouter un nouveau vêtement'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveProfile,
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Valider'),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _logout,
                              style: ButtonStyle(
                                side: MaterialStateProperty.all(const BorderSide(color: Colors.red)),
                                backgroundColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.hovered)) return Colors.red;
                                  return Colors.white;
                                }),
                                foregroundColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.hovered)) return Colors.white;
                                  return Colors.red;
                                }),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              child: const Text(
                                'Se déconnecter',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
