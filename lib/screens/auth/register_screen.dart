import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Simple logic for password strength indicator
  double _strengthValue = 0;
  void _checkPasswordStrength(String value) {
    setState(() {
      if (value.isEmpty) _strengthValue = 0;
      else if (value.length < 6) _strengthValue = 0.3;
      else if (value.length < 10) _strengthValue = 0.6;
      else _strengthValue = 1.0;
    });
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      var user = await _auth.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        'parent',
      );

      if (user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!"), behavior: SnackBarBehavior.floating),
        );
        Navigator.pushReplacementNamed(context, '/parent');
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed. Please try again."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT & ACCENTS
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
          ),
          // Subtle abstract shapes
          Positioned(top: -30, left: -30, child: CircleAvatar(radius: 80, backgroundColor: Colors.indigo.withOpacity(0.03))),

          // 2. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                children: [
                  // BRANDING
                  const Icon(Icons.auto_awesome, size: 50, color: Colors.indigo),
                  const SizedBox(height: 10),
                  const Text("LittleGenius", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.indigo)),
                  const Text("Create Parent Account", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                  
                  const SizedBox(height: 30),

                  // REGISTRATION CARD
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: Colors.indigo.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFieldLabel("Email Address"),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputStyle(Icons.mail_outline),
                            validator: (v) => (v == null || !v.contains('@')) ? "Enter a valid email" : null,
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel("Password"),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: _checkPasswordStrength,
                            decoration: _inputStyle(Icons.lock_outline, isPassword: true),
                            validator: (v) => (v == null || v.length < 6) ? "Minimum 6 characters" : null,
                          ),
                          
                          // Subtle Strength Indicator
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _strengthValue,
                              backgroundColor: Colors.grey.shade100,
                              color: _strengthValue < 0.4 ? Colors.red : _strengthValue < 0.7 ? Colors.orange : Colors.green,
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildFieldLabel("Confirm Password"),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: _inputStyle(Icons.check_circle_outline),
                            validator: (v) => v != _passwordController.text ? "Passwords do not match" : null,
                          ),
                          const SizedBox(height: 30),

                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                  ),
                                  onPressed: _handleRegister,
                                  child: const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text("OR REGISTER WITH", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
                  const SizedBox(height: 15),

                  // SOCIAL BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialButton(Icons.g_mobiledata, Colors.red, "Google"),
                      const SizedBox(width: 15),
                      _socialButton(Icons.apple, Colors.black, "Apple"),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(color: Colors.blueGrey)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Login", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
    );
  }

  InputDecoration _inputStyle(IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: Colors.indigo.withOpacity(0.5)),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
      filled: true,
      fillColor: Colors.blue.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.indigo, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.red.shade200)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _socialButton(IconData icon, Color color, String label) {
    return InkWell(
      onTap: () {}, // Handle Social Sign-in Logic
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}