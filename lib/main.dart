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
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.white,
              cardColor: Colors.white,
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black87),
                labelSmall: TextStyle(color: Colors.grey),
                labelLarge: TextStyle(color: Colors.white),
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.grey[900],
              cardColor: Colors.grey[800],
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
                labelSmall: TextStyle(color: Colors.grey),
                labelLarge: TextStyle(color: Colors.black),
              ),
            ),
            themeMode: themeProvider.themeMode, // 現在のテーマモードを設定
            home: const FeedUrlInputPage(),
          );
        },
      ),
    );
  }
}
