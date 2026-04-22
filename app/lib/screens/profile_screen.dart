import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onUserUpdated;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showPassword = false;
  bool _showPasswordConfirm = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.user['last_name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });

    final body = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      if (_passwordController.text.isNotEmpty) ...{
        'current_password': _currentPasswordController.text,
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmController.text,
      },
    };

    final result = await _authService.updateProfile(body);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _currentPasswordController.clear();
      _passwordController.clear();
      _passwordConfirmController.clear();
      widget.onUserUpdated(result['user']);
      setState(() => _successMessage = 'Profil bol úspešne uložený.');
    } else {
      setState(() => _errorMessage = result['error'] ?? 'Chyba pri ukladaní.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 80, color: Colors.indigo),
                  const SizedBox(height: 8),
                  Text(
                    widget.user['name'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.user['email'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _sectionTitle('Osobné údaje'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _firstNameController,
                    label: 'Meno',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Povinné pole' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _lastNameController,
                    label: 'Priezvisko',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Povinné pole' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildField(
              controller: _emailController,
              label: 'E-mail',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Povinné pole';
                if (!v.contains('@')) return 'Neplatný e-mail';
                return null;
              },
            ),
            const SizedBox(height: 28),

            _sectionTitle('Zmena hesla'),
            const SizedBox(height: 4),
            const Text(
              'Vyplňte len ak chcete zmeniť heslo.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),

            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Aktuálne heslo',
              show: _showCurrentPassword,
              onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
              validator: (v) {
                if (_passwordController.text.isNotEmpty && (v == null || v.isEmpty)) {
                  return 'Zadajte aktuálne heslo';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            _buildPasswordField(
              controller: _passwordController,
              label: 'Nové heslo',
              show: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length < 6) {
                  return 'Heslo musí mať aspoň 6 znakov';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            _buildPasswordField(
              controller: _passwordConfirmController,
              label: 'Potvrdenie nového hesla',
              show: _showPasswordConfirm,
              onToggle: () => setState(() => _showPasswordConfirm = !_showPasswordConfirm),
              validator: (v) {
                if (_passwordController.text.isNotEmpty && v != _passwordController.text) {
                  return 'Heslá sa nezhodujú';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('Uložiť zmeny'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo),
        ),
      ),
    );
  }
}