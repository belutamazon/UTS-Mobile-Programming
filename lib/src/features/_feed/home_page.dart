import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/common/widgets/post_widget.dart';
import 'package:flutteruts/src/features/_community/community_list_page.dart';
import 'package:flutteruts/src/features/_feed/create_post_page.dart';
import 'package:flutteruts/src/features/_search/search_page.dart';
import 'package:flutteruts/src/features/_profile/profile_page.dart';
import 'package:flutteruts/src/features/_notification/notification_page.dart';
import 'package:flutteruts/src/features/_chat/messagePage.dart';

class FollowingFeed extends StatefulWidget {
  final Function(String, String) onToggleLike;
  final Function(String, String) onHandleRepost;

  const FollowingFeed({
    super.key,
    required this.onToggleLike,
    required this.onHandleRepost,
  });

  @override
  State<FollowingFeed> createState() => _FollowingFeedState();
}

class _FollowingFeedState extends State<FollowingFeed> {
  List<String> _followingIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowingIds();
  }

  Future<void> _fetchFollowingIds() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .get();
      
      final ids = followingSnapshot.docs.map((doc) => doc.id).toList();
      
      ids.add(currentUser.uid);

      if (mounted) {
        setState(() {
          _followingIds = ids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error fetching following IDs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_followingIds.isEmpty) {
      return const Center(
        child: Text(
          "Posts from users you follow will appear here.",
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('threads')
          .where('authorId', whereIn: _followingIds)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No posts from users you follow yet.",
              style: TextStyle(color: AppColors.secondaryText),
            ),
          );
        }

        final posts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final threadId = posts[index].id;
            return PostWidget(
              postData: postData,
              threadId: threadId,
              onToggleLike: widget.onToggleLike,
              onHandleRepost: widget.onHandleRepost,
            );
          },
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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
      debugPrint("Gagal melakukan like/unlike: $e");
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
  
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final List<Widget> pages = [
      TabBarView(
        controller: _tabController,
        children: [
           StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('threads').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No posts yet.", style: TextStyle(color: AppColors.secondaryText)));
              }
              final posts = snapshot.data!.docs;
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final postData = posts[index].data() as Map<String, dynamic>;
                  final threadId = posts[index].id;
                  return PostWidget(
                    postData: postData,
                    threadId: threadId,
                    onToggleLike: toggleLike,
                    onHandleRepost: handleRepost,
                  );
                },
              );
            },
          ),
          FollowingFeed(
            onToggleLike: toggleLike,
            onHandleRepost: handleRepost,
          ),
        ],
      ),
      const SearchPage(),
      const CommunityListPage(),
      const NotificationPage(),
      const MessagePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            child: const CircleAvatar(
              backgroundColor: AppColors.secondaryText,
              child: Icon(Icons.person, color: AppColors.background),
            ),
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/z_dark.png", height: 28),
        bottom: _selectedIndex == 0
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: AppColors.primaryText,
                unselectedLabelColor: AppColors.secondaryText,
                tabs: const [Tab(text: "For you"), Tab(text: "Following")],
              )
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryText,
        unselectedItemColor: AppColors.secondaryText,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() { _selectedIndex = index; });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "Messages"),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              heroTag: 'homePageFAB', 
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage()));
              },
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: AppColors.primaryText),
            )
          : null,
    );
  }
}