import 'package:flutter/material.dart';
import 'package:frontend/models/follower.dart';

class MockFollowerProvider extends ChangeNotifier {
  List<Follower> _followers = [];
  List<Following> _following = [];
  List<FollowerComparison> _mutuals = [];
  List<FollowerComparison> _followersOnly = [];
  List<FollowerComparison> _followingOnly = [];
  FollowerStats? _stats;
  
  bool _followersLoading = false;
  bool _followingLoading = false;
  bool _mutualsLoading = false;
  bool _followersOnlyLoading = false;
  bool _followingOnlyLoading = false;
  bool _statsLoading = false;
  
  String? _followersError;
  String? _followingError;
  String? _mutualsError;
  String? _followersOnlyError;
  String? _followingOnlyError;
  String? _statsError;
  
  int _totalFollowers = 0;
  int _totalFollowing = 0;
  int _totalMutuals = 0;
  int _totalFollowersOnly = 0;
  int _totalFollowingOnly = 0;
  
  bool _hasMoreFollowers = true;
  bool _hasMoreFollowing = true;
  bool _hasMoreMutuals = true;
  bool _hasMoreFollowersOnly = true;
  bool _hasMoreFollowingOnly = true;
  
  String? _searchQuery;
  String? _ordering = '-date_followed';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Tracking flags for testing
  bool fetchFollowersCalled = false;
  bool fetchFollowingCalled = false;
  bool refreshCalled = false;
  String? lastSearchQuery;
  String? lastOrdering;

  // Getters
  List<Follower> get followers => _followers;
  List<Following> get following => _following;
  List<FollowerComparison> get mutuals => _mutuals;
  List<FollowerComparison> get followersOnly => _followersOnly;
  List<FollowerComparison> get followingOnly => _followingOnly;
  FollowerStats? get stats => _stats;
  
  bool get followersLoading => _followersLoading;
  bool get followingLoading => _followingLoading;
  bool get mutualsLoading => _mutualsLoading;
  bool get followersOnlyLoading => _followersOnlyLoading;
  bool get followingOnlyLoading => _followingOnlyLoading;
  bool get statsLoading => _statsLoading;
  
  String? get followersError => _followersError;
  String? get followingError => _followingError;
  String? get mutualsError => _mutualsError;
  String? get followersOnlyError => _followersOnlyError;
  String? get followingOnlyError => _followingOnlyError;
  String? get statsError => _statsError;
  
  int get totalFollowers => _totalFollowers;
  int get totalFollowing => _totalFollowing;
  int get totalMutuals => _totalMutuals;
  int get totalFollowersOnly => _totalFollowersOnly;
  int get totalFollowingOnly => _totalFollowingOnly;
  
  bool get hasMoreFollowers => _hasMoreFollowers;
  bool get hasMoreFollowing => _hasMoreFollowing;
  bool get hasMoreMutuals => _hasMoreMutuals;
  bool get hasMoreFollowersOnly => _hasMoreFollowersOnly;
  bool get hasMoreFollowingOnly => _hasMoreFollowingOnly;
  
  String? get searchQuery => _searchQuery;
  String? get ordering => _ordering;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // Setters for testing
  void setFollowers(List<Follower> followers) {
    _followers = followers;
    notifyListeners();
  }

  void setFollowing(List<Following> following) {
    _following = following;
    notifyListeners();
  }

  void setFollowersLoading(bool loading) {
    _followersLoading = loading;
    notifyListeners();
  }

  void setFollowingLoading(bool loading) {
    _followingLoading = loading;
    notifyListeners();
  }

  void setFollowersError(String? error) {
    _followersError = error;
    notifyListeners();
  }

  void setFollowingError(String? error) {
    _followingError = error;
    notifyListeners();
  }

  void setTotalFollowers(int total) {
    _totalFollowers = total;
    notifyListeners();
  }

  void setTotalFollowing(int total) {
    _totalFollowing = total;
    notifyListeners();
  }

  void setHasMoreFollowers(bool has) {
    _hasMoreFollowers = has;
    notifyListeners();
  }

  void setHasMoreFollowing(bool has) {
    _hasMoreFollowing = has;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOrdering(String? order) {
    _ordering = order;
    notifyListeners();
  }

  // Methods
  Future<void> fetchFollowers({bool refresh = false}) async {
    fetchFollowersCalled = true;
    
    if (refresh) {
      refreshCalled = true;
    }

    _followersLoading = true;
    _followersError = null;
    notifyListeners();

    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 50));

    _followersLoading = false;
    notifyListeners();
  }

  Future<void> fetchFollowing({bool refresh = false}) async {
    fetchFollowingCalled = true;
    
    if (refresh) {
      refreshCalled = true;
    }

    _followingLoading = true;
    _followingError = null;
    notifyListeners();

    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 50));

    _followingLoading = false;
    notifyListeners();
  }

  // Reset tracking flags
  void reset() {
    fetchFollowersCalled = false;
    fetchFollowingCalled = false;
    refreshCalled = false;
    lastSearchQuery = null;
    lastOrdering = null;
  }
}
