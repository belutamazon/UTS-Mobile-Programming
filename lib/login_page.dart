import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // BARU: Variabel untuk mengontrol mode (login atau register)
  bool _isLoginMode = true; 
  bool _isLoading = false;

  // BARU: Fungsi untuk beralih mode
  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  // DIUBAH: Satu fungsi untuk menangani login dan register
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
        // Mode Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Mode Register
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
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
      backgroundColor: Colors.black,
      // DIUBAH: Judul AppBar berubah sesuai mode
      appBar: AppBar(title: Text(_isLoginMode ? "Login" : "Register")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLoginMode ? "Welcome Back!" : "Create a New Account",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // DIUBAH: Tombol utama menjalankan fungsi _authenticate
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      // DIUBAH: Teks tombol berubah sesuai mode
                      child: Text(_isLoginMode ? "Login" : "Register"),
                    ),
                  ),
            const SizedBox(height: 12),
            // BARU: Tombol untuk beralih antara login dan register
            TextButton(
              onPressed: _isLoading ? null : _toggleMode,
              child: Text(
                _isLoginMode 
                  ? "Don't have an account? Register" 
                  : "Already have an account? Login",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}