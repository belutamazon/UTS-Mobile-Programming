import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messagePage.dart';

class UsersPage extends StatelessWidget {
  final String currentUserId; // user yg login

  const UsersPage({super.key, required this.currentUserId});

  /// Cari atau buat chatId dengan user lain
  Future<String> _createOrGetChat(String otherUserId) async {
  // 1. Ambil ID pengguna saat ini dan pengguna lain.
  List<String> userIds = [currentUserId, otherUserId];
  
  // 2. Urutkan ID tersebut berdasarkan abjad untuk memastikan konsistensi.
  userIds.sort();
  
  // 3. Gabungkan ID yang sudah diurutkan dengan underscore.
  // Ini akan menghasilkan ID yang SELALU SAMA untuk pasangan pengguna ini.
  String chatId = userIds.join('_');

  // 4. Langsung menunjuk ke dokumen chat dengan ID yang sudah pasti.
  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
  final docSnap = await chatRef.get();

  // 5. Jika dokumen chat belum ada, buat yang baru dengan ID tersebut.
  if (!docSnap.exists) {
    await chatRef.set({
      'members': [currentUserId, otherUserId],
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 6. Kembalikan ID yang konsisten.
  return chatId;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              if (user.id == currentUserId) return Container();

              return ListTile(
                title: Text(user['name'],style: TextStyle(color: Colors.white),),
                subtitle: Text(user['email'],style: TextStyle(color: Colors.grey),),
                onTap: () async {
                  String chatId = await _createOrGetChat(user.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessagePage(
                        chatId: chatId,
                        currentUserId: currentUserId,
                        otherUsername: user['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
