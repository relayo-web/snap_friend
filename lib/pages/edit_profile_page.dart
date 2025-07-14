import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_friend/services/storage_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isSaving = false;
  bool _isPrivate = false; // 🔑 鍵アカ設定の状態変数

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['displayName'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _isPrivate = data['isPrivate'] ?? false;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await StorageService().uploadImage(_imageFile!, uid);
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'displayName': _nameController.text,
      'bio': _bioController.text,
      'isPrivate': _isPrivate, // ✅ 鍵アカ設定を保存
      if (imageUrl != null) 'iconURL': imageUrl,
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ プロフィールを保存しました')),
      );
      Navigator.pop(context); // 戻る
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィールを編集')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(Icons.add_a_photo, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '名前'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'ひとこと'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('アカウントを非公開にする'),
                    subtitle: const Text('フォロワー以外に投稿やプロフィールが表示されなくなります'),
                    value: _isPrivate,
                    onChanged: (val) {
                      setState(() => _isPrivate = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('保存する'),
                  ),
                ],
              ),
            ),
    );
  }
}
