import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/common/widgets/post_widget.dart';

class CommentPage extends StatefulWidget {
  final String threadId;
  const CommentPage({super.key, required this.threadId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  Map<String, dynamic>? _threadData;
  bool _isLoadingThread = true;

  @override
  void initState() {
    super.initState();
    _fetchThreadData();
  }

  Future<void> _fetchThreadData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('threads').doc(widget.threadId).get();
      if (doc.exists && mounted) {
        setState(() {
          _threadData = doc.data();
          _isLoadingThread = false;
        });
      } else {
        if(mounted) setState(() { _isLoadingThread = false; });
      }
    } catch (e) {
      if(mounted) setState(() { _isLoadingThread = false; });
      debugPrint("Error fetching thread data: $e");
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final tempMessage = _commentController.text;
    _commentController.clear();

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final username = userDoc.data()?['name'] ?? 'A User';
    
    final threadRef = FirebaseFirestore.instance.collection('threads').doc(widget.threadId);
    final commentRef = threadRef.collection('comments').doc();

    final batch = FirebaseFirestore.instance.batch();
    batch.set(commentRef, {
      'userId': currentUserId,
      'username': username,
      'content': tempMessage,
      'timestamp': FieldValue.serverTimestamp(),
    });
    batch.update(threadRef, {'comments': FieldValue.increment(1)});

    await batch.commit();

    final postAuthorId = _threadData?['authorId'];
    if (postAuthorId != null) {
      _createNotification(recipientId: postAuthorId, actorId: currentUserId, type: 'comment', postId: widget.threadId);
    }
  }
  
  void _createNotification({ required String recipientId, required String actorId, required String type, required String postId,}) async {
    if (recipientId == actorId) return;
    final actorDoc = await FirebaseFirestore.instance.collection('users').doc(actorId).get();
    final actorName = actorDoc.data()?['name'] ?? 'Someone';
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': recipientId, 'actorId': actorId, 'actorName': actorName, 'type': type,
      'postId': postId, 'isRead': false, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Post"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isLoadingThread)
            const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
          else if (_threadData != null)
            PostWidget(
              postData: _threadData!,
              threadId: widget.threadId,
              onToggleLike: (id, uid) {},
              onHandleRepost: (id, uid) {},
            )
          else 
            const Padding(padding: EdgeInsets.all(16.0), child: Text("Post not found.", style: TextStyle(color: AppColors.secondaryText))),

          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('threads').doc(widget.threadId).collection('comments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingThread) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet.", style: TextStyle(color: AppColors.secondaryText)));
                }

                final comments = snapshot.data!.docs;

                comments.sort((a, b) {
                  var aData = a.data() as Map<String, dynamic>;
                  var bData = b.data() as Map<String, dynamic>;
                  Timestamp? aTimestamp = aData['timestamp'];
                  Timestamp? bTimestamp = bData['timestamp'];
                  if (aTimestamp == null) return -1;
                  if (bTimestamp == null) return 1;

                  return aTimestamp.compareTo(bTimestamp);
                });

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final commentData = comments[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.secondaryText, child: Icon(Icons.person, color: AppColors.background)),
                      title: Text(commentData['username'] ?? 'User', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                      subtitle: Text(commentData['content'] ?? '', style: const TextStyle(color: AppColors.primaryText)),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: AppColors.primaryText),
                decoration: const InputDecoration(
                  hintText: "Post your reply...",
                  hintStyle: TextStyle(color: AppColors.secondaryText),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendComment(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.accent),
              onPressed: _sendComment,
            ),
          ],
        ),
      ),
    );
  }
}