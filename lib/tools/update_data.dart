import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<void> updateCommunityNamesToLowercase() async {
  print("Starting community name update...");

  // 1. Ambil semua dokumen dari koleksi 'communities'
  final QuerySnapshot snapshot = await _db.collection('communities').get();

  // 2. Gunakan WriteBatch untuk efisiensi dan atomicity (semua berhasil atau semua gagal)
  final WriteBatch batch = _db.batch();
  int count = 0;

  for (var doc in snapshot.docs) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String? name = data['name'] as String?;

    if (name != null && name.isNotEmpty) {
      final String nameLower = name.toLowerCase();

      // HANYA update jika field name_lower belum ada atau berbeda
      if (data['name_lower'] == null || data['name_lower'] != nameLower) {
        // Tambahkan operasi update ke batch
        batch.update(doc.reference, {'name_lower': nameLower});
        count++;
      }
    }
  }

  if (count > 0) {
    // 3. Commit (Terapkan) semua perubahan sekaligus
    await batch.commit();
    print("Successfully updated $count community documents with 'name_lower'.");
  } else {
    print("No updates necessary.");
  }
}

// Catatan: Anda dapat menjalankan fungsi ini sekali dari main() Anda
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await updateCommunityNamesToLowercase();
  print("Update process finished.");
  // Setelah selesai, Anda dapat menghapus pemanggilan fungsi ini dari main.
}
*/
