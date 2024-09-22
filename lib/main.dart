// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/feed_provider.dart';
import 'providers/theme_provider.dart';
import 'pages/feed_url_input_page.dart';

void main() {
  runApp(const MyApp());
}

/// アプリケーションのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FeedProvider>(
          create: (_) => FeedProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'フィードリーダー',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              // 必要に応じてカスタムライトテーマを追加
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
              // 必要に応じてカスタムダークテーマを追加
            ),
            themeMode: themeProvider.themeMode, // 現在のテーマモードを設定
            home: const FeedUrlInputPage(),
          );
        },
      ),
    );
  }
}
