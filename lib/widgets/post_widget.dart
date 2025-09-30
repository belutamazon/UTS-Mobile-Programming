import 'package:flutter/material.dart';

class PostWidget extends StatelessWidget {
  final Map<String, dynamic> postData;
  const PostWidget({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    // Ambil nama penulis dari data, beri nilai default jika tidak ada
    final authorName = postData['authorName'] ?? 'a user';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konten postingan
          Text(
            postData["content"] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Menampilkan "by [Nama User]"
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "by $authorName",
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ),
        ],
      )
    );
  }
}