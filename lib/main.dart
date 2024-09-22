// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/feed_provider.dart';
import 'pages/feed_url_input_page.dart';

void main() {
  runApp(const MyApp());
}

/// アプリケーションのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FeedProvider>(
      create: (_) => FeedProvider(),
      child: MaterialApp(
        title: 'フィードリーダー',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const FeedUrlInputPage(),
      ),
    );
  }
}
