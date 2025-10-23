import 'package:flutter/foundation.dart';

import '../models/follower.dart';
import '../services/api_service.dart';

/// Provider for managing follower/following state
class FollowerProvider with ChangeNotifier {
  final ApiService _apiService;

  FollowerProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ============================================
  // State Management
  // ============================================

  // Followers
  List<Follower> _followers = [];
  bool _followersLoading = false;
  String? _followersError;
  int _followersPage = 1;
  bool _hasMoreFollowers = true;
  int _totalFollowers = 0;

  // Following
  List<Following> _following = [];
  bool _followingLoading = false;
  String? _followingError;
  int _followingPage = 1;
  bool _hasMoreFollowing = true;
  int _totalFollowing = 0;

  // Statistics
  FollowerStats? _stats;
  bool _statsLoading = false;
  String? _statsError;

  // Mutuals
  List<FollowerComparison> _mutuals = [];
  bool _mutualsLoading = false;
  String? _mutualsError;
  int _mutualsPage = 1;
  bool _hasMoreMutuals = true;
  int _totalMutuals = 0;

  // Followers-only
  List<FollowerComparison> _followersOnly = [];
  bool _followersOnlyLoading = false;
  String? _followersOnlyError;
  int _followersOnlyPage = 1;
  bool _hasMoreFollowersOnly = true;
  int _totalFollowersOnly = 0;

  // Following-only
  List<FollowerComparison> _followingOnly = [];
  bool _followingOnlyLoading = false;
  String? _followingOnlyError;
  int _followingOnlyPage = 1;
  bool _hasMoreFollowingOnly = true;
  int _totalFollowingOnly = 0;

  // Filters
  String? _searchQuery;
  String? _ordering = '-date_followed';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // ============================================
  // Getters
  // ============================================

  List<Follower> get followers => _followers;
  bool get followersLoading => _followersLoading;
  String? get followersError => _followersError;
  bool get hasMoreFollowers => _hasMoreFollowers;
  int get totalFollowers => _totalFollowers;

  List<Following> get following => _following;
  bool get followingLoading => _followingLoading;
  String? get followingError => _followingError;
  bool get hasMoreFollowing => _hasMoreFollowing;
  int get totalFollowing => _totalFollowing;

  FollowerStats? get stats => _stats;
  bool get statsLoading => _statsLoading;
  String? get statsError => _statsError;

  List<FollowerComparison> get mutuals => _mutuals;
  bool get mutualsLoading => _mutualsLoading;
  String? get mutualsError => _mutualsError;
  bool get hasMoreMutuals => _hasMoreMutuals;
  int get totalMutuals => _totalMutuals;

  List<FollowerComparison> get followersOnly => _followersOnly;
  bool get followersOnlyLoading => _followersOnlyLoading;
  String? get followersOnlyError => _followersOnlyError;
  bool get hasMoreFollowersOnly => _hasMoreFollowersOnly;
  int get totalFollowersOnly => _totalFollowersOnly;

  List<FollowerComparison> get followingOnly => _followingOnly;
  bool get followingOnlyLoading => _followingOnlyLoading;
  String? get followingOnlyError => _followingOnlyError;
  bool get hasMoreFollowingOnly => _hasMoreFollowingOnly;
  int get totalFollowingOnly => _totalFollowingOnly;

  String? get searchQuery => _searchQuery;
  String? get ordering => _ordering;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // ============================================
  // Followers Methods
  // ============================================

  Future<void> fetchFollowers({bool refresh = false}) async {
    if (refresh) {
      _followersPage = 1;
      _followers = [];
      _hasMoreFollowers = true;
    }

    if (_followersLoading || !_hasMoreFollowers) return;

    _followersLoading = true;
    _followersError = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchFollowers(
        page: _followersPage,
        ordering: _ordering,
        search: _searchQuery,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      _totalFollowers = response.count;
      _followers.addAll(response.results);
      _hasMoreFollowers = response.next != null;
      _followersPage++;
    } catch (e) {
      _followersError = e.toString();
    } finally {
      _followersLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Following Methods
  // ============================================

  Future<void> fetchFollowing({bool refresh = false}) async {
    if (refresh) {
      _followingPage = 1;
      _following = [];
      _hasMoreFollowing = true;
    }

    if (_followingLoading || !_hasMoreFollowing) return;

    _followingLoading = true;
    _followingError = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchFollowing(
        page: _followingPage,
        ordering: _ordering,
        search: _searchQuery,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      _totalFollowing = response.count;
      _following.addAll(response.results);
      _hasMoreFollowing = response.next != null;
      _followingPage++;
    } catch (e) {
      _followingError = e.toString();
    } finally {
      _followingLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Statistics Methods
  // ============================================

  Future<void> fetchStats({bool forceRefresh = false}) async {
    if (_statsLoading || (_stats != null && !forceRefresh)) return;

    _statsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      _stats = await _apiService.fetchFollowerStats();
    } catch (e) {
      _statsError = e.toString();
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Mutuals Methods
  // ============================================

  Future<void> fetchMutuals({bool refresh = false}) async {
    if (refresh) {
      _mutualsPage = 1;
      _mutuals = [];
      _hasMoreMutuals = true;
    }

    if (_mutualsLoading || !_hasMoreMutuals) return;

    _mutualsLoading = true;
    _mutualsError = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchMutuals(
        page: _mutualsPage,
      );

      _totalMutuals = response.count;
      _mutuals.addAll(response.results);
      _hasMoreMutuals = response.next != null;
      _mutualsPage++;
    } catch (e) {
      _mutualsError = e.toString();
    } finally {
      _mutualsLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Followers-Only Methods
  // ============================================

  Future<void> fetchFollowersOnly({bool refresh = false}) async {
    if (refresh) {
      _followersOnlyPage = 1;
      _followersOnly = [];
      _hasMoreFollowersOnly = true;
    }

    if (_followersOnlyLoading || !_hasMoreFollowersOnly) return;

    _followersOnlyLoading = true;
    _followersOnlyError = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchFollowersOnly(
        page: _followersOnlyPage,
      );

      _totalFollowersOnly = response.count;
      _followersOnly.addAll(response.results);
      _hasMoreFollowersOnly = response.next != null;
      _followersOnlyPage++;
    } catch (e) {
      _followersOnlyError = e.toString();
    } finally {
      _followersOnlyLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Following-Only Methods
  // ============================================

  Future<void> fetchFollowingOnly({bool refresh = false}) async {
    if (refresh) {
      _followingOnlyPage = 1;
      _followingOnly = [];
      _hasMoreFollowingOnly = true;
    }

    if (_followingOnlyLoading || !_hasMoreFollowingOnly) return;

    _followingOnlyLoading = true;
    _followingOnlyError = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchFollowingOnly(
        page: _followingOnlyPage,
      );

      _totalFollowingOnly = response.count;
      _followingOnly.addAll(response.results);
      _hasMoreFollowingOnly = response.next != null;
      _followingOnlyPage++;
    } catch (e) {
      _followingOnlyError = e.toString();
    } finally {
      _followingOnlyLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Filter Methods
  // ============================================

  void setSearchQuery(String? query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setOrdering(String? ordering) {
    if (_ordering != ordering) {
      _ordering = ordering;
      notifyListeners();
    }
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _ordering = '-date_followed';
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  // ============================================
  // Utility Methods
  // ============================================

  void clearAll() {
    _followers = [];
    _following = [];
    _mutuals = [];
    _followersOnly = [];
    _followingOnly = [];
    _stats = null;
    _followersPage = 1;
    _followingPage = 1;
    _mutualsPage = 1;
    _followersOnlyPage = 1;
    _followingOnlyPage = 1;
    _hasMoreFollowers = true;
    _hasMoreFollowing = true;
    _hasMoreMutuals = true;
    _hasMoreFollowersOnly = true;
    _hasMoreFollowingOnly = true;
    clearFilters();
    notifyListeners();
  }
}
