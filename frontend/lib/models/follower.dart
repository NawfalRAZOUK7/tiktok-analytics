/// Follower model representing a TikTok follower
class Follower {
  final int id;
  final String username;
  final DateTime dateFollowed;
  final DateTime createdAt;
  final bool? isMutual; // Computed field from comparison endpoints

  Follower({
    required this.id,
    required this.username,
    required this.dateFollowed,
    required this.createdAt,
    this.isMutual,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      id: json['id'] as int,
      username: json['username'] as String,
      dateFollowed: DateTime.parse(json['date_followed'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isMutual: json['is_mutual'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'date_followed': dateFollowed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (isMutual != null) 'is_mutual': isMutual,
    };
  }

  Follower copyWith({
    int? id,
    String? username,
    DateTime? dateFollowed,
    DateTime? createdAt,
    bool? isMutual,
  }) {
    return Follower(
      id: id ?? this.id,
      username: username ?? this.username,
      dateFollowed: dateFollowed ?? this.dateFollowed,
      createdAt: createdAt ?? this.createdAt,
      isMutual: isMutual ?? this.isMutual,
    );
  }
}

/// Following model representing a TikTok following
class Following {
  final int id;
  final String username;
  final DateTime dateFollowed;
  final DateTime createdAt;
  final bool? isMutual; // Computed field from comparison endpoints

  Following({
    required this.id,
    required this.username,
    required this.dateFollowed,
    required this.createdAt,
    this.isMutual,
  });

  factory Following.fromJson(Map<String, dynamic> json) {
    return Following(
      id: json['id'] as int,
      username: json['username'] as String,
      dateFollowed: DateTime.parse(json['date_followed'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isMutual: json['is_mutual'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'date_followed': dateFollowed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (isMutual != null) 'is_mutual': isMutual,
    };
  }

  Following copyWith({
    int? id,
    String? username,
    DateTime? dateFollowed,
    DateTime? createdAt,
    bool? isMutual,
  }) {
    return Following(
      id: id ?? this.id,
      username: username ?? this.username,
      dateFollowed: dateFollowed ?? this.dateFollowed,
      createdAt: createdAt ?? this.createdAt,
      isMutual: isMutual ?? this.isMutual,
    );
  }
}

/// Follower comparison result (for mutuals, followers-only, following-only)
class FollowerComparison {
  final String username;
  final DateTime? dateFollowed;
  final DateTime? dateFollowing;
  final bool isMutual;

  FollowerComparison({
    required this.username,
    this.dateFollowed,
    this.dateFollowing,
    required this.isMutual,
  });

  factory FollowerComparison.fromJson(Map<String, dynamic> json) {
    return FollowerComparison(
      username: json['username'] as String,
      dateFollowed: json['date_followed'] != null
          ? DateTime.parse(json['date_followed'] as String)
          : null,
      dateFollowing: json['date_following'] != null
          ? DateTime.parse(json['date_following'] as String)
          : null,
      isMutual: json['is_mutual'] as bool,
    );
  }

  DateTime? get mostRecentDate {
    if (dateFollowed != null && dateFollowing != null) {
      return dateFollowed!.isAfter(dateFollowing!)
          ? dateFollowed
          : dateFollowing;
    }
    return dateFollowed ?? dateFollowing;
  }
}

/// Follower statistics
class FollowerStats {
  final int totalFollowers;
  final int totalFollowing;
  final int mutualsCount;
  final int followersOnlyCount;
  final int followingOnlyCount;
  final double followerRatio;
  final Map<String, int> weeklyGrowth;
  final Map<String, int> monthlyGrowth;
  final List<TopAcquisitionDate> topAcquisitionDates;

  FollowerStats({
    required this.totalFollowers,
    required this.totalFollowing,
    required this.mutualsCount,
    required this.followersOnlyCount,
    required this.followingOnlyCount,
    required this.followerRatio,
    required this.weeklyGrowth,
    required this.monthlyGrowth,
    required this.topAcquisitionDates,
  });

  factory FollowerStats.fromJson(Map<String, dynamic> json) {
    return FollowerStats(
      totalFollowers: json['total_followers'] as int,
      totalFollowing: json['total_following'] as int,
      mutualsCount: json['mutuals_count'] as int,
      followersOnlyCount: json['followers_only_count'] as int,
      followingOnlyCount: json['following_only_count'] as int,
      followerRatio: (json['follower_ratio'] as num).toDouble(),
      weeklyGrowth: Map<String, int>.from(json['weekly_growth'] as Map),
      monthlyGrowth: Map<String, int>.from(json['monthly_growth'] as Map),
      topAcquisitionDates: (json['top_acquisition_dates'] as List)
          .map((date) => TopAcquisitionDate.fromJson(date))
          .toList(),
    );
  }
}

/// Top acquisition date with follower count
class TopAcquisitionDate {
  final DateTime date;
  final int followersGained;

  TopAcquisitionDate({
    required this.date,
    required this.followersGained,
  });

  factory TopAcquisitionDate.fromJson(Map<String, dynamic> json) {
    return TopAcquisitionDate(
      date: DateTime.parse(json['date'] as String),
      followersGained: json['followers_gained'] as int,
    );
  }
}
