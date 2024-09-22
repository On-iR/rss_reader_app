// lib/services/feed_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/feed_item.dart';

/// フィードの取得と解析を行うサービスクラス
class FeedService {
  /// フィードURLからFeedItemのリストを取得
  Future<List<FeedItem>> fetchFeed(String feedUrl) async {
    final uri = Uri.tryParse(feedUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      throw Exception('有効なURLを入力してください。');
    }

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('フィードの読み込みに失敗しました。ステータスコード: ${response.statusCode}');
    }

    // エンコーディングの検出とデコード
    final encoding = _detectEncoding(response.headers, response.bodyBytes);
    final content = encoding.decode(response.bodyBytes);

    try {
      // RSSフィードとして解析を試みる
      final rssFeed = RssFeed.parse(content);
      return rssFeed.items!
          .map((item) => FeedItem.fromRssItem(item))
          .toList(growable: false);
    } catch (_) {
      try {
        // RSSでない場合、Atomフィードとして解析を試みる
        final atomFeed = AtomFeed.parse(content);
        return atomFeed.items!
            .map((item) => FeedItem.fromAtomItem(item))
            .toList(growable: false);
      } catch (e) {
        throw Exception('RSSまたはAtom形式のフィードではありません。');
      }
    }
  }

  /// HTTPレスポンスヘッダーからエンコーディングを検出
  Encoding _detectEncoding(Map<String, String> headers, List<int> bodyBytes) {
    final contentType = headers['content-type'];
    if (contentType != null) {
      final charsetMatch = RegExp(r'charset=([\w-]+)').firstMatch(contentType);
      if (charsetMatch != null) {
        final charset = charsetMatch.group(1);
        if (charset != null) {
          final encoding = Encoding.getByName(charset);
          if (encoding != null) {
            return encoding;
          }
        }
      }
    }
    // デフォルトはUTF-8
    return utf8;
  }
}
