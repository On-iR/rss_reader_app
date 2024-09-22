import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // 特定のRSSフィードURLを指定してください
  final String feedUrl = 'https://example.com/rss';

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

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading:
                item.media?.contents != null && item.media!.contents!.isNotEmpty
                    ? Image.network(
                        item.media!.contents!.first.url ?? '',
                        width: 60,
                        fit: BoxFit.cover,
                      )
                    : null,
            title: Text(
              item.title ?? 'タイトルなし',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  item.description
                          ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') ??
                      '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
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
