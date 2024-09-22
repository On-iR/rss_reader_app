// lib/models/feed_item.dart

import 'package:webfeed_plus/webfeed_plus.dart';

/// フィードアイテムのデータモデル
class FeedItem {
  final String? title;
  final String? link;
  final String? description;
  final DateTime? pubDate;
  final String? imageUrl;

  FeedItem({
    this.title,
    this.link,
    this.description,
    this.pubDate,
    this.imageUrl,
  });

  /// RSSフィードアイテムからFeedItemを作成
  factory FeedItem.fromRssItem(RssItem item) {
    // 日付の取得
    final pubDate = item.pubDate;

    // 画像URLの取得
    String? imageUrl;
    if (item.enclosure?.url != null) {
      imageUrl = item.enclosure!.url;
    } else if (item.media?.contents?.isNotEmpty == true) {
      imageUrl = item.media!.contents!.first.url;
    }

    // descriptionのHTMLタグを除去
    final description =
        item.description?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

    return FeedItem(
      title: item.title,
      link: item.link,
      description: description,
      pubDate: pubDate,
      imageUrl: imageUrl,
    );
  }

  /// AtomフィードアイテムからFeedItemを作成
  factory FeedItem.fromAtomItem(AtomItem item) {
    // 日付の取得とパース
    DateTime? pubDate;
    if (item.updated != null) {
      pubDate = item.updated;
    } else if (item.published != null) {
      pubDate = DateTime.tryParse(item.published!);
    }

    // 画像URLの取得
    String? imageUrl;
    if (item.media?.contents?.isNotEmpty == true) {
      imageUrl = item.media!.contents!.first.url;
    }

    // descriptionのHTMLタグを除去
    final description =
        item.summary?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

    // リンクの取得（Atomフィードのリンクはリストであるため、最初のリンクを使用）
    String? link;
    if (item.links?.isNotEmpty == true) {
      link = item.links!.first.href;
    }

    return FeedItem(
      title: item.title,
      link: link,
      description: description,
      pubDate: pubDate,
      imageUrl: imageUrl,
    );
  }
}
