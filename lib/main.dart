import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'package:snap_friend/services/storage_service.dart';
import 'package:snap_friend/services/auth_service.dart';
import 'package:snap_friend/services/firestore_service.dart';
import 'package:snap_friend/pages/posts_page.dart';
import 'package:snap_friend/pages/qr_show_page.dart';
import 'package:snap_friend/pages/qr_scan_page.dart';
import 'package:snap_friend/pages/friend_requests_page.dart';
import 'package:snap_friend/pages/friends_page.dart';
import 'package:snap_friend/pages/sign_in_page.dart';
import 'package:snap_friend/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;

    return MaterialApp(
      title: 'SnapFriend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          if (user == null) {
            return SignInPage(
              authService: authService,
              onSignedIn: () {
                (context as Element).reassemble();
              },
            );
          }
          return MyHomePage(
            title: 'SnapFriend',
            authService: authService,
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final AuthService authService;

  const MyHomePage({
    super.key,
    required this.title,
    required this.authService,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  final _storageService = StorageService();

  Future<void> _pickImageAndUpload() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() => _image = file);

      final uid = widget.authService.currentUser!.uid;
      final url = await _storageService.uploadImage(file, uid);

      if (!mounted) return;

      if (url != null) {
        await FirestoreService.addPost(
          imageUrl: url,
          caption: '',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 投稿を保存しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ アップロードに失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: _image == null
            ? const Text("画像が未選択です")
            : Image.file(_image!),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'upload',
            onPressed: _pickImageAndUpload,
            tooltip: '画像を選択・アップロード',
            child: const Icon(Icons.upload),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'posts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostsPage()),
              );
            },
            tooltip: '投稿履歴を表示',
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'qr',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrShowPage()),
              );
            },
            tooltip: 'QRを表示',
            child: const Icon(Icons.qr_code),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrScanPage(authService: widget.authService),
                ),
              );
            },
            tooltip: 'QRを読み取る',
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'friend_requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FriendRequestsPage(),
                ),
              );
            },
            tooltip: 'フレンド申請一覧',
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'friends',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FriendsPage(),
                ),
              );
            },
            tooltip: '友だち一覧',
            child: const Icon(Icons.group),
          ),
        ],
      ),
    );
  }
}
