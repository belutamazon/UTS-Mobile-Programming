import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final postContent = _textController.text.trim();
    if (postContent.isEmpty) return;

    setState(() { _isLoading = true; });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userName = userDoc.data()?['name'] ?? 'A User';
      final userEmail = userDoc.data()?['email'] ?? 'no-email';

      await FirebaseFirestore.instance.collection('threads').add({
        'authorId': currentUser.uid,
        'user': userName,
        'handle': userEmail,
        'content': postContent,
        'content_lower': postContent.toLowerCase(),
        'likes': 0,
        'likedBy': [],
        'reposts': 0,
        'repostedBy': [],
        'comments': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Gagal membuat postingan: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("New Post"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                  : const Text("Post"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(backgroundColor: AppColors.secondaryText, child: Icon(Icons.person, color: AppColors.background)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                maxLines: null,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "What's happening?",
                  hintStyle: TextStyle(color: AppColors.secondaryText),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}