import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://127.0.0.1:8000/api'});

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

    final uri = Uri.parse('$baseUrl/posts/').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);

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
      final response = await http.get(uri);

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
      final response = await http.get(uri);

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
  Future<Map<String, dynamic>> importPosts(Map<String, dynamic> jsonData) async {
    final uri = Uri.parse('$baseUrl/posts/import/');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
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
}
