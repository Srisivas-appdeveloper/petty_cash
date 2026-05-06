import 'package:flutter/material.dart';
import '../main.dart';
import 'admin_screen.dart';
import 'reception_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'admin';
  final _pinController = TextEditingController();
  String? _error;

  static const _pins = {
    'admin': '1234',
    'reception1': '1111',
    'reception2': '2222',
  };

  static const _roleLabels = {
    'admin': 'Admin (Cash Allotter)',
    'reception1': 'Reception 1',
    'reception2': 'Reception 2',
  };

  void _login() {
    if (_pinController.text == _pins[_selectedRole]) {
      final screen = _selectedRole == 'admin'
          ? const AdminScreen()
          : ReceptionScreen(
              table: _selectedRole == 'reception1'
                  ? 'Reception 1'
                  : 'Reception 2',
              roleName: _roleLabels[_selectedRole]!,
            );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF16213E),
              Color(0xFF1A3A5C),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo & title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.navy, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Petty Cash',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy)),
                          Text('Management System',
                              style:
                                  TextStyle(fontSize: 12, color: AppColors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Role selector
                  _label('LOGIN AS'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.inputBorder, width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more_rounded,
                            color: AppColors.navy),
                        items: _roleLabels.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value,
                                      style: const TextStyle(
                                          fontSize: 14, color: AppColors.navy)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedRole = v!;
                            _error = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PIN
                  _label('PIN'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '• • • •',
                      hintStyle: TextStyle(
                          letterSpacing: 8, color: AppColors.grey),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _login(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],

                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login_rounded, size: 20),
                      label: const Text('Sign In'),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
          letterSpacing: 1,
        ),
      );
}
