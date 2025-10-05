import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/features/_chat/chat_page.dart';
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  Future<void> _startChat(BuildContext context, String recipientId, String recipientName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    List<String> ids = [currentUserId, recipientId];
    ids.sort();
    String chatId = ids.join('_');

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'members': [currentUserId, recipientId],
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chatId,
          recipientId: recipientId,
          recipientName: recipientName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("New Message"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('name_lower').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;
              
              if (userId == FirebaseAuth.instance.currentUser?.uid) {
                return const SizedBox.shrink();
              }

              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.secondaryText, child: Icon(Icons.person, color: AppColors.background)),
                title: Text(userData['name'] ?? 'User', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                subtitle: Text('@${userData['email']?.split('@')[0] ?? 'handle'}', style: const TextStyle(color: AppColors.secondaryText)),
                onTap: () => _startChat(context, userId, userData['name'] ?? 'User'),
              );
            },
          );
        },
      ),
    );
  }
}