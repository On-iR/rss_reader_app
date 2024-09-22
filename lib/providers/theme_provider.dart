import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  /// 現在のテーマモード
  ThemeMode _themeMode = ThemeMode.light;

  /// SharedPreferencesのキー
  static const String _themeKey = 'theme_mode';

  /// コンストラクタでSharedPreferencesからテーマモードを読み込む
  ThemeProvider() {
    _loadThemeMode();
  }

  /// 現在のテーマモードを取得
  ThemeMode get themeMode => _themeMode;

  /// テーマモードを切り替え
  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    // 永続化
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_themeKey, isDarkMode);
  }

  /// SharedPreferencesからテーマモードを読み込む
  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
