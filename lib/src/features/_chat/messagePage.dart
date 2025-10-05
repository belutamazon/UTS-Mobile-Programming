import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/features/_chat/chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutteruts/src/features/_search/users_page.dart';
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text("Please log in to see messages.", style: TextStyle(color: AppColors.secondaryText))),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('members', arrayContains: currentUserId)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Start a new conversation.", style: TextStyle(color: AppColors.secondaryText)));
          }

          return ListView.separated(
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final List<dynamic> members = chatData['members'];
              final otherUserId = members.firstWhere((id) => id != currentUserId, orElse: () => null);

              if (otherUserId == null) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const ListTile();
                  
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final timestamp = (chatData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return ListTile(
                    leading: const CircleAvatar(radius: 24, backgroundColor: AppColors.secondaryText, child: Icon(Icons.person, color: AppColors.background)),
                    title: Text(userData['name'] ?? 'User', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    subtitle: Text(chatData['lastMessage'] ?? '', style: const TextStyle(color: AppColors.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      timeago.format(timestamp, locale: 'en_short'),
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => 
                        ChatPage(
                          chatId: chatDoc.id, 
                          recipientId: otherUserId, 
                          recipientName: userData['name']
                        )
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersPage()));
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.primaryText),
      ),
    );
  }
}