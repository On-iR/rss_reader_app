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

/// アプリケーションのルートウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'フィードリーダー',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FeedUrlInputPage(),
    );
  }
}

/// フィードURLを入力する画面
class FeedUrlInputPage extends StatefulWidget {
  const FeedUrlInputPage({super.key});

  @override
  State<FeedUrlInputPage> createState() => _FeedUrlInputPageState();
}

class _FeedUrlInputPageState extends State<FeedUrlInputPage> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// フィードURLを送信し、フィードを読み込む
  Future<void> _submitUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String feedUrl = _controller.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // URLの検証
    final uri = Uri.tryParse(feedUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      setState(() {
        _isLoading = false;
        _errorMessage = '有効なURLを入力してください。';
      });
      return;
    }

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // エンコーディングの検出とデコード
        final encoding = _detectEncoding(response.headers, response.bodyBytes);
        final content = encoding.decode(response.bodyBytes);

        try {
          // RSSフィードとして解析を試みる
          RssFeed.parse(content);
        } catch (_) {
          try {
            // RSSでない場合、Atomフィードとして解析を試みる
            AtomFeed.parse(content);
          } catch (e) {
            throw Exception('RSSまたはAtom形式のフィードではありません。');
          }
        }

        // フィードの解析が成功したら _isLoading を false に設定
        setState(() {
          _isLoading = false;
        });

        // フィードリストページへ遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedListPage(feedUrl: feedUrl),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'フィードの読み込みに失敗しました。ステータスコード: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'フィードの読み込み中にエラーが発生しました: $e';
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードURLを入力'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'フィードURL',
                        hintText: 'https://example.com/feed',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'フィードURLを入力してください。';
                        }
                        final uri = Uri.tryParse(value.trim());
                        if (uri == null || !uri.hasAbsolutePath) {
                          return '有効なURLを入力してください。';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitUrl,
                      child: const Text('フィードを読み込む'),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// フィードの一覧を表示する画面
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

  /// フィードを読み込み、フィードアイテムをリストに追加
  Future<void> _loadFeed() async {
    try {
      final uri = Uri.tryParse(widget.feedUrl);
      if (uri == null) {
        throw Exception('無効なフィードURLです。');
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // エンコーディングの検出とデコード
        final encoding = _detectEncoding(response.headers, response.bodyBytes);
        final content = encoding.decode(response.bodyBytes);

        try {
          // RSSフィードとして解析を試みる
          final feed = RssFeed.parse(content);
          _items.addAll(feed.items!
              .map((item) => FeedItem.fromRssItem(item))
              .toList(growable: false));
        } catch (_) {
          try {
            // RSSでない場合、Atomフィードとして解析を試みる
            final feed = AtomFeed.parse(content);
            _items.addAll(feed.items!
                .map((item) => FeedItem.fromAtomItem(item))
                .toList(growable: false));
          } catch (e) {
            throw Exception('RSSまたはAtom形式のフィードではありません。');
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('フィードの読み込みに失敗しました。ステータスコード: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('フィードの読み込み中にエラーが発生しました: $e');
      setState(() {
        _isLoading = false;
        _items.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フィードの読み込みに失敗しました: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィード一覧'),
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

/// フィードアイテムのデータモデル
class FeedItem {
  final String? title;
  final String? link;
  final String? description;
  final DateTime? pubDate; // DateTime 型
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

/// フィードアイテムを表示するカードウィジェット
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
                          fit: BoxFit.cover, // 画像がコンテナ全体を覆うように設定
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
