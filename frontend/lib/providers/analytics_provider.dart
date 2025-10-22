import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/analytics.dart';

class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService;

  AnalyticsProvider(this._apiService);

  // Trends data
  TrendsResponse? _trendsData;
  bool _trendsLoading = false;
  String? _trendsError;

  TrendsResponse? get trendsData => _trendsData;
  bool get trendsLoading => _trendsLoading;
  String? get trendsError => _trendsError;

  // Top posts data
  TopPostsByTimeResponse? _topPostsData;
  bool _topPostsLoading = false;
  String? _topPostsError;

  TopPostsByTimeResponse? get topPostsData => _topPostsData;
  bool get topPostsLoading => _topPostsLoading;
  String? get topPostsError => _topPostsError;

  // Keyword frequency data
  KeywordFrequencyResponse? _keywordData;
  bool _keywordLoading = false;
  String? _keywordError;

  KeywordFrequencyResponse? get keywordData => _keywordData;
  bool get keywordLoading => _keywordLoading;
  String? get keywordError => _keywordError;

  // Engagement ratio data
  EngagementRatioResponse? _engagementData;
  bool _engagementLoading = false;
  String? _engagementError;

  EngagementRatioResponse? get engagementData => _engagementData;
  bool get engagementLoading => _engagementLoading;
  String? get engagementError => _engagementError;

  /// Fetch trends data
  Future<void> fetchTrends({
    String grouping = 'day',
    int days = 30,
  }) async {
    _trendsLoading = true;
    _trendsError = null;
    notifyListeners();

    try {
      _trendsData = await _apiService.fetchTrends(
        grouping: grouping,
        days: days,
      );
      _trendsError = null;
    } catch (e) {
      _trendsError = e.toString();
      _trendsData = null;
    } finally {
      _trendsLoading = false;
      notifyListeners();
    }
  }

  /// Fetch top posts by time window
  Future<void> fetchTopPosts({
    String window = 'daily',
    int limit = 5,
    String metric = 'likes',
  }) async {
    _topPostsLoading = true;
    _topPostsError = null;
    notifyListeners();

    try {
      _topPostsData = await _apiService.fetchTopPostsByTime(
        window: window,
        limit: limit,
        metric: metric,
      );
      _topPostsError = null;
    } catch (e) {
      _topPostsError = e.toString();
      _topPostsData = null;
    } finally {
      _topPostsLoading = false;
      notifyListeners();
    }
  }

  /// Fetch keyword frequency
  Future<void> fetchKeywords({
    int limit = 20,
    int minLength = 3,
  }) async {
    _keywordLoading = true;
    _keywordError = null;
    notifyListeners();

    try {
      _keywordData = await _apiService.fetchKeywordFrequency(
        limit: limit,
        minLength: minLength,
      );
      _keywordError = null;
    } catch (e) {
      _keywordError = e.toString();
      _keywordData = null;
    } finally {
      _keywordLoading = false;
      notifyListeners();
    }
  }

  /// Fetch engagement ratio analysis
  Future<void> fetchEngagement({
    int limit = 10,
  }) async {
    _engagementLoading = true;
    _engagementError = null;
    notifyListeners();

    try {
      _engagementData = await _apiService.fetchEngagementRatio(
        limit: limit,
      );
      _engagementError = null;
    } catch (e) {
      _engagementError = e.toString();
      _engagementData = null;
    } finally {
      _engagementLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all analytics data at once
  Future<void> fetchAllAnalytics({
    String trendGrouping = 'day',
    int trendDays = 30,
    String topPostsWindow = 'daily',
    int topPostsLimit = 5,
    String topPostsMetric = 'likes',
    int keywordLimit = 20,
    int keywordMinLength = 3,
    int engagementLimit = 10,
  }) async {
    await Future.wait([
      fetchTrends(grouping: trendGrouping, days: trendDays),
      fetchTopPosts(window: topPostsWindow, limit: topPostsLimit, metric: topPostsMetric),
      fetchKeywords(limit: keywordLimit, minLength: keywordMinLength),
      fetchEngagement(limit: engagementLimit),
    ]);
  }

  /// Clear all analytics data
  void clearAllData() {
    _trendsData = null;
    _trendsError = null;
    _topPostsData = null;
    _topPostsError = null;
    _keywordData = null;
    _keywordError = null;
    _engagementData = null;
    _engagementError = null;
    notifyListeners();
  }
}
