import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> forYouPosts = [
    "The US government has made funds for internal company 30% of equity.",
    "Apple to release a new AI-powered iPhone with advanced features.",
    "NASA confirms water traces on Mars surface found again.",
    "Global chip shortage may continue until 2026, experts warn.",
    "Microsoft invests heavily in quantum computing research.",
    "Tesla introduces cheaper EV model for Asian markets.",
    "Indonesia to become key hub for nickel production.",
    "Meta launches new VR headset with ultra-thin design.",
    "OpenAI announces breakthrough in language model efficiency.",
    "Amazon expands drone delivery program to more cities.",
  ];

  final List<String> followingPosts = [
    "Ferrari plans to launch electric supercar in 2026.",
    "Red Bull confirms new F1 engine development project.",
    "McLaren signs new partnership deal for future upgrades.",
    "Spotify testing AI-generated playlist for premium users.",
    "Sony announces PS6 concept in early development.",
    "Netflix to add live sports streaming by next year.",
    "Samsung reveals flexible laptop prototype at tech expo.",
    "Xiaomi develops solar-powered smartphone prototype.",
    "YouTube adds new feature to block AI deepfake content.",
    "Google invests 2B Dollar in green data center expansion.",
  ];

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

  Widget _buildPostList(List<String> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              posts[index],
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Community",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "For you"),
            Tab(text: "Following"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(forYouPosts),
          _buildPostList(followingPosts),
        ],
      ),
    );
  }
}
