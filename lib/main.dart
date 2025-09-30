 import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- Paket inti Firebase
import 'firebase_options.dart'; // <-- Konfigurasi proyek Anda
import 'auth_gate.dart'; // <-- Gerbang logika untuk login

// 1. Fungsi main harus 'async' untuk menunggu proses inisialisasi
void main() async {
  // 2. Memastikan semua widget siap sebelum Firebase dijalankan
  WidgetsFlutterBinding.ensureInitialized();  
  
  // 3. Menunggu koneksi ke Firebase selesai sebelum aplikasi berjalan
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 4. Menjalankan aplikasi SETELAH Firebase siap
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'X Clone',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 0, 0, 0),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: Colors.blueAccent),
      ),
      // Titik awal aplikasi diubah ke AuthGate untuk memeriksa status login
      home: const AuthGate(), 
    );
  }
}