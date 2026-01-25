import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _register() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;
    
    // 2. Check Terms
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the Terms of Service")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 3. Logic: Firebase Registration
    String? error = await _authService.registerUser(
      _emailController.text.trim(), 
      _passController.text.trim()
    );

    setState(() => _isLoading = false);

    if (error == null) {
      if (!mounted) return;
      // Show success and move to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Created! Welcome to the family."),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.pop(context); 
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                "Welcome, Parent!",
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.primaryBlue
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create a secure account to track your child's progress and manage settings.",
                style: TextStyle(fontSize: 16, color: Colors.blueGrey, height: 1.4),
              ),
              
              const SizedBox(height: 40),

              // --- EMAIL FIELD ---
              _buildLabel("Parent's Email"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(Icons.email_outlined, "example@email.com"),
                validator: (v) => (v == null || !v.contains('@')) ? "Enter a valid email" : null,
              ),

              const SizedBox(height: 20),

              // --- PASSWORD FIELD ---
              _buildLabel("Create Password"),
              TextFormField(
                controller: _passController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  Icons.lock_outline, 
                  "••••••••",
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? "Minimum 6 characters" : null,
              ),

              const SizedBox(height: 20),

              // --- CONFIRM PASSWORD ---
              _buildLabel("Confirm Password"),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: _inputDecoration(Icons.lock_reset_rounded, "••••••••"),
                validator: (v) => v != _passController.text ? "Passwords do not match" : null,
              ),

              const SizedBox(height: 20),

              // --- TERMS CHECKBOX ---
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms, 
                    activeColor: AppColors.primaryBlue,
                    onChanged: (v) => setState(() => _agreeToTerms = v!),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the Terms of Service and Privacy Policy",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- SIGN UP BUTTON ---
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 65),
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    onPressed: _register,
                    child: const Text(
                      "Start Learning", 
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),

              const SizedBox(height: 30),

              // --- FOOTER ---
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 15, fontFamily: 'Poppins'),
                      children: [
                        const TextSpan(text: "Already have an account? "),
                        TextSpan(
                          text: "Log in", 
                          style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}