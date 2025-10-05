import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/features/_feed/comment_page.dart';
import 'package:timeago/timeago.dart' as timeago;
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications yet.", style: TextStyle(color: AppColors.secondaryText)),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final String type = notification['type'];
              final String actorName = notification['actorName'];
              final postTimestamp = (notification['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              String message = '';
              IconData iconData;
              Color iconColor;

              switch (type) {
                case 'like':
                  message = 'liked your post.';
                  iconData = Icons.favorite;
                  iconColor = Colors.pink;
                  break;
                case 'repost':
                  message = 'reposted your post.';
                  iconData = Icons.repeat;
                  iconColor = Colors.green;
                  break;
                case 'comment':
                  message = 'commented on your post.';
                  iconData = Icons.chat_bubble;
                  iconColor = AppColors.accent;
                  break;
                default:
                  message = 'interacted with your post.';
                  iconData = Icons.person;
                  iconColor = AppColors.secondaryText;
              }

              return ListTile(
                leading: Icon(iconData, color: iconColor, size: 28),
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontFamily: 'Roboto'),
                    children: [
                      TextSpan(
                        text: actorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' $message'),
                    ],
                  ),
                ),
                subtitle: Text(
                  timeago.format(postTimestamp),
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentPage(threadId: notification['postId']),
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