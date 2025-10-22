import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Post> _posts = [];
  PostStats? _stats;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;

  // Filters
  String _searchQuery = '';
  String _sortBy = '-date'; // Default: newest first
  int? _minLikes;
  int? _maxLikes;
  int? _minViews;
  int? _maxViews;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool? _isPrivate;
  bool? _isPinned;

  // Getters
  List<Post> get posts => _posts;
  PostStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  int? get minLikes => _minLikes;
  int? get maxLikes => _maxLikes;
  int? get minViews => _minViews;
  int? get maxViews => _maxViews;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool? get isPrivate => _isPrivate;
  bool? get isPinned => _isPinned;

  /// Fetch posts with current filters
  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _posts = [];
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchPosts(
        page: _currentPage,
        ordering: _sortBy,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        likesMin: _minLikes,
        likesMax: _maxLikes,
        viewsMin: _minViews,
        viewsMax: _maxViews,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        isPrivate: _isPrivate,
        isPinned: _isPinned,
      );

      if (refresh) {
        _posts = response.results;
      } else {
        _posts.addAll(response.results);
      }

      _totalCount = response.count;
      _hasMore = response.next != null;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch statistics
  Future<void> fetchStats() async {
    try {
      _stats = await _apiService.fetchStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch stats: $e');
    }
  }

  /// Update search query and refresh
  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchPosts(refresh: true);
  }

  /// Update sort order and refresh
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    fetchPosts(refresh: true);
  }

  /// Update like filters and refresh
  void setLikesFilter({int? min, int? max}) {
    _minLikes = min;
    _maxLikes = max;
    fetchPosts(refresh: true);
  }

  /// Update view filters and refresh
  void setViewsFilter({int? min, int? max}) {
    _minViews = min;
    _maxViews = max;
    fetchPosts(refresh: true);
  }

  /// Update date filters and refresh
  void setDateFilter({DateTime? from, DateTime? to}) {
    _dateFrom = from;
    _dateTo = to;
    fetchPosts(refresh: true);
  }

  /// Update privacy filter and refresh
  void setPrivacyFilter(bool? isPrivate) {
    _isPrivate = isPrivate;
    fetchPosts(refresh: true);
  }

  /// Update pinned filter and refresh
  void setPinnedFilter(bool? isPinned) {
    _isPinned = isPinned;
    fetchPosts(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _sortBy = '-date';
    _minLikes = null;
    _maxLikes = null;
    _minViews = null;
    _maxViews = null;
    _dateFrom = null;
    _dateTo = null;
    _isPrivate = null;
    _isPinned = null;
    fetchPosts(refresh: true);
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _minLikes != null ||
        _maxLikes != null ||
        _minViews != null ||
        _maxViews != null ||
        _dateFrom != null ||
        _dateTo != null ||
        _isPrivate != null ||
        _isPinned != null;
  }
}
