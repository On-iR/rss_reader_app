import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 特定のフィードURLを指定してください（RSSまたはAtom）
  final String feedUrl = 'https://zenn.dev/feed';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'フィードリーダー',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FeedListPage(feedUrl: feedUrl),
    );
  }
}

class FeedListPage extends StatefulWidget {
  final String feedUrl;

  const FeedListPage({super.key, required this.feedUrl});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  final List<FeedItem> _items = [];
  bool _isLoading = true;
  bool _showImages = true; // 画像表示モードを管理する変数

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final response = await http.get(Uri.parse(widget.feedUrl));

      if (response.statusCode == 200) {
        // エンコーディングの検出とデコード
        final encoding = _detectEncoding(response.headers, response.bodyBytes);
        final content = encoding.decode(response.bodyBytes);

        var feed;
        try {
          // RSSフィードとして解析を試みる
          feed = RssFeed.parse(content);
        } catch (_) {
          // RSSでない場合、Atomフィードとして解析を試みる
          feed = AtomFeed.parse(content);
        }

        List<FeedItem> items = [];
        if (feed is RssFeed) {
          items = feed.items!
              .map((item) => FeedItem.fromRssItem(item))
              .toList(growable: false);
        } else if (feed is AtomFeed) {
          items = feed.items!
              .map((item) => FeedItem.fromAtomItem(item))
              .toList(growable: false);
        }

        setState(() {
          _items.clear();
          _items.addAll(items);
          _isLoading = false;
        });
      } else {
        throw Exception('フィードの読み込みに失敗しました');
      }
    } catch (e) {
      debugPrint('フィードの読み込み中にエラーが発生しました: $e');
      setState(() {
        _isLoading = false;
        _items.clear();
      });
    }
  }

  // エンコーディングの検出
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードリーダー'),
        actions: [
          Row(
            children: [
              const Text('画像表示'),
              Switch(
                value: _showImages,
                onChanged: (value) {
                  setState(() {
                    _showImages = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeed,
              child: _items.isEmpty
                  ? const Center(child: Text('フィードの読み込みに失敗しました'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return FeedCard(
                          item: item,
                          showImages: _showImages,
                        );
                      },
                    ),
            ),
    );
  }
}

class FeedItem {
  final String? title;
  final String? link;
  final String? description;
  final DateTime? pubDate; // DateTime 型に変更
  final String? imageUrl;

  FeedItem({
    this.title,
    this.link,
    this.description,
    this.pubDate,
    this.imageUrl,
  });

  // RSSアイテムからFeedItemを作成
  factory FeedItem.fromRssItem(RssItem item) {
    // 日付のフォーマット
    DateTime? pubDate = item.pubDate;

    // 画像URLの取得
    String? imageUrl;
    if (item.enclosure?.url != null) {
      imageUrl = item.enclosure!.url;
    } else if (item.media?.contents?.isNotEmpty == true) {
      imageUrl = item.media!.contents!.first.url;
    }

    // descriptionのHTMLタグを除去
    String? description =
        item.description?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

    return FeedItem(
      title: item.title,
      link: item.link,
      description: description,
      pubDate: pubDate,
      imageUrl: imageUrl,
    );
  }

  // AtomアイテムからFeedItemを作成
  factory FeedItem.fromAtomItem(AtomItem item) {
    // 日付のフォーマット
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
    String? description =
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

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final bool showImages;

  const FeedCard({
    super.key,
    required this.item,
    required this.showImages,
  });

  @override
  Widget build(BuildContext context) {
    // 画像の高さを決定
    final double imageHeight = showImages ? 200.0 : 0.0;

    return GestureDetector(
      onTap: () async {
        final url = item.link;
        if (url != null && await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リンクを開けませんでした')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // カードの角丸を設定
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showImages)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit
                              .cover, // BoxFit.contain から BoxFit.cover に変更
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/default_image.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/default_image.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? 'タイトルなし',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.pubDate != null
                        ? DateFormat('yyyy/MM/dd HH:mm').format(item.pubDate!)
                        : '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
