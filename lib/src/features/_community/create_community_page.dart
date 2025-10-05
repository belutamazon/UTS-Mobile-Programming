import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    final communityName = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (communityName.isEmpty) return;
    
    setState(() { _isLoading = true; });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('communities').add({
        'name': communityName,
        'name_lower': communityName.toLowerCase(),
        'description': description,
        'creatorId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Gagal membuat komunitas: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Community"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createCommunity,
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Create"),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(
                labelText: "Community Name",
                labelStyle: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: const InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: AppColors.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}