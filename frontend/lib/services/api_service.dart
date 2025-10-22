import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/analytics.dart';
import '../models/post.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl;
  final AuthService? _authService;
  final Duration timeout;

  ApiService({
    String? baseUrl,
    AuthService? authService,
    Duration? timeout,
  })  : baseUrl = baseUrl ?? Environment.apiBaseUrl,
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
}
