import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messagePage.dart'; // Pastikan path import ini benar

class UsersPage extends StatelessWidget {
  final String currentUserId;
  const UsersPage({super.key, required this.currentUserId});

  /// Fungsi untuk membuat atau mendapatkan ID chat yang konsisten
  Future<String> _createOrGetChat(String otherUserId) async {
    List<String> userIds = [currentUserId, otherUserId];
    userIds.sort();
    String chatId = userIds.join('_');

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final docSnap = await chatRef.get();

    if (!docSnap.exists) {
      await chatRef.set({
        'members': [currentUserId, otherUserId],
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Direct Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userDoc = users[index];
              // Asumsi setiap dokumen user memiliki field 'email' dan 'name'
              final userEmail = userDoc.get('email') ?? 'No Email';
              final userName = userDoc.get('name') ?? 'No Name';
              final userId = userDoc.id; // ID dokumen user adalah UID-nya

              // Jangan tampilkan diri sendiri di daftar
              if (userId == currentUserId) {
                return const SizedBox.shrink(); // Widget kosong
              }

              return ListTile(
                title: Text(userName, style: const TextStyle(color: Colors.white)),
                subtitle: Text(userEmail, style: const TextStyle(color: Colors.grey)),
                onTap: () async {
                  final chatId = await _createOrGetChat(userId);
                  
                  // Pengecekan keamanan sebelum navigasi
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagePage(
                          chatId: chatId,
                          currentUserId: currentUserId,
                          otherUsername: userName,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}