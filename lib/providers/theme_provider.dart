// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';

/// テーマの状態を管理するプロバイダークラス
class ThemeProvider with ChangeNotifier {
  /// 現在のテーマモード
  ThemeMode _themeMode = ThemeMode.light;

  /// 現在のテーマモードを取得
  ThemeMode get themeMode => _themeMode;

  /// テーマモードを設定
  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
