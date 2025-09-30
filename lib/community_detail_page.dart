import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_in_community_page.dart';
import 'widgets/post_widget.dart'; // Widget terpisah untuk post

class CommunityDetailPage extends StatefulWidget {
  final String communityId;
  final Map<String, dynamic> communityData;

  const CommunityDetailPage({
    super.key,
    required this.communityId,
    required this.communityData,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool _isMember = false;
  bool _isLoading = true;
  bool _isTogglingJoin = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    setState(() { _isLoading = true; });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() { _isLoading = false; });
      return;
    }
    final memberDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('members')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        _isMember = memberDoc.exists;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMembership() async {
    setState(() { _isTogglingJoin = true; });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final communityRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityId);
    final memberRef = communityRef.collection('members').doc(currentUser.uid);

    try {
      if (_isMember) {
        await memberRef.delete();
        await communityRef.update({'memberCount': FieldValue.increment(-1)});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You left the community.")));
      } else {
        await memberRef.set({'joinedAt': FieldValue.serverTimestamp(), 'role': 'member'});
        await communityRef.update({'memberCount': FieldValue.increment(1)});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome to the community!")));
      }
      if (mounted) {
        setState(() { _isMember = !_isMember; });
      }
    } catch (e) {
      // Handle error
    } finally {
       if (mounted) setState(() { _isTogglingJoin = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.communityData['name'] ?? 'Community'),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isMember) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostInCommunityPage(communityId: widget.communityId)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Join first before you can post in this community.")),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.communityData['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.communityData['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('${widget.communityData['memberCount'] ?? 0} Members', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isTogglingJoin ? null : _toggleMembership,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMember ? Colors.grey.shade800 : Colors.white,
                            foregroundColor: _isMember ? Colors.white : Colors.black,
                          ),
                          child: _isTogglingJoin ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isMember ? "Joined" : "Join"),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey, height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('communities')
                        .doc(widget.communityId)
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No posts yet. Be the first to post!", style: TextStyle(color: Colors.white)));
                      }
                      final posts = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postData = posts[index].data() as Map<String, dynamic>;
                          return PostWidget(postData: postData);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}