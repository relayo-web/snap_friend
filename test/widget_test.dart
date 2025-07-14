import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_friend/main.dart';

/// モックの AuthService を作成（実際の AuthService に合わせて実装を増やせます）
class MockAuthService {
  // 必要ならメソッドを追加
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // モック認証サービスを用意
    final mockAuthService = MockAuthService();

    // MyApp に authService を渡してビルド
    await tester.pumpWidget(MyApp(authService: mockAuthService));

    // 初期値は 0 であることを確認
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // ＋ ボタンをタップして再描画
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // カウントが 1 に増えていることを確認
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
