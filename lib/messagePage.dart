import 'package:flutter/material.dart';
import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  final List<Map<String, String>> chats = [
    {
      'name': 'John Doe',
      'username': '@johnd',
      'message': 'Hey, how are you?',
      'time': '2m',
      'avatar': 'https://i.pravatar.cc/150?img=1'
    },
    {
      'name': 'Jane Smith',
      'username': '@janes',
      'message': 'Let’s catch up tomorrow!',
      'time': '1h',
      'avatar': 'https://i.pravatar.cc/150?img=2'
    },
    {
      'name': 'Alex Lee',
      'username': '@alexl',
      'message': 'See you later!',
      'time': '3h',
      'avatar': 'https://i.pravatar.cc/150?img=3'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messages"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat['avatar']!),
            ),
            title: Text(chat['name']!, style: TextStyle(color: Colors.white)),
            subtitle: Text(
              "${chat['username']} · ${chat['message']}",
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Text(chat['time']!, style: TextStyle(color: Colors.grey[400])),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    name: chat['name']!,
                    avatar: chat['avatar']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
