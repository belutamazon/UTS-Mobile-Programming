import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/common/widgets/post_widget.dart';
import 'package:flutteruts/src/features/_profile/follow_list_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final String targetUid;
  late final String currentUid;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    targetUid = widget.userId ?? currentUid;

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
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

  void toggleLike(String threadId, String userId) async {
    if (userId.isEmpty) return;
    final threadRef = FirebaseFirestore.instance.collection('threads').doc(threadId);
    try {
      final DocumentSnapshot threadDoc = await threadRef.get();
      if (!threadDoc.exists) return;
      final postData = threadDoc.data() as Map<String, dynamic>;
      final postAuthorId = postData['authorId'];
      final likedByList = List<String>.from(postData['likedBy'] ?? []);
      if (likedByList.contains(userId)) {
        await threadRef.update({'likes': FieldValue.increment(-1), 'likedBy': FieldValue.arrayRemove([userId])});
      } else {
        await threadRef.update({'likes': FieldValue.increment(1), 'likedBy': FieldValue.arrayUnion([userId])});
        if (postAuthorId != null) {
          _createNotification(recipientId: postAuthorId, actorId: userId, type: 'like', postId: threadId);
        }
      }
    } catch (e) {
      debugPrint("Gagal like/unlike dari Profile: $e");
    }
  }

  void handleRepost(String threadId, String userId) async {
    if (userId.isEmpty) return;
    final threadRef = FirebaseFirestore.instance.collection('threads').doc(threadId);
    final userRepostRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('reposts').doc(threadId);
    final batch = FirebaseFirestore.instance.batch();

    try {
      final threadDoc = await threadRef.get();
      if (!threadDoc.exists) return;

      final postData = threadDoc.data() as Map<String, dynamic>;
      final postAuthorId = postData['authorId'];
      final repostedByList = List<String>.from(postData['repostedBy'] ?? []);

      if (repostedByList.contains(userId)) {
        batch.update(threadRef, {'reposts': FieldValue.increment(-1), 'repostedBy': FieldValue.arrayRemove([userId])});
        batch.delete(userRepostRef);
      } else {
        batch.update(threadRef, {'reposts': FieldValue.increment(1), 'repostedBy': FieldValue.arrayUnion([userId])});
        batch.set(userRepostRef, {
          'threadId': threadId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (postAuthorId != null) {
          _createNotification(recipientId: postAuthorId, actorId: userId, type: 'repost', postId: threadId);
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Gagal toggle repost: $e");
    }
  }
  
  Future<void> _followUser() async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(FirebaseFirestore.instance.collection('users').doc(currentUid).collection('following').doc(targetUid), <String, dynamic>{});
    batch.set(FirebaseFirestore.instance.collection('users').doc(targetUid).collection('followers').doc(currentUid), <String, dynamic>{});
    batch.update(FirebaseFirestore.instance.collection('users').doc(currentUid), {'followingCount': FieldValue.increment(1)});
    batch.update(FirebaseFirestore.instance.collection('users').doc(targetUid), {'followersCount': FieldValue.increment(1)});
    await batch.commit();
  }
  
  Future<void> _unfollowUser() async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(FirebaseFirestore.instance.collection('users').doc(currentUid).collection('following').doc(targetUid));
    batch.delete(FirebaseFirestore.instance.collection('users').doc(targetUid).collection('followers').doc(currentUid));
    batch.update(FirebaseFirestore.instance.collection('users').doc(currentUid), {'followingCount': FieldValue.increment(-1)});
    batch.update(FirebaseFirestore.instance.collection('users').doc(targetUid), {'followersCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> _showEditBioDialog(String currentBio) async {
    final bioController = TextEditingController(text: currentBio);
    if (!mounted) return;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.divider,
          title: const Text('Edit Bio', style: TextStyle(color: AppColors.primaryText)),
          content: TextField(
            controller: bioController,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: const InputDecoration(hintText: "Tell us about yourself", hintStyle: TextStyle(color: AppColors.secondaryText)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(targetUid).update({
                  'bio': bioController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwnProfile = targetUid == currentUid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: AppColors.primaryText,
          unselectedLabelColor: AppColors.secondaryText,
          tabs: const [Tab(text: "Posts"), Tab(text: "Reposts")],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetUid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found.", style: TextStyle(color: AppColors.secondaryText)));
          }
          
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              _buildProfileHeader(userData, isOwnProfile),
              const Divider(color: AppColors.divider, height: 1),
              Expanded(
                child: IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    _buildPostsTab(),
                    _buildRepostsTab(),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData, bool isOwnProfile) {
    final currentBio = userData['bio'] ?? '';
    final followersCount = userData['followersCount'] ?? 0;
    final followingCount = userData['followingCount'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 40, backgroundColor: AppColors.secondaryText, child: Icon(Icons.person, color: AppColors.background, size: 40)),
              if (isOwnProfile)
                ElevatedButton(
                  onPressed: () => _showEditBioDialog(currentBio),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background, foregroundColor: AppColors.primaryText,
                    side: const BorderSide(color: AppColors.secondaryText), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Edit profile"),
                )
              else 
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUid).collection('following').doc(targetUid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 36);
                    final bool isFollowing = snapshot.data!.exists;
                    return ElevatedButton(
                      onPressed: isFollowing ? _unfollowUser : _followUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? AppColors.background : AppColors.primaryText,
                        foregroundColor: isFollowing ? AppColors.primaryText : AppColors.background,
                        side: isFollowing ? const BorderSide(color: AppColors.secondaryText) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(isFollowing ? "Following" : "Follow"),
                    );
                  },
                )
            ],
          ),
          const SizedBox(height: 12),
          Text(userData['name'] ?? 'User', style: const TextStyle(color: AppColors.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('@${userData['email']?.split('@')[0] ?? 'handle'}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 16)),
          const SizedBox(height: 12),
          if (currentBio.isNotEmpty) ...[
            Text(currentBio, style: const TextStyle(color: AppColors.primaryText, fontSize: 15)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FollowListPage(userId: targetUid, title: "Followers"))),
                child: Row(
                  children: [
                    Text("$followersCount", style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Text("Followers", style: TextStyle(color: AppColors.secondaryText)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FollowListPage(userId: targetUid, title: "Following"))),
                child: Row(
                  children: [
                    Text("$followingCount", style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Text("Following", style: TextStyle(color: AppColors.secondaryText)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('threads').where('authorId', isEqualTo: targetUid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No posts yet.", style: TextStyle(color: AppColors.secondaryText)));
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final postDoc = snapshot.data!.docs[index];
            final postData = postDoc.data() as Map<String, dynamic>;
            return PostWidget(
              postData: postData, threadId: postDoc.id,
              onToggleLike: toggleLike, onHandleRepost: handleRepost,
            );
          },
        );
      },
    );
  }

  Widget _buildRepostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(targetUid).collection('reposts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reposts yet.", style: TextStyle(color: AppColors.secondaryText)));
        }
        
        final repostDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: repostDocs.length,
          itemBuilder: (context, index) {
            final repostData = repostDocs[index].data() as Map<String, dynamic>;
            final threadId = repostData['threadId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('threads').doc(threadId).get(),
              builder: (context, threadSnapshot) {
                if (!threadSnapshot.hasData || !threadSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final postData = threadSnapshot.data!.data() as Map<String, dynamic>;
                return PostWidget(
                  postData: postData,
                  threadId: threadId,
                  onToggleLike: toggleLike,
                  onHandleRepost: handleRepost,
                );
              },
            );
          },
        );
      },
    );
  }
}