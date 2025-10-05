import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/features/_profile/profile_page.dart';

class FollowListPage extends StatelessWidget {
  final String userId;
  final String title;

  const FollowListPage({super.key, required this.userId, required this.title});

  @override
  Widget build(BuildContext context) {
    final collectionPath = title.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(collectionPath)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No users found.", style: TextStyle(color: AppColors.secondaryText)),
            );
          }

          final userIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.separated(
            itemCount: userIds.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              return _buildUserTile(context, userIds[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? 'User';
        final userHandle = '@${userData['email']?.split('@')[0] ?? 'handle'}';

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.secondaryText,
            child: Icon(Icons.person, color: AppColors.background),
          ),
          title: Text(userName, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
          subtitle: Text(userHandle, style: const TextStyle(color: AppColors.secondaryText)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
            );
          },
        );
      },
    );
  }
}