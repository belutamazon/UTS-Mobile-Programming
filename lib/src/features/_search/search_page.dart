import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutteruts/src/common/theme/app_colors.dart';
import 'package:flutteruts/src/features/_profile/profile_page.dart';
import 'dart:async'; 
import 'package:flutteruts/src/features/_feed/comment_page.dart';
import 'package:flutteruts/src/features/_community/community_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
class SearchResult {
  final List<DocumentSnapshot> users;
  final List<DocumentSnapshot> posts;
  final List<DocumentSnapshot> communities;

  SearchResult({required this.users, required this.posts, required this.communities});
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Future<SearchResult>? _searchFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        setState(() {
          _searchFuture = _performSearch(_searchController.text.trim());
        });
      } else {
        setState(() {
          _searchFuture = null;
        });
      }
    });
  }

  Future<SearchResult> _performSearch(String query) async {
    final lowerCaseQuery = query.toLowerCase();
    
    final usersFuture = FirebaseFirestore.instance.collection('users')
        .where('name_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('name_lower', isLessThan: '${lowerCaseQuery}z')
        .limit(3).get();
        
    final postsFuture = FirebaseFirestore.instance.collection('threads')
        .where('content_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('content_lower', isLessThan: '${lowerCaseQuery}z')
        .limit(3).get();

    final communitiesFuture = FirebaseFirestore.instance.collection('communities')
        .where('name_lower', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('name_lower', isLessThan: '${lowerCaseQuery}z')
        .limit(3).get();

    final results = await Future.wait([usersFuture, postsFuture, communitiesFuture]);

    return SearchResult(
      users: results[0].docs,
      posts: results[1].docs,
      communities: results[2].docs,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(20)),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: 'Search X...',
              hintStyle: const TextStyle(color: AppColors.secondaryText),
              prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.secondaryText),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            ),
          ),
        ),
      ),
      body: _buildResults(),
    );
  }

  Widget _buildResults() {
    if (_searchFuture == null) {
      return const Center(child: Text("Search for users, posts, and communities.", style: TextStyle(color: AppColors.secondaryText)));
    }

    return FutureBuilder<SearchResult>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("An error occurred: ${snapshot.error}", style: TextStyle(color: Colors.red.shade300)));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("No results found.", style: TextStyle(color: AppColors.secondaryText)));
        }

        final results = snapshot.data!;
        final bool hasNoResults = results.users.isEmpty && results.posts.isEmpty && results.communities.isEmpty;

        if (hasNoResults) {
          return const Center(child: Text("No results found.", style: TextStyle(color: AppColors.secondaryText)));
        }

        return ListView(
          children: [
            if (results.users.isNotEmpty) _buildSection("Users", results.users, _buildUserTile),
            if (results.posts.isNotEmpty) _buildSection("Posts", results.posts, _buildPostTile),
            if (results.communities.isNotEmpty) _buildSection("Communities", results.communities, _buildCommunityTile),
          ],
        );
      },
    );
  }
  
  Widget _buildSection(String title, List<DocumentSnapshot> docs, Widget Function(DocumentSnapshot) tileBuilder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(title, style: const TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...docs.map((doc) => tileBuilder(doc)),
        const Divider(color: AppColors.divider, height: 1),
      ],
    );
  }

  ListTile _buildUserTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    if (userId == FirebaseAuth.instance.currentUser?.uid) return ListTile();

    return ListTile(
      leading: const CircleAvatar(backgroundColor: AppColors.secondaryText, child: Icon(Icons.person, color: AppColors.background)),
      title: Text(data['name'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
      subtitle: Text('@${data['email']?.split('@')[0] ?? ''}', style: const TextStyle(color: AppColors.secondaryText)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: doc.id))),
    );
  }
  
  ListTile _buildPostTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListTile(
      leading: const CircleAvatar(backgroundColor: AppColors.secondaryText, child: Icon(Icons.article_outlined, color: AppColors.background, size: 20)),
      title: Text(data['content'] ?? '', style: const TextStyle(color: AppColors.primaryText), maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('by ${data['user'] ?? ''}', style: const TextStyle(color: AppColors.secondaryText)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommentPage(threadId: doc.id))),
    );
  }

  ListTile _buildCommunityTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListTile(
      leading: const CircleAvatar(backgroundColor: AppColors.secondaryText, child: Icon(Icons.group, color: AppColors.background)),
      title: Text(data['name'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
      subtitle: Text('${data['memberCount'] ?? 0} members', style: const TextStyle(color: AppColors.secondaryText)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityDetailPage(communityId: doc.id))),
    );
  }
}