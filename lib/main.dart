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
              primarySwatch: Colors.lime, // 基本テーマをライムグリーンに設定
              brightness: Brightness.light,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.lime,
                foregroundColor: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.white,
              cardColor: Colors.white,
              elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lime, // ボタンの色をライムグリーンに設定
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontWeight: FontWeight.w900))),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black87),
                labelSmall: TextStyle(color: Colors.grey),
                labelLarge: TextStyle(color: Colors.white),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white; // 選択時のサムの色（ライトテーマ）
                  }
                  return Colors.grey; // 非選択時のサムの色
                }),
                trackColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.lime[700]!; // 選択時のトラックの色を濃いライムグリーンに設定
                  }
                  return Colors.grey.shade400; // 非選択時のトラックの色
                }),
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.lime, // ダークテーマでもライムグリーンを使用
              brightness: Brightness.dark,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.grey[900],
              cardColor: Colors.grey[800],
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lime, // ボタンの色をライムグリーンに設定
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontWeight: FontWeight.w900)),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
                labelSmall: TextStyle(color: Colors.grey),
                labelLarge: TextStyle(color: Colors.black),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.black; // 選択時のサムの色（ダークテーマ）
                  }
                  return Colors.grey; // 非選択時のサムの色
                }),
                trackColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.limeAccent; // 選択時のトラックの色をライムアクセントに設定
                  }
                  return Colors.grey.shade600; // 非選択時のトラックの色
                }),
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
