import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // 特定のフィードURLを指定してください（RSSまたはAtom）
  final String feedUrl = 'https://aws.amazon.com/jp/blogs/aws/feed/';

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

  FeedListPage({required this.feedUrl});

  @override
  _FeedListPageState createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  List<_FeedItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final response = await http.get(Uri.parse(widget.feedUrl));
      if (response.statusCode == 200) {
        var feed;
        try {
          // RSSフィードとして解析を試みる
          feed = RssFeed.parse(response.body);
        } catch (e) {
          // RSSでない場合、Atomフィードとして解析を試みる
          feed = AtomFeed.parse(response.body);
        }

        List<_FeedItem> items = [];
        if (feed is RssFeed) {
          items =
              feed.items!.map((item) => _FeedItem.fromRssItem(item)).toList();
        } else if (feed is AtomFeed) {
          items =
              feed.items!.map((item) => _FeedItem.fromAtomItem(item)).toList();
        }

        setState(() {
          _items = items;
          _isLoading = false;
        });
      } else {
        throw Exception('フィードの読み込みに失敗しました');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
        _items = [];
      });
    }
  }

  Widget _buildFeedList() {
    if (_items.isEmpty) {
      return Center(child: Text('フィードの読み込みに失敗しました'));
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        return GestureDetector(
          onTap: () async {
            final url = item.link;
            if (url != null && await canLaunch(url)) {
              await launch(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('リンクを開けませんでした')),
              );
            }
          },
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 画像部分
                if (item.imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title ?? 'タイトルなし',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item.description ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        item.pubDate ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('フィードリーダー'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFeed,
                child: _buildFeedList(),
              ));
  }
}

class _FeedItem {
  final String? title;
  final String? link;
  final String? description;
  final String? pubDate;
  final String? imageUrl;

  _FeedItem({
    this.title,
    this.link,
    this.description,
    this.pubDate,
    this.imageUrl,
  });

  // RSSアイテムからFeedItemを作成
  factory _FeedItem.fromRssItem(RssItem item) {
    // 日付のフォーマット
    String? formattedDate;
    if (item.pubDate != null) {
      formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(item.pubDate!);
    }

    // 画像URLの取得
    String? imageUrl;
    if (item.enclosure != null && item.enclosure!.url != null) {
      imageUrl = item.enclosure!.url;
    } else if (item.media?.contents != null &&
        item.media!.contents!.isNotEmpty) {
      imageUrl = item.media!.contents!.first.url;
    }

    // descriptionのHTMLタグを除去
    String? description =
        item.description?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

    return _FeedItem(
      title: item.title,
      link: item.link,
      description: description,
      pubDate: formattedDate,
      imageUrl: imageUrl,
    );
  }

  // AtomアイテムからFeedItemを作成
  factory _FeedItem.fromAtomItem(AtomItem item) {
    // 日付のフォーマット
    String? formattedDate;
    if (item.updated != null) {
      formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(item.updated!);
    } else if (item.published != null) {
      formattedDate =
          DateFormat('yyyy/MM/dd HH:mm').format(item.published! as DateTime);
    }

    // 画像URLの取得（Atomフィードではカスタム処理が必要な場合があります）
    String? imageUrl;
    if (item.media != null &&
        item.media!.contents != null &&
        item.media!.contents!.isNotEmpty) {
      imageUrl = item.media!.contents!.first.url;
    }

    // descriptionのHTMLタグを除去
    String? description =
        item.summary?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

    // リンクの取得
    String? link;
    if (item.links != null && item.links!.isNotEmpty) {
      link = item.links!.first.href;
    }

    return _FeedItem(
      title: item.title,
      link: link,
      description: description,
      pubDate: formattedDate,
      imageUrl: imageUrl,
    );
  }
}
