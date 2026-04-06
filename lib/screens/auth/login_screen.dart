import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- LOGIC: FORGOT PASSWORD DIALOG ---
  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email and we will send you a reset link."),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailCtrl,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String email = resetEmailCtrl.text.trim();
              if (email.isNotEmpty) {
                String? error = await _authService.sendPasswordReset(email);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? "Reset link sent to $email"))
                  );
                }
              }
            },
            child: const Text("Send link"),
          )
        ],
      ),
    );
  }

  // --- LOGIC: GOOGLE LOGIN ---
  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    var userData = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (userData != null) {
      _navigateBasedOnRole(userData['role'] ?? 'parent');
    }
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/profile_selector');
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    var userData = await _authService.loginUser(_emailController.text.trim(), _passController.text.trim());
    setState(() => _isLoading = false);

    if (userData != null) {
      _navigateBasedOnRole(userData['role'] ?? 'parent');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 20),
              const Text("Welcome back!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog, // CONNECTED
                  child: const Text("Forgot Password?"),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: AppColors.primaryBlue),
                    onPressed: _login,
                    child: const Text("Log In", style: TextStyle(color: Colors.white)),
                  ),
              const SizedBox(height: 30),
              const Text("OR CONTINUE WITH"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialButton(Icons.g_mobiledata_rounded, Colors.red, _loginWithGoogle), // CONNECTED
                  _socialButton(Icons.apple, Colors.black, () {
                    // Logic for Apple Sign in
                  }),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: const Text("Sign up", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: 55,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
        child: Icon(icon, size: 35, color: color),
      ),
    );
  }
}