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
  // 特定のRSSフィードURLを指定してください
  final String feedUrl = 'https://zenn.dev/feed';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSSリーダー',
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
  RssFeed? _feed;
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
        final feed = RssFeed.parse(response.body);
        setState(() {
          _feed = feed;
          _isLoading = false;
        });
      } else {
        throw Exception('フィードの読み込みに失敗しました');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
        _feed = null;
      });
    }
  }

  Widget _buildFeedList() {
    if (_feed == null || _feed!.items == null) {
      return Center(child: Text('フィードの読み込みに失敗しました'));
    }

    return ListView.builder(
      itemCount: _feed!.items!.length,
      itemBuilder: (context, index) {
        final item = _feed!.items![index];

        // 日付のフォーマット
        String formattedDate = '';
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
                if (imageUrl != null)
                  Container(
                    height: 200, // 高さを調整してください
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
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
                        item.description
                                ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ??
                            '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        formattedDate,
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
          title: Text('RSSフィード'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFeed,
                child: _buildFeedList(),
              ));
  }
}
