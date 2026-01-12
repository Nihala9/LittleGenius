import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Corrected path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("LittleGenius Login"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.auto_awesome, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text("Welcome Back!", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const Text("Sign in to continue your adventure", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController, 
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), 
                obscureText: true
              ),
              const SizedBox(height: 30),
              
              _isLoading 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleLogin,
                    child: const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
              
              const SizedBox(height: 30),
              const Divider(),
              TextButton(
                onPressed: () => _handleTestAccount('admin'), 
                child: const Text("Create Test Admin Account")
              ),
              TextButton(
                onPressed: () => _handleTestAccount('parent'), 
                child: const Text("Create Test Parent Account")
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleTestAccount(String role) async {
    await _auth.signUp(_emailController.text, _passwordController.text, role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$role Account Created! Now click Log In."))
      );
    }
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    var user = await _auth.login(_emailController.text, _passwordController.text);
    
    if (user != null) {
      String role = await _auth.getUserRole(user.uid);
      if (!mounted) return;

      // Using Named Routes from main.dart
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/parent');
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed. Check your email/password."))
        );
      }
    }
  }
}