import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostInCommunityPage extends StatefulWidget {
  final String communityId;
  const CreatePostInCommunityPage({super.key, required this.communityId});

  @override
  State<CreatePostInCommunityPage> createState() => _CreatePostInCommunityPageState();
}

class _CreatePostInCommunityPageState extends State<CreatePostInCommunityPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() { _isLoading = true; });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Menambahkan dokumen ke sub-koleksi 'posts' di dalam komunitas
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('posts')
          .add({
        'content': _textController.text,
        'authorId': currentUser.uid,
        'authorName': currentUser.displayName ?? currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
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
        title: const Text("Create Post"),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading ? const CircularProgressIndicator() : const Text("Post"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          maxLines: 10,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Share something with the community...",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}