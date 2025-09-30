import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Nama class yang benar untuk dipanggil dari HomePage
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createThread() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() { _isLoading = true; });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to post.")),
      );
      setState(() { _isLoading = false; });
      return;
    }

    // Data ini untuk postingan umum, tanpa communityId
    final threadData = {
      'content': _textController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'authorId': currentUser.uid,
      'user': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Anonymous',
      'handle': currentUser.email,
      'likes': 0,
      'reposts': 0,
      'comments': 0,
    };

    try {
      // Menambahkan data ke koleksi 'threads' utama
      await FirebaseFirestore.instance.collection('threads').add(threadData);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _isLoading = false; });
      print("Error creating thread: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("New Post"),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createThread,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Post"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.white),
          maxLines: 10,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "What's happening?",
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}