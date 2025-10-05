import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';

class CreatePostInCommunityPage extends StatefulWidget {
  final String communityId;
  const CreatePostInCommunityPage({super.key, required this.communityId});

  @override
  State<CreatePostInCommunityPage> createState() => _CreatePostInCommunityPageState();
}

class _CreatePostInCommunityPageState extends State<CreatePostInCommunityPage> {
  final TextEditingController _textController = TextEditingController();
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
      final communityDoc = await FirebaseFirestore.instance.collection('communities').doc(widget.communityId).get();
      final communityName = communityDoc.data()?['name'] ?? '';
      final postData = {
        'content': postContent,
        'content_lower': postContent.toLowerCase(),
        'authorId': currentUser.uid,
        'user': userName,
        'handle': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'reposts': 0,
        'repostedBy': [],
        'comments': 0,
        'communityId': widget.communityId,
        'communityName': communityName,
      };

      final batch = FirebaseFirestore.instance.batch();
      final threadRef = FirebaseFirestore.instance.collection('threads').doc();
      batch.set(threadRef, postData);

      final communityPostRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityId).collection('posts').doc(threadRef.id);
      batch.set(communityPostRef, postData);
      
      await batch.commit();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Gagal membuat postingan komunitas: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: AppColors.background,
        elevation: 0,
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
                  hintText: "Share something with the community...",
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