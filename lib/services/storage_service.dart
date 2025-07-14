import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

class StorageService {
  /// ✅ 投稿画像をアップロード（Storageルールに対応するownerIdを付与）
  Future<String?> uploadImage(File file, String uid) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileExtension = file.path.split('.').last;
      final fileName = '$timestamp.$fileExtension';

      final path = 'postImages/$uid/$fileName'; // ← アップロード先を明確に
      final ref = FirebaseStorage.instance.ref().child(path);

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      print('📦 MIME TYPE: $mimeType');

      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'ownerId': uid, // ← Storageルール用のセキュリティキー
        },
      );

      await ref.putFile(file, metadata);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Storage upload failed: $e');
      return null;
    }
  }

  /// 🔽 プロフィール画像用（ファイル名固定、公開）
  Future<String?> uploadProfileIcon(File file, String uid) async {
    try {
      final path = 'userIcons/$uid.jpg'; // ← パスも明確に
      final ref = FirebaseStorage.instance.ref().child(path);

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final metadata = SettableMetadata(contentType: mimeType);

      await ref.putFile(file, metadata);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ アイコンアップロード失敗: $e');
      return null;
    }
  }
}
