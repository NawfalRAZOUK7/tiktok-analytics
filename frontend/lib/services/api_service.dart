import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/analytics.dart';
import '../models/follower.dart';
import '../models/post.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  final AuthService? _authService;
  final Duration timeout;

  ApiService({String? baseUrl, AuthService? authService, Duration? timeout})
    : baseUrl = baseUrl ?? Environment.apiBaseUrl,
      _authService = authService ?? AuthService(),
      timeout = timeout ?? Duration(seconds: Environment.apiTimeout);

  /// Get headers with auth token if available
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (_authService != null) {
      final token = await _authService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  /// Fetch paginated list of posts with optional filters
  Future<PostListResponse> fetchPosts({
    int page = 1,
    int pageSize = 20,
    String? ordering,
    String? search,
    int? likesMin,
    int? likesMax,
    int? viewsMin,
    int? viewsMax,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isPrivate,
    bool? isPinned,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (ordering != null) queryParams['ordering'] = ordering;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (likesMin != null) queryParams['likes__gte'] = likesMin.toString();
    if (likesMax != null) queryParams['likes__lte'] = likesMax.toString();
    if (viewsMin != null) queryParams['views__gte'] = viewsMin.toString();
    if (viewsMax != null) queryParams['views__lte'] = viewsMax.toString();
    if (dateFrom != null) {
      queryParams['date__gte'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['date__lte'] = dateTo.toIso8601String().split('T')[0];
    }
    if (isPrivate != null) queryParams['is_private'] = isPrivate.toString();
    if (isPinned != null) queryParams['is_pinned'] = isPinned.toString();

    final uri = Uri.parse(
      '$baseUrl/posts/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PostListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch a single post by ID
  Future<Post> fetchPost(int id) async {
    final uri = Uri.parse('$baseUrl/posts/$id/');

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Post.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch aggregate statistics
  Future<PostStats> fetchStats() async {
    final uri = Uri.parse('$baseUrl/posts/stats/');

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PostStats.fromJson(data);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Import posts from JSON
  Future<Map<String, dynamic>> importPosts(
    Map<String, dynamic> jsonData,
  ) async {
    final uri = Uri.parse('$baseUrl/posts/import/');

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(jsonData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception('Import failed: $error');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ========== Analytics Endpoints ==========

  /// Fetch trends (views/likes over time)
  Future<TrendsResponse> fetchTrends({
    String grouping = 'day',
    int days = 30,
  }) async {
    final queryParams = {'grouping': grouping, 'days': days.toString()};

    final uri = Uri.parse(
      '$baseUrl/posts/trends/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TrendsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load trends: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch top posts by time window
  Future<TopPostsByTimeResponse> fetchTopPostsByTime({
    String window = 'daily',
    int limit = 5,
    String metric = 'likes',
  }) async {
    final queryParams = {
      'window': window,
      'limit': limit.toString(),
      'metric': metric,
    };

    final uri = Uri.parse(
      '$baseUrl/posts/top_posts_by_time/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TopPostsByTimeResponse.fromJson(data);
      } else {
        throw Exception('Failed to load top posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch keyword frequency analysis
  Future<KeywordFrequencyResponse> fetchKeywordFrequency({
    int limit = 20,
    int minLength = 3,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      'min_length': minLength.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/posts/keyword_frequency/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return KeywordFrequencyResponse.fromJson(data);
      } else {
        throw Exception('Failed to load keywords: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch engagement ratio analysis
  Future<EngagementRatioResponse> fetchEngagementRatio({int limit = 10}) async {
    final queryParams = {'limit': limit.toString()};

    final uri = Uri.parse(
      '$baseUrl/posts/engagement_ratio_analysis/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return EngagementRatioResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load engagement data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============================================
  // Followers/Following Endpoints
  // ============================================

  /// Fetch paginated list of followers
  Future<FollowerListResponse> fetchFollowers({
    int page = 1,
    int pageSize = 100,
    String? ordering,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (ordering != null) queryParams['ordering'] = ordering;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (dateFrom != null) {
      queryParams['date_followed__gte'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['date_followed__lte'] = dateTo.toIso8601String();
    }

    final uri = Uri.parse(
      '$baseUrl/api/followers/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FollowerListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load followers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch paginated list of following
  Future<FollowingListResponse> fetchFollowing({
    int page = 1,
    int pageSize = 100,
    String? ordering,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (ordering != null) queryParams['ordering'] = ordering;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (dateFrom != null) {
      queryParams['date_followed__gte'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['date_followed__lte'] = dateTo.toIso8601String();
    }

    final uri = Uri.parse(
      '$baseUrl/api/following/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FollowingListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load following: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch follower statistics
  Future<FollowerStats> fetchFollowerStats() async {
    final uri = Uri.parse('$baseUrl/api/followers/stats/');

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FollowerStats.fromJson(data);
      } else {
        throw Exception(
          'Failed to load follower stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch mutuals (common followers/following)
  Future<FollowerComparisonListResponse> fetchMutuals({
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/followers/common/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FollowerComparisonListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load mutuals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch followers-only (non-reciprocal followers)
  Future<FollowerComparisonListResponse> fetchFollowersOnly({
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/followers/followers-only/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FollowerComparisonListResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load followers-only: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch following-only (non-reciprocal following)
  Future<FollowerComparisonListResponse> fetchFollowingOnly({
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/followers/following-only/',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return FollowerComparisonListResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load following-only: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

/// Paginated response for followers list
class FollowerListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Follower> results;

  FollowerListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FollowerListResponse.fromJson(Map<String, dynamic> json) {
    return FollowerListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List)
              .map((follower) => Follower.fromJson(follower))
              .toList(),
    );
  }
}

/// Paginated response for following list
class FollowingListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Following> results;

  FollowingListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FollowingListResponse.fromJson(Map<String, dynamic> json) {
    return FollowingListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List)
              .map((following) => Following.fromJson(following))
              .toList(),
    );
  }
}

/// Paginated response for follower comparison (mutuals, distinct)
class FollowerComparisonListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FollowerComparison> results;

  FollowerComparisonListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FollowerComparisonListResponse.fromJson(Map<String, dynamic> json) {
    return FollowerComparisonListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List)
              .map((comparison) => FollowerComparison.fromJson(comparison))
              .toList(),
    );
  }
}
