// lib/pages/feed_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_card.dart';

/// フィードの一覧を表示する画面
class FeedListPage extends StatelessWidget {
  const FeedListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フィード一覧'),
        actions: [
          Row(
            children: [
              const Text('画像表示'),
              Switch(
                value: feedProvider.showImages,
                onChanged: (value) {
                  feedProvider.showImages = value;
                },
              ),
            ],
          ),
        ],
      ),
      body: feedProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () {
                if (feedProvider.feedUrl != null &&
                    feedProvider.feedUrl!.isNotEmpty) {
                  return feedProvider.loadFeed(feedProvider.feedUrl!);
                } else {
                  return Future.value();
                }
              },
              child: feedProvider.items.isEmpty
                  ? const Center(child: Text('フィードの読み込みに失敗しました'))
                  : ListView.builder(
                      itemCount: feedProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = feedProvider.items[index];
                        return FeedCard(
                          item: item,
                          showImages: feedProvider.showImages,
                        );
                      },
                    ),
            ),
    );
  }
}
