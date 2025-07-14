import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// あなたの UID を QR コードとして表示するページ
class QrShowPage extends StatelessWidget {
  const QrShowPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth から現在ユーザーの UID を取得
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('あなたのQRコード'),
        centerTitle: true,
      ),
      body: Center(
        child: Hero(
          tag: 'qr',
          child: QrImageView(
            data: uid,
            version: QrVersions.auto,
            size: 240.0,
            gapless: false,
            errorStateBuilder: (context, error) => const Center(
              child: Text('QRコードの生成に失敗しました'),
            ),
          ),
        ),
      ),
    );
  }
}
