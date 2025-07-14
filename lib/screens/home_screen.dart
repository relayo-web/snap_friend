import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import 'package:snap_friend/pages/notifications_page.dart'; // ✅ 絶対パスでインポート

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  String? _uploadedUrl;
  final picker = ImagePicker();
  final StorageService _storageService = StorageService();

  final String dummyUserId = "anonymousUser";

  Future<void> pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _selectedImage = file;
      });

      final url = await _storageService.uploadImage(file, dummyUserId);

      if (url != null) {
        setState(() {
          _uploadedUrl = url;
        });
        print('✅ アップロード成功: $url');
      } else {
        print('❌ アップロード失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像アップロード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsPage(), // ✅ 正しいクラス名
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : const Text('画像が選択されていません'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickAndUploadImage,
              child: const Text('画像を選択＆アップロード'),
            ),
            const SizedBox(height: 20),
            _uploadedUrl != null
                ? SelectableText('アップロード先URL:\n$_uploadedUrl')
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
