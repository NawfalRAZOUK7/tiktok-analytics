import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy \'at\' h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (post.videoLink != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launchUrl(post.videoLink!),
              tooltip: 'Open in TikTok',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (post.coverUrl != null)
              CachedNetworkImage(
                imageUrl: post.coverUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      height: 300,
                      color: Colors.grey.shade300,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 300,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.video_library, size: 64)),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badges
                  Wrap(
                    spacing: 8,
                    children: [
                      if (post.isPinned)
                        Chip(
                          label: const Text('Pinned'),
                          avatar: const Icon(Icons.push_pin, size: 16),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      if (post.isPrivate)
                        Chip(
                          label: const Text('Private'),
                          avatar: const Icon(Icons.lock, size: 16),
                          backgroundColor: Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metrics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildMetricRow(
                            icon: Icons.favorite,
                            iconColor: Colors.red,
                            label: 'Likes',
                            value: _formatNumber(post.likes),
                          ),
                          const Divider(),
                          _buildMetricRow(
                            icon: Icons.remove_red_eye,
                            iconColor: Colors.blue,
                            label: 'Views',
                            value: _formatNumber(post.views ?? 0),
                          ),
                          const Divider(),
                          _buildMetricRow(
                            icon: Icons.comment,
                            iconColor: Colors.green,
                            label: 'Comments',
                            value: _formatNumber(post.comments ?? 0),
                          ),
                          const Divider(),
                          _buildMetricRow(
                            icon: Icons.share,
                            iconColor: Colors.orange,
                            label: 'Shares',
                            value: _formatNumber(post.shares ?? 0),
                          ),
                          if (post.duration != null) ...[
                            const Divider(),
                            _buildMetricRow(
                              icon: Icons.access_time,
                              iconColor: Colors.purple,
                              label: 'Duration',
                              value: post.formattedDuration,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Engagement Metrics
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Engagement Metrics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Total Engagement',
                            _formatNumber(post.totalEngagement ?? 0),
                          ),
                          _buildInfoRow(
                            'Engagement Ratio',
                            '${((post.engagementRatio ?? 0) * 100).toStringAsFixed(2)}%',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hashtags
                  if (post.hashtags.isNotEmpty) ...[
                    const Text(
                      'Hashtags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          post.hashtags
                              .map(
                                (tag) => Chip(
                                  label: Text('#$tag'),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Metadata
                  const Text(
                    'Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('Post ID', post.postId),
                          _buildInfoRow(
                            'Published',
                            dateFormat.format(post.date),
                          ),
                          if (post.videoLink != null)
                            _buildLinkRow(
                              'Video Link',
                              post.videoLink!,
                              context,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String url, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          TextButton(
            onPressed: () => _launchUrl(url),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }
}
