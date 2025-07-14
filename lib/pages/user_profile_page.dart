import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snap_friend/services/friend_request_service.dart';
import 'package:snap_friend/pages/edit_profile_page.dart';

class UserProfilePage extends StatefulWidget {
  final String otherUid;

  const UserProfilePage({super.key, required this.otherUid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  bool _isFriend = false;
  bool _isRequested = false;
  bool _isSelf = false;
  bool _isPrivate = false;
  bool _isFollower = false;
  bool _isAnon = false;

  String? _displayName;
  String? _iconURL;
  String? _bio;

  late final String myUid;

  @override
  void initState() {
    super.initState();
    myUid = FirebaseAuth.instance.currentUser!.uid;
    _initProfile();
  }

  Future<void> _initProfile() async {
    try {
      _isSelf = (widget.otherUid == myUid);
      _isAnon = FirebaseAuth.instance.currentUser!.isAnonymous;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUid)
          .get();

      final data = userDoc.data();
      final displayName = data?['displayName'] ?? '名前未設定';
      final iconURL = data?['iconURL'] ?? '';
      final bio = data?['bio'] ?? '';
      final isPrivate = data?['isPrivate'] ?? false;

      bool isFollowing = false;
      if (!_isSelf) {
        final followDoc = await FirebaseFirestore.instance
            .collection('followers')
            .doc(widget.otherUid)
            .collection('users')
            .doc(myUid)
            .get();
        isFollowing = followDoc.exists;

        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('friends')
            .doc(widget.otherUid)
            .get();

        final requestDoc = await FirebaseFirestore.instance
            .collection('friendRequests')
            .doc(widget.otherUid)
            .collection('received')
            .doc(myUid)
            .get();

        _isFriend = friendDoc.exists;
        _isRequested = requestDoc.exists;
      }

      setState(() {
        _displayName = displayName;
        _iconURL = iconURL;
        _bio = bio;
        _isPrivate = isPrivate;
        _isFollower = isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _sendRequest() async {
    await FriendRequestService.sendRequest(widget.otherUid);
    setState(() {
      _isRequested = true;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ フレンド申請を送信しました')),
      );
    }
  }

  Future<void> _showUpgradeDialog() async {
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📧 本登録（メール＆パスワード）'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passCtl,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtl.text.trim();
              final pass = passCtl.text.trim();
              if (email.isEmpty || pass.isEmpty) return;

              try {
                final cred = EmailAuthProvider.credential(
                  email: email,
                  password: pass,
                );
                await FirebaseAuth.instance.currentUser!
                    .linkWithCredential(cred);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  setState(() => _isAnon = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ 本登録に成功しました')),
                  );
                }
              } on FirebaseAuthException catch (e) {
                final msg = _mapAuthError(e.code);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'そのメールアドレスは既に使われています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードは6文字以上にしてください';
      case 'requires-recent-login':
        return 'もう一度ログインが必要です';
      default:
        return '予期せぬエラーが発生しました（$code）';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isBlocked = _isPrivate && !_isSelf && !_isFollower;

    if (isBlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('ユーザープロフィール')),
        body: const Center(
          child: Text('このアカウントは非公開です'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelf ? 'プロフィール（自分）' : 'ユーザープロフィール'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: _iconURL != null && _iconURL!.isNotEmpty
                  ? NetworkImage(_iconURL!)
                  : null,
              child: _iconURL == null || _iconURL!.isEmpty
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _displayName ?? '（名前不明）',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_bio != null && _bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _bio!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('UID: ${widget.otherUid}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 24),
            if (_isSelf && _isAnon)
              ElevatedButton(
                onPressed: _showUpgradeDialog,
                child: const Text('📧 本登録する'),
              )
            else if (_isSelf)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfilePage(),
                    ),
                  );
                },
                child: const Text('プロフィールを編集する'),
              )
            else if (_isFriend)
              const Text('👫 すでにフレンドです')
            else if (_isRequested)
              const Text('⏳ 申請中です')
            else
              ElevatedButton(
                onPressed: _sendRequest,
                child: const Text('フレンド申請を送る'),
              ),
          ],
        ),
      ),
    );
  }
}