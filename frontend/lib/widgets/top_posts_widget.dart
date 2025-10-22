import 'package:flutter/material.dart';
import '../models/analytics.dart';
import 'package:intl/intl.dart';

class TopPostsWidget extends StatelessWidget {
  final TopPostsByTimeResponse data;

  const TopPostsWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Posts by Time Window',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Window: ${data.window} | Metric: ${data.metric} | Limit: ${data.limit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time periods
          if (data.data.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No top posts data available'),
                ),
              ),
            )
          else
            ...data.data.map((period) => _buildPeriodCard(context, period)),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(BuildContext context, TopPostsByTime period) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          period.periodLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${period.topPosts.length} posts'),
        initiallyExpanded: true,
        children: [
          if (period.topPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No posts in this period'),
            )
          else
            ...period.topPosts.asMap().entries.map((entry) {
              final index = entry.key;
              final post = entry.value as Map<String, dynamic>;
              return _buildPostTile(context, post, index + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildPostTile(BuildContext context, Map<String, dynamic> post, int rank) {
    final title = post['title'] as String? ?? 'Untitled';
    final likes = post['likes'] as int? ?? 0;
    final views = post['views'] as int? ?? 0;
    final date = post['date'] as String?;
    final videoUrl = post['video_url'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRankColor(rank),
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.favorite, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(NumberFormat.compact().format(likes)),
              const SizedBox(width: 16),
              const Icon(Icons.visibility, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text(NumberFormat.compact().format(views)),
            ],
          ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('MMM d, yyyy').format(DateTime.parse(date)),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
      trailing: videoUrl != null
          ? IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {
                // Could open video URL here
              },
            )
          : null,
      isThreeLine: true,
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.blue;
    }
  }
}
