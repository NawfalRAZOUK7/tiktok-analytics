import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/follower.dart';

/// Reusable card widget for displaying a follower or following user
class FollowerCard extends StatelessWidget {
  final String username;
  final DateTime? dateFollowed;
  final DateTime? dateFollowing;
  final bool? isMutual;
  final VoidCallback? onTap;

  const FollowerCard({
    Key? key,
    required this.username,
    this.dateFollowed,
    this.dateFollowing,
    this.isMutual,
    this.onTap,
  }) : super(key: key);

  /// Factory constructor for Follower model
  factory FollowerCard.fromFollower(Follower follower, {VoidCallback? onTap}) {
    return FollowerCard(
      username: follower.username,
      dateFollowed: follower.dateFollowed,
      isMutual: follower.isMutual,
      onTap: onTap,
    );
  }

  /// Factory constructor for Following model
  factory FollowerCard.fromFollowing(Following following,
      {VoidCallback? onTap}) {
    return FollowerCard(
      username: following.username,
      dateFollowed: following.dateFollowed,
      isMutual: following.isMutual,
      onTap: onTap,
    );
  }

  /// Factory constructor for FollowerComparison model
  factory FollowerCard.fromComparison(FollowerComparison comparison,
      {VoidCallback? onTap}) {
    return FollowerCard(
      username: comparison.username,
      dateFollowed: comparison.dateFollowed,
      dateFollowing: comparison.dateFollowing,
      isMutual: comparison.isMutual,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap ?? () => _openTikTokProfile(username),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty
                        ? username[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Username and date info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@$username',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMutual == true) ...[
                          const SizedBox(width: 8),
                          _buildMutualBadge(theme),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildDateInfo(theme, dateFormatter),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMutualBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            size: 12,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Mutual',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(ThemeData theme, DateFormat formatter) {
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outline,
    );

    if (dateFollowed != null && dateFollowing != null) {
      // Show both dates for mutuals
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Followed you: ${formatter.format(dateFollowed!)}',
            style: textStyle,
          ),
          Text(
            'You followed: ${formatter.format(dateFollowing!)}',
            style: textStyle,
          ),
        ],
      );
    } else if (dateFollowed != null) {
      return Text(
        'Followed: ${formatter.format(dateFollowed!)}',
        style: textStyle,
      );
    } else if (dateFollowing != null) {
      return Text(
        'Following since: ${formatter.format(dateFollowing!)}',
        style: textStyle,
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openTikTokProfile(String username) async {
    final url = Uri.parse('https://www.tiktok.com/@$username');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
