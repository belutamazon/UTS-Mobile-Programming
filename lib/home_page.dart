import 'package:flutter/material.dart';
// Asumsi Anda memiliki file-file ini di proyek Anda
// Anda mungkin perlu menyesuaikan path import sesuai struktur proyek Anda
import 'community_list_page.dart'; 
import 'create_post_page.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'users_page.dart';   

// Placeholder pages untuk menghindari error jika file tidak ada
class SearchPage extends StatelessWidget { const SearchPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("Search Page", style: TextStyle(color: Colors.white)));}
// CommunityPage sekarang digunakan untuk notifikasi sesuai kode lama, bisa diganti widget khusus notifikasi
class NotificationPage extends StatelessWidget { const NotificationPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("Notifications Page", style: TextStyle(color: Colors.white)));}
class MessagesPage extends StatelessWidget { const MessagesPage({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("Messages Page", style: TextStyle(color: Colors.white)));}


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
  
  // ✅ KODE DIPERBAIKI DI SINI
  final List<Widget> _pages = [
    const Center(child: Text("Placeholder for Home")), // Index 0, tidak terpakai oleh body utama
    const SearchPage(),                                // Index 1: Search
    const CommunityListPage(),                         // Index 2: Community
    // BENAR: Index 3 sekarang adalah halaman Notifikasi
    const Center(
      child: Text("Notifications Page", style: TextStyle(color: Colors.white)),
    ),
    // BENAR: Index 4 sekarang adalah halaman Pesan
    UsersPage(currentUserId: FirebaseAuth.instance.currentUser!.uid),
  ];

  Widget buildPost(Map<String, dynamic> postData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                postData["user"] ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Text(postData["handle"] ?? '@handle', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(postData["content"] ?? '', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(children: [
                Icon(Icons.comment, color: Colors.grey[400], size: 20),
                const SizedBox(width: 5),
                Text("${postData["comments"] ?? 0}", style: const TextStyle(color: Colors.grey)),
              ]),
              Row(children: [
                Icon(Icons.repeat, color: Colors.grey[400], size: 20),
                const SizedBox(width: 5),
                Text("${postData["reposts"] ?? 0}", style: const TextStyle(color: Colors.grey)),
              ]),
              Row(children: [
                Icon(Icons.favorite, color: Colors.grey[400], size: 20),
                const SizedBox(width: 5),
                Text("${postData["likes"] ?? 0}", style: const TextStyle(color: Colors.grey)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil ID pengguna saat ini di dalam method build agar selalu terbaru
    final currentUser = FirebaseAuth.instance.currentUser;

    // Jika karena suatu alasan user null (misalnya saat proses logout)
    // tampilkan loading untuk mencegah error.
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text("Z"),
        bottom: _selectedIndex == 0
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "For you"),
                  Tab(text: "Following"),
                ],
              )
            : null,
      ),
      // PERBAIKAN UTAMA: Menggunakan IndexedStack untuk menampilkan halaman
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Index 0: Home (dengan TabBarView)
          TabBarView(
            controller: _tabController,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('threads')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // ... (logika StreamBuilder Anda untuk postingan tidak perlu diubah)
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final posts = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final postData = posts[index].data() as Map<String, dynamic>;
                      return buildPost(postData);
                    },
                  );
                },
              ),
              const Center(child: Text("Following Feed", style: TextStyle(color: Colors.white))),
            ],
          ),
          // Index 1: Search
          const SearchPage(),
          // Index 2: Community
          const CommunityListPage(),
          // Index 3: Notifications
          const NotificationPage(),
          // Index 4: Messages
          // ID PENGGUNA SELALU DIAMBIL YANG TERBARU DAN BENAR DI SINI
          UsersPage(currentUserId: currentUser.uid),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePostPage()),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}