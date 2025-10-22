/// Analytics data models

class TrendData {
  final String date;
  final int totalLikes;
  final int totalViews;
  final double avgLikes;
  final double avgViews;
  final int postCount;

  TrendData({
    required this.date,
    required this.totalLikes,
    required this.totalViews,
    required this.avgLikes,
    required this.avgViews,
    required this.postCount,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      date: json['date'] as String,
      totalLikes: json['total_likes'] as int? ?? 0,
      totalViews: json['total_views'] as int? ?? 0,
      avgLikes: (json['avg_likes'] as num?)?.toDouble() ?? 0.0,
      avgViews: (json['avg_views'] as num?)?.toDouble() ?? 0.0,
      postCount: json['post_count'] as int? ?? 0,
    );
  }
}

class TrendsResponse {
  final String grouping;
  final int days;
  final String startDate;
  final String endDate;
  final List<TrendData> data;

  TrendsResponse({
    required this.grouping,
    required this.days,
    required this.startDate,
    required this.endDate,
    required this.data,
  });

  factory TrendsResponse.fromJson(Map<String, dynamic> json) {
    return TrendsResponse(
      grouping: json['grouping'] as String,
      days: json['days'] as int,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      data: (json['data'] as List)
          .map((item) => TrendData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TopPostsByTime {
  final String period;
  final String periodLabel;
  final List<dynamic> topPosts; // Using dynamic since it's Post model from another file

  TopPostsByTime({
    required this.period,
    required this.periodLabel,
    required this.topPosts,
  });

  factory TopPostsByTime.fromJson(Map<String, dynamic> json) {
    return TopPostsByTime(
      period: json['period'] as String,
      periodLabel: json['period_label'] as String,
      topPosts: json['top_posts'] as List,
    );
  }
}

class TopPostsByTimeResponse {
  final String window;
  final String metric;
  final int limit;
  final List<TopPostsByTime> data;

  TopPostsByTimeResponse({
    required this.window,
    required this.metric,
    required this.limit,
    required this.data,
  });

  factory TopPostsByTimeResponse.fromJson(Map<String, dynamic> json) {
    return TopPostsByTimeResponse(
      window: json['window'] as String,
      metric: json['metric'] as String,
      limit: json['limit'] as int,
      data: (json['data'] as List)
          .map((item) => TopPostsByTime.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KeywordData {
  final String word;
  final int count;
  final double percentage;

  KeywordData({
    required this.word,
    required this.count,
    required this.percentage,
  });

  factory KeywordData.fromJson(Map<String, dynamic> json) {
    return KeywordData(
      word: json['word'] as String,
      count: json['count'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class KeywordFrequencyResponse {
  final int totalWords;
  final int uniqueWords;
  final List<KeywordData> keywords;

  KeywordFrequencyResponse({
    required this.totalWords,
    required this.uniqueWords,
    required this.keywords,
  });

  factory KeywordFrequencyResponse.fromJson(Map<String, dynamic> json) {
    return KeywordFrequencyResponse(
      totalWords: json['total_words'] as int,
      uniqueWords: json['unique_words'] as int,
      keywords: (json['keywords'] as List)
          .map((item) => KeywordData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EngagementRatioPost {
  final Map<String, dynamic> post;
  final int daysSincePost;
  final double engagementPerDay;
  final double likesPerDay;

  EngagementRatioPost({
    required this.post,
    required this.daysSincePost,
    required this.engagementPerDay,
    required this.likesPerDay,
  });

  factory EngagementRatioPost.fromJson(Map<String, dynamic> json) {
    return EngagementRatioPost(
      post: Map<String, dynamic>.from(json),
      daysSincePost: json['days_since_post'] as int,
      engagementPerDay: (json['engagement_per_day'] as num).toDouble(),
      likesPerDay: (json['likes_per_day'] as num).toDouble(),
    );
  }

  String get title => post['title'] as String? ?? '';
  int get likes => post['likes'] as int? ?? 0;
  int get views => post['views'] as int? ?? 0;
}

class EngagementRatioResponse {
  final int limit;
  final List<EngagementRatioPost> posts;

  EngagementRatioResponse({
    required this.limit,
    required this.posts,
  });

  factory EngagementRatioResponse.fromJson(Map<String, dynamic> json) {
    return EngagementRatioResponse(
      limit: json['limit'] as int,
      posts: (json['posts'] as List)
          .map((item) => EngagementRatioPost.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
