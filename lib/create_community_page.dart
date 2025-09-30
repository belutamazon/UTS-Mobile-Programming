import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package/firebase_auth/firebase_auth.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() { _isLoading = true; });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle jika tidak ada user yang login
      return;
    }

    try {
      // 1. Buat dokumen komunitas baru
      final communityDocRef = await FirebaseFirestore.instance.collection('communities').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'creatorId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1, // Pembuat langsung menjadi anggota
        'category': 'General', // Default
      });
      
      // 2. Otomatis jadikan pembuat sebagai anggota di sub-koleksi
      await communityDocRef.collection('members').doc(currentUser.uid).set({
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'creator',
      });

      if (mounted) Navigator.pop(context);

    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Create a Community"),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createCommunity,
            child: _isLoading ? const CircularProgressIndicator() : const Text("Create"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Community Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
    );
  }
}