// lib/widgets/feed_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/feed_item.dart';

/// フィードアイテムを表示するカードウィジェット
class FeedCard extends StatelessWidget {
  final FeedItem item;
  final bool showImages;

  const FeedCard({
    Key? key,
    required this.item,
    required this.showImages,
  }) : super(key: key);

  /// リンクを開く関数
  Future<void> _openLink(BuildContext context) async {
    final url = item.link;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画像の高さを決定
    final double imageHeight = showImages ? 200.0 : 0.0;

    // 現在のテーマに基づいてテキストカラーを設定
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return GestureDetector(
      onTap: () => _openLink(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // カードの角丸を設定
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showImages &&
                item.imageUrl != null &&
                item.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover, // 画像がコンテナ全体を覆うように設定
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/default_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (showImages && (item.imageUrl == null || item.imageUrl!.isEmpty))
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: Image.asset(
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                        decoration: TextDecoration.underline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor),
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
