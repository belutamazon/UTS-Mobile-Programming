import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/features/_feed/comment_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> postData;
  final String threadId;
  final Function(String, String) onToggleLike;
  final Function(String, String) onHandleRepost;

  const PostWidget({
    super.key,
    required this.postData,
    required this.threadId,
    required this.onToggleLike,
    required this.onHandleRepost,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    final List<dynamic> likedBy = postData["likedBy"] ?? [];
    final bool isLiked = likedBy.contains(currentUserId);
    final List<dynamic> repostedBy = postData["repostedBy"] ?? [];
    final bool isReposted = repostedBy.contains(currentUserId);

    final postTimestamp = (postData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CommentPage(threadId: threadId)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.secondaryText,
              radius: 20,
              child: Icon(Icons.person, color: AppColors.background),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        postData["user"] ?? 'User',
                        style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '@${postData["handle"]?.split('@')[0] ?? 'handle'} · ${timeago.format(postTimestamp)}',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    postData["content"] ?? '',
                    style: const TextStyle(color: AppColors.primaryText, fontSize: 15, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  _buildActionBar(
                    context: context,
                    comments: postData["comments"] ?? 0,
                    reposts: postData["reposts"] ?? 0,
                    likes: postData["likes"] ?? 0,
                    isLiked: isLiked,
                    isReposted: isReposted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar({
    required BuildContext context,
    required int comments,
    required int reposts,
    required int likes,
    required bool isLiked,
    required bool isReposted,
  }) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionButton(
          icon: Icons.chat_bubble_outline,
          value: comments,
          onTap: () {},
        ),
        _actionButton(
          icon: Icons.repeat,
          value: reposts,
          color: isReposted ? Colors.green : AppColors.secondaryText,
          onTap: () => onHandleRepost(threadId, currentUserId),
        ),
        _actionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_outline,
          value: likes,
          color: isLiked ? Colors.pink : AppColors.secondaryText,
          onTap: () => onToggleLike(threadId, currentUserId),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required int value, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.secondaryText, size: 20),
          const SizedBox(width: 4),
          if (value > 0)
            Text(
              value.toString(),
              style: TextStyle(color: color ?? AppColors.secondaryText, fontSize: 14),
            ),
        ],
      ),
    );
  }
}