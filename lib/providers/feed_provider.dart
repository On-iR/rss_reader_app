// lib/providers/feed_provider.dart

import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../services/feed_service.dart';

/// フィードの状態を管理するプロバイダークラス
class FeedProvider with ChangeNotifier {
  final FeedService _feedService = FeedService();

  List<FeedItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showImages = true; // 画像表示状態を追加

  List<FeedItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showImages => _showImages;

  /// 画像表示状態を設定
  set showImages(bool value) {
    _showImages = value;
    notifyListeners();
  }

  /// フィードを読み込み、状態を更新する
  Future<void> loadFeed(String feedUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedItems = await _feedService.fetchFeed(feedUrl);
      _items = fetchedItems;
    } catch (e) {
      _errorMessage = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
