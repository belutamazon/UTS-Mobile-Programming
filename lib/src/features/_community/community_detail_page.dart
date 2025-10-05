import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/common/widgets/post_widget.dart';
import 'package:flutteruts/src/features/_community/create_post_in_community_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityDetailPage extends StatefulWidget {
  final String communityId;
  const CommunityDetailPage({super.key, required this.communityId});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool _isMember = false;
  bool _isLoadingMembership = true;
  bool _isTogglingJoin = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkMembership();
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
  
  void toggleLike(String postId, String userId) async {
    if (userId.isEmpty) return;
    
    final communityPostRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityId).collection('posts').doc(postId);
    final mainThreadRef = FirebaseFirestore.instance.collection('threads').doc(postId);

    try {
      final postDoc = await communityPostRef.get();
      if (!postDoc.exists) return;

      final postData = postDoc.data() as Map<String, dynamic>;
      final postAuthorId = postData['authorId'];
      final likedByList = List<String>.from(postData['likedBy'] ?? []);
      
      final batch = FirebaseFirestore.instance.batch();
      
      if (likedByList.contains(userId)) {
        batch.update(communityPostRef, {'likes': FieldValue.increment(-1), 'likedBy': FieldValue.arrayRemove([userId])});
        batch.update(mainThreadRef, {'likes': FieldValue.increment(-1), 'likedBy': FieldValue.arrayRemove([userId])});
      } else {
        batch.update(communityPostRef, {'likes': FieldValue.increment(1), 'likedBy': FieldValue.arrayUnion([userId])});
        batch.update(mainThreadRef, {'likes': FieldValue.increment(1), 'likedBy': FieldValue.arrayUnion([userId])});
        
        if (postAuthorId != null) {
          _createNotification(recipientId: postAuthorId, actorId: userId, type: 'like', postId: postId);
        }
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint("Gagal sinkronisasi like: $e");
    }
  }

  void handleRepost(String postId, String userId) async {
    if (userId.isEmpty) return;
    
    final communityPostRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityId).collection('posts').doc(postId);
    final mainThreadRef = FirebaseFirestore.instance.collection('threads').doc(postId);

    try {
      final postDoc = await communityPostRef.get();
      if (!postDoc.exists) return;

      final postData = postDoc.data() as Map<String, dynamic>;
      final postAuthorId = postData['authorId'];
      final repostedByList = List<String>.from(postData['repostedBy'] ?? []);

      final batch = FirebaseFirestore.instance.batch();

      if (repostedByList.contains(userId)) {
        batch.update(communityPostRef, {'reposts': FieldValue.increment(-1), 'repostedBy': FieldValue.arrayRemove([userId])});
        batch.update(mainThreadRef, {'reposts': FieldValue.increment(-1), 'repostedBy': FieldValue.arrayRemove([userId])});
      } else {
        batch.update(communityPostRef, {'reposts': FieldValue.increment(1), 'repostedBy': FieldValue.arrayUnion([userId])});
        batch.update(mainThreadRef, {'reposts': FieldValue.increment(1), 'repostedBy': FieldValue.arrayUnion([userId])});
        
        if (postAuthorId != null) {
          _createNotification(recipientId: postAuthorId, actorId: userId, type: 'repost', postId: postId);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Gagal sinkronisasi repost: $e");
    }
  }

  Future<void> _checkMembership() async {
    if (currentUser == null) {
      if (mounted) setState(() { _isLoadingMembership = false; });
      return;
    }
    try {
      final memberDoc = await FirebaseFirestore.instance.collection('communities').doc(widget.communityId).collection('members').doc(currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _isMember = memberDoc.exists;
          _isLoadingMembership = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking membership: $e");
      if (mounted) setState(() { _isLoadingMembership = false; });
    }
  }

  Future<void> _toggleMembership() async {
    if (currentUser == null) return;
    setState(() { _isTogglingJoin = true; });
    final communityRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityId);
    final memberRef = communityRef.collection('members').doc(currentUser!.uid);
    try {
      if (_isMember) {
        await memberRef.delete();
        await communityRef.update({'memberCount': FieldValue.increment(-1)});
      } else {
        await memberRef.set({'joinedAt': FieldValue.serverTimestamp(), 'role': 'member'});
        await communityRef.update({'memberCount': FieldValue.increment(1)});
      }
      if (mounted) {
        setState(() { _isMember = !_isMember; });
      }
    } catch (e) {
      debugPrint("Gagal mengubah status membership: $e");
    } finally {
      if (mounted) setState(() { _isTogglingJoin = false; });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('communities').doc(widget.communityId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Failed to load community.")));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(backgroundColor: AppColors.background, body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text("Error"), backgroundColor: AppColors.background, elevation: 0),
            body: const Center(child: Text("Community not found.", style: TextStyle(color: AppColors.secondaryText))),
          );
        }

        final communityData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(""),
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_isMember) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostInCommunityPage(communityId: widget.communityId)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Join first to post.")));
              }
            },
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.add, color: AppColors.primaryText),
          ),
          body: Column(
            children: [
              _buildCommunityHeader(communityData),
              const Divider(color: AppColors.divider, height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('communities').doc(widget.communityId).collection('posts').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No posts yet. Be the first!", style: TextStyle(color: AppColors.secondaryText)));
                    }
                    
                    final posts = postSnapshot.data!.docs;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final postData = posts[index].data() as Map<String, dynamic>;
                        final postId = posts[index].id;
                        return PostWidget(
                          postData: postData,
                          threadId: postId,
                          onToggleLike: toggleLike,
                          onHandleRepost: handleRepost,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityHeader(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['name'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (data['description'] != null && data['description'].isNotEmpty) ...[
            Text(data['description'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 16)),
            const SizedBox(height: 8),
          ],
          Text('${data['memberCount'] ?? 0} Members', style: const TextStyle(color: AppColors.secondaryText)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingMembership || _isTogglingJoin ? null : _toggleMembership,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMember ? AppColors.background : AppColors.primaryText,
                foregroundColor: _isMember ? AppColors.primaryText : AppColors.background,
                side: _isMember ? const BorderSide(color: AppColors.secondaryText) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoadingMembership || _isTogglingJoin
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isMember ? "Joined" : "Join"),
            ),
          ),
        ],
      ),
    );
  }
}