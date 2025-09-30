import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, List<String>> categories = {
    "For You": [
      "AI is reshaping the future of work.",
      "Flutter 4.0 rumored to support native desktop widgets.",
      "Indonesia's tech startups see record growth in 2025.",
    ],
    "Trending": [
      "Cat videos dominate social media again.",
      "Rashford's brace stuns Barcelona fans.",
      "OpenAI's new model breaks efficiency records.",
    ],
    "News": [
      "NASA confirms water traces on Mars surface found again.",
      "Apple to release a new AI-powered iPhone with advanced features.",
      "Amazon expands drone delivery program to more cities.",
    ],
  };

  String currentTab = "For You";
  List<String> filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.keys.length, vsync: this);
    filteredPosts = categories[currentTab] ?? [];
    _searchController.addListener(_filterPosts);
    _tabController.addListener(() {
      setState(() {
        currentTab = categories.keys.elementAt(_tabController.index);
        _filterPosts();
      });
    });
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    final allPosts = categories[currentTab] ?? [];
    setState(() {
      filteredPosts = allPosts
          .where((post) => post.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPost(String post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        post,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search X",
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.white),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: categories.keys.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categories.keys.map((category) {
          return ListView.builder(
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) => _buildPost(filteredPosts[index]),
          );
        }).toList(),
      ),
    );
  }
}
