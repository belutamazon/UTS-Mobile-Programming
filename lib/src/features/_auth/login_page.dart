import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoginMode = true; 
  bool _isLoading = false;

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  Future<void> _authenticate() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password cannot be empty.")),
      );
      return;
    }
    
    setState(() { _isLoading = true; });

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          String email = userCredential.user!.email ?? '';
          String username = email.split('@')[0];

          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'name': username,
            'email': email,
            'name_lower': username.toLowerCase(), 
            'bio': '',                          
            'followersCount': 0,                
            'followingCount': 0,                
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "An error occurred.")),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isLoginMode ? "Login" : "Register"),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLoginMode ? "Welcome Back!" : "Create a New Account",
              style: const TextStyle(color: AppColors.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppColors.secondaryText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondaryText)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: AppColors.secondaryText),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondaryText)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _isLoginMode ? "Login" : "Register",
                        style: const TextStyle(color: AppColors.primaryText),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _toggleMode,
              child: Text(
                _isLoginMode 
                  ? "Don't have an account? Register" 
                  : "Already have an account? Login",
                style: const TextStyle(color: AppColors.primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}