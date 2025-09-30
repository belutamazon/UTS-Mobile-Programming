// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});

//   // DIUBAH: Dihilangkan kode untuk menampilkan foto
//   Widget buildPost(Map<String, dynamic> postData) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//            Row(
//             children: [
//               const CircleAvatar( // Ikon statis
//                 backgroundColor: Colors.grey,
//                 child: Icon(Icons.person, color: Colors.white),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 postData["user"] ?? 'User',
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(width: 5),
//               Text(postData["handle"] ?? '@handle', style: const TextStyle(color: Colors.grey)),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(postData["content"] ?? '', style: const TextStyle(color: Colors.white)),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final User? currentUser = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("Profile"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//               if(context.mounted) {
//                 Navigator.of(context).popUntil((route) => route.isFirst);
//               }
//             },
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 // DIUBAH: Dihilangkan kode untuk menampilkan foto
//                 const CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.grey,
//                   child: Icon(Icons.person, color: Colors.white, size: 40),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'No Name', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
//                 Text(currentUser?.email ?? 'No Email', style: const TextStyle(color: Colors.grey, fontSize: 16)),
//               ],
//             ),
//           ),
//           const Divider(color: Colors.grey),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('threads')
//                   .where('authorId', isEqualTo: currentUser?.uid)
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                  if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text("You haven't posted anything yet.", style: TextStyle(color: Colors.white)));
//                 }
                
//                 final posts = snapshot.data!.docs;
//                 return ListView.builder(
//                   itemCount: posts.length,
//                   itemBuilder: (context, index) {
//                     final postData = posts[index].data() as Map<String, dynamic>;
//                     return buildPost(postData);
//                   },
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // DIUBAH: Dihilangkan kode untuk menampilkan foto
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
              const CircleAvatar( // Ikon statis
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                postData["user"] ?? 'User',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              Text(postData["handle"] ?? '@handle', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(postData["content"] ?? '', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if(context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // DIUBAH: Dihilangkan kode untuk menampilkan foto
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'No Name', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(currentUser?.email ?? 'No Email', style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('threads')
                  .where('authorId', isEqualTo: currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("You haven't posted anything yet.", style: TextStyle(color: Colors.white)));
                }
                
                final posts = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final postData = posts[index].data() as Map<String, dynamic>;
                    return buildPost(postData);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}