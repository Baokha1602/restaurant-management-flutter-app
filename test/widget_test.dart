// Basic Flutter widget test for Restaurant Manager project.
//
// This test simply verifies that the main app starts
// and can build its first frame without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurantmanager/main.dart'; // ✅ đúng với name: restaurantmanager

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // 🧩 Build the main app
    await tester.pumpWidget(MyApp(startScreen: const SizedBox()));


    // ⏱ Chờ app dựng xong giao diện đầu tiên
    await tester.pumpAndSettle();

    // ✅ Kiểm tra xem có MaterialApp và Scaffold không (ứng dụng đã chạy)
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
