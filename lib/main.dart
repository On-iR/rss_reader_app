import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';

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
    if (_feed == null) {
      return Center(child: Text('フィードの読み込みに失敗しました'));
    }

    return ListView.builder(
      itemCount: _feed!.items!.length,
      itemBuilder: (context, index) {
        final item = _feed!.items![index];
        return ListTile(
          title: Text(item.title ?? 'タイトルなし'),
          subtitle: Text(item.pubDate?.toLocal().toString() ?? '日付なし'),
          onTap: () {
            // 詳細ページへの遷移やリンクを開く処理をここに追加できます
          },
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
            : _buildFeedList());
  }
}
