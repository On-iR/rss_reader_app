// lib/pages/feed_url_input_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/theme_provider.dart';
import 'feed_list_page.dart';

/// フィードURLを入力する画面
class FeedUrlInputPage extends StatefulWidget {
  const FeedUrlInputPage({Key? key}) : super(key: key);

  @override
  State<FeedUrlInputPage> createState() => _FeedUrlInputPageState();
}

class _FeedUrlInputPageState extends State<FeedUrlInputPage> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 初期値を設定
    _controller = TextEditingController(text: 'https://zenn.dev/feed');
  }

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
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // フィードを読み込む
      await Provider.of<FeedProvider>(context, listen: false).loadFeed(feedUrl);

      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      if (feedProvider.errorMessage != null) {
        setState(() {
          _errorMessage = feedProvider.errorMessage;
        });
      } else {
        // フィードリストページへ遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedListPage(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'フィードの読み込み中にエラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードURLを入力'),
        actions: [
          const Icon(Icons.dark_mode),
          Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                          labelText: 'フィードURL',
                          hintText: 'https://example.com/feed',
                          border: const OutlineInputBorder(),
                          hintStyle: TextStyle(color: Colors.grey.shade400)),
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
