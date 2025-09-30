// import 'package:flutter/material.dart';
// import 'community_profile_page.dart'; // Kita tetap butuh ini untuk navigasi

// class CommunityPage extends StatefulWidget {
//   const CommunityPage({super.key});

//   @override
//   State<CommunityPage> createState() => _CommunityPageState();
// }

// class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   // DATA DUMMY UNTUK DAFTAR KOMUNITAS
//   final List<Map<String, dynamic>> dummyCommunities = [
//     {
//       "id": "comm_1",
//       "name": "Flutter Enthusiasts",
//       "description": "Komunitas untuk para pengembang Flutter dari semua level...",
//       "category": "Technology",
//       "memberCount": 1234
//     },
//     {
//       "id": "comm_2",
//       "name": "Indo Gamers Hub",
//       "description": "Tempat kumpul para gamer Indonesia! Diskusi game terbaru...",
//       "category": "Gaming",
//       "memberCount": 5678
//     },
//     {
//       "id": "comm_3",
//       "name": "Pecinta Kopi Nusantara",
//       "description": "Dari Sabang sampai Merauke, mari berbagi cerita...",
//       "category": "Lifestyle",
//       "memberCount": 910
//     }
//   ];

//   // DATA DUMMY UNTUK POSTINGAN DI TAB FOLLOWING
//   final List<Map<String, dynamic>> dummyPosts = [
//     {
//       "user": "DogeDesigner",
//       "handle": "@cb_doge",
//       "content": "Excited to join the Flutter Enthusiasts community!",
//     },
//     {
//       "user": "GamerPro",
//       "handle": "@pro_gamer",
//       "content": "Looking for a team to play Valorant tonight. #IndoGamersHub",
//     }
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text("Community"),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           labelColor: Colors.white,
//           unselectedLabelColor: Colors.grey,
//           tabs: const [
//             Tab(text: "For You"),
//             Tab(text: "Following"),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // Tab "For You" menggunakan data dummyCommunities
//           ListView.builder(
//             itemCount: dummyCommunities.length,
//             itemBuilder: (context, index) {
//               final communityData = dummyCommunities[index];
//               return ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.group_work, color: Colors.white)),
//                 title: Text(communityData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                 subtitle: Text('${communityData['memberCount']} Members', style: const TextStyle(color: Colors.grey)),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => CommunityProfilePage(
//                         communityId: communityData['id'],
//                         communityData: communityData,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//           // Tab "Following" menggunakan data dummyPosts
//           ListView.builder(
//             itemCount: dummyPosts.length,
//             itemBuilder: (context, index) {
//               final postData = dummyPosts[index];
//               return Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: const BoxDecoration(
//                   border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
//                         const SizedBox(width: 10),
//                         Text(postData["user"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                         const SizedBox(width: 5),
//                         Text(postData["handle"], style: const TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(postData["content"], style: const TextStyle(color: Colors.white)),
//                   ],
//                 )
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }