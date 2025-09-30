import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagePage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUsername;

  const MessagePage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUsername,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String text = _messageController.text.trim();

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    // add ke messages
    await chatRef.collection('messages').add({
      'senderId': widget.currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // update chat info
    await chatRef.update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUsername)),
      body: Column(
        children: [
          /// 🔹 List pesan
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet.")); // Tambahkan ini untuk kejelasan
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    print("--- Memeriksa Pesan ---");
                    print("Isi Pesan: ${msg['text']}");
                    print("ID Pengirim (dari Firestore): ${msg['senderId']}");
                    print("ID User Saat Ini (di Aplikasi): ${widget.currentUserId}");
                    bool isMe = msg['senderId'] == widget.currentUserId;
                    print("Apakah ini pesan saya? $isMe");

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                          // Jika ini pesan saya, teksnya putih. Jika pesan orang lain, teksnya hitam.
                          color: isMe ? Colors.white : Colors.white
                          ),
                        ),
                      )
                    );
                  },
                );
              },
            ),
          ),

          /// 🔹 Input pesan
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Ketik pesan...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
