/// Post model matching Django backend API
class Post {
  final int id;
  final String postId;
  final String title;
  final int likes;
  final DateTime date;
  final String? coverUrl;
  final String? videoLink;
  final int? views;
  final int? comments;
  final int? shares;
  final int? duration;
  final List<String> hashtags;
  final bool isPrivate;
  final bool isPinned;
  final double? engagementRatio;
  final int? totalEngagement;

  Post({
    required this.id,
    required this.postId,
    required this.title,
    required this.likes,
    required this.date,
    this.coverUrl,
    this.videoLink,
    this.views,
    this.comments,
    this.shares,
    this.duration,
    this.hashtags = const [],
    this.isPrivate = false,
    this.isPinned = false,
    this.engagementRatio,
    this.totalEngagement,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      postId: json['post_id'] as String,
      title: json['title'] as String,
      likes: json['likes'] as int,
      date: DateTime.parse(json['date'] as String),
      coverUrl: json['cover_url'] as String?,
      videoLink: json['video_link'] as String?,
      views: json['views'] as int?,
      comments: json['comments'] as int?,
      shares: json['shares'] as int?,
      duration: json['duration'] as int?,
      hashtags: json['hashtags'] != null
          ? List<String>.from(json['hashtags'] as List)
          : [],
      isPrivate: json['is_private'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      engagementRatio: (json['engagement_ratio'] as num?)?.toDouble(),
      totalEngagement: json['total_engagement'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'title': title,
      'likes': likes,
      'date': date.toIso8601String(),
      'cover_url': coverUrl,
      'video_link': videoLink,
      'views': views,
      'comments': comments,
      'shares': shares,
      'duration': duration,
      'hashtags': hashtags,
      'is_private': isPrivate,
      'is_pinned': isPinned,
      'engagement_ratio': engagementRatio,
      'total_engagement': totalEngagement,
    };
  }

  String get formattedDuration {
    if (duration == null) return 'N/A';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedViews {
    if (views == null) return 'N/A';
    if (views! >= 1000000) {
      return '${(views! / 1000000).toStringAsFixed(1)}M';
    } else if (views! >= 1000) {
      return '${(views! / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String get formattedLikes {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }

  /// Create a copy of this Post with modified fields
  Post copyWith({
    int? id,
    String? postId,
    String? title,
    int? likes,
    DateTime? date,
    String? coverUrl,
    String? videoLink,
    int? views,
    int? comments,
    int? shares,
    int? duration,
    List<String>? hashtags,
    bool? isPrivate,
    bool? isPinned,
    double? engagementRatio,
    int? totalEngagement,
  }) {
    return Post(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      title: title ?? this.title,
      likes: likes ?? this.likes,
      date: date ?? this.date,
      coverUrl: coverUrl ?? this.coverUrl,
      videoLink: videoLink ?? this.videoLink,
      views: views ?? this.views,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      duration: duration ?? this.duration,
      hashtags: hashtags ?? this.hashtags,
      isPrivate: isPrivate ?? this.isPrivate,
      isPinned: isPinned ?? this.isPinned,
      engagementRatio: engagementRatio ?? this.engagementRatio,
      totalEngagement: totalEngagement ?? this.totalEngagement,
    );
  }
}

/// Paginated response from backend
class PostListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Post> results;

  PostListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    return PostListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List)
          .map((post) => Post.fromJson(post as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Statistics response from backend
class PostStats {
  final int totalPosts;
  final int totalLikes;
  final int totalViews;
  final int totalComments;
  final int totalShares;
  final double avgLikes;
  final double avgViews;
  final double avgComments;
  final double avgShares;
  final double avgEngagementRatio;
  final Map<String, String> dateRange;

  PostStats({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalViews,
    required this.totalComments,
    required this.totalShares,
    required this.avgLikes,
    required this.avgViews,
    required this.avgComments,
    required this.avgShares,
    required this.avgEngagementRatio,
    required this.dateRange,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      totalPosts: json['total_posts'] as int,
      totalLikes: json['total_likes'] as int,
      totalViews: json['total_views'] as int,
      totalComments: json['total_comments'] as int,
      totalShares: json['total_shares'] as int,
      avgLikes: (json['avg_likes'] as num).toDouble(),
      avgViews: (json['avg_views'] as num).toDouble(),
      avgComments: (json['avg_comments'] as num).toDouble(),
      avgShares: (json['avg_shares'] as num).toDouble(),
      avgEngagementRatio: (json['avg_engagement_ratio'] as num).toDouble(),
      dateRange: Map<String, String>.from(json['date_range'] as Map),
    );
  }
}
