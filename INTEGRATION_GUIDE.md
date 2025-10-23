# TikTok Analytics - Integration Guide

## Overview

This document explains how the Django backend and Flutter frontend are integrated to create a full-stack TikTok analytics application.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (Flutter)                    │
│                                                               │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   Screens   │───▶│  Providers   │───▶│  API Service │   │
│  │  (UI Layer) │    │ (State Mgmt) │    │ (HTTP Client)│   │
│  └─────────────┘    └──────────────┘    └──────┬───────┘   │
│                                                  │            │
└──────────────────────────────────────────────────┼───────────┘
                                                   │ HTTP/JSON
                                                   │
┌──────────────────────────────────────────────────▼───────────┐
│                        Backend (Django)                       │
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │ REST API     │───▶│ Serializers  │───▶│   Models     │   │
│  │ (ViewSets)   │    │ (DRF)        │    │ (Database)   │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Backend API Endpoints

All endpoints are under `/api/posts/` and follow REST conventions.

### Base URL

- **Development**: `http://127.0.0.1:8000/api`
- **Production**: Configure via environment variable `API_BASE_URL`

### Endpoints

#### 1. List Posts

```
GET /api/posts/
```

**Query Parameters**:

- `page` (int): Page number (default: 1)
- `page_size` (int): Items per page (default: 20, max: 100)
- `ordering` (string): Sort field (e.g., `-date`, `likes`, `-views`)
- `search` (string): Search in title and hashtags
- `likes_min` (int): Minimum likes filter
- `likes_max` (int): Maximum likes filter
- `views_min` (int): Minimum views filter
- `views_max` (int): Maximum views filter
- `date_from` (date): Filter posts from this date
- `date_to` (date): Filter posts to this date
- `is_private` (bool): Filter by privacy status
- `is_pinned` (bool): Filter pinned posts

**Response**:

```json
{
  "count": 100,
  "next": "http://127.0.0.1:8000/api/posts/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "post_id": "video123",
      "title": "Amazing Video",
      "date": "2024-01-15T10:30:00Z",
      "likes": 1500,
      "views": 25000,
      "comments": 120,
      "shares": 50,
      "duration": 30,
      "cover_url": "https://example.com/cover.jpg",
      "video_link": "https://tiktok.com/@user/video/123",
      "hashtags": ["trending", "viral"],
      "is_private": false,
      "is_pinned": true,
      "engagement_ratio": 0.06,
      "total_engagement": 1670
    }
  ]
}
```

#### 2. Get Single Post

```
GET /api/posts/{id}/
```

**Response**: Same as single post object above.

#### 3. Create Post

```
POST /api/posts/
```

**Request Body**:

```json
{
  "post_id": "video123",
  "title": "Amazing Video",
  "date": "2024-01-15T10:30:00Z",
  "likes": 1500,
  "views": 25000,
  "comments": 120,
  "shares": 50,
  "duration": 30,
  "cover_url": "https://example.com/cover.jpg",
  "video_link": "https://tiktok.com/@user/video/123",
  "hashtags": ["trending", "viral"],
  "is_private": false,
  "is_pinned": false
}
```

#### 4. Update Post

```
PUT /api/posts/{id}/
PATCH /api/posts/{id}/
```

#### 5. Delete Post

```
DELETE /api/posts/{id}/
```

#### 6. Import Posts (Bulk)

```
POST /api/posts/import/
```

**Request Body**:

```json
{
  "posts": [
    {
      "post_id": "video123",
      "title": "Amazing Video",
      ...
    }
  ]
}
```

**Response**:

```json
{
  "imported": 10,
  "skipped": 2,
  "errors": []
}
```

#### 7. Statistics

```
GET /api/posts/statistics/
```

**Response**:

```json
{
  "total_posts": 100,
  "total_likes": 150000,
  "total_views": 2500000,
  "total_comments": 12000,
  "total_shares": 5000,
  "avg_likes": 1500,
  "avg_views": 25000,
  "avg_engagement_rate": 0.06,
  "avg_duration": 45
}
```

#### 8. Insights

```
GET /api/posts/insights/
```

**Query Parameters**:

- `insight_type` (string): Type of insight
  - `trends`: Engagement trends over time
  - `top_posts`: Top performing posts
  - `keywords`: Keyword frequency analysis
  - `engagement`: Engagement patterns

**Response** (varies by insight type):

```json
{
  "insight_type": "trends",
  "data": [
    {
      "date": "2024-01",
      "avg_likes": 1500,
      "avg_views": 25000,
      "post_count": 10
    }
  ]
}
```

## Frontend Integration

### 1. API Service Layer

The `ApiService` class (`frontend/lib/services/api_service.dart`) handles all HTTP communication:

```dart
class ApiService {
  final String baseUrl;
  final AuthService? _authService;
  final Duration timeout;

  // Fetch posts with filters
  Future<PostListResponse> fetchPosts({
    int page = 1,
    String? ordering,
    String? search,
    // ... filters
  });

  // Get single post
  Future<Post> fetchPost(int id);

  // Import posts
  Future<Map<String, dynamic>> importPosts(List<Map<String, dynamic>> posts);

  // Get statistics
  Future<PostStats> fetchStatistics();

  // Get insights
  Future<AnalyticsData> fetchInsights({
    String insightType = 'trends',
  });
}
```

**Features**:

- Automatic authentication header injection
- Timeout configuration (default: 30s)
- Error handling with custom exceptions
- JSON serialization/deserialization

### 2. State Management (Provider)

Three main providers manage application state:

#### AuthProvider

```dart
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  User? _user;

  Future<void> login(String username, String password);
  Future<void> logout();
  Future<void> register(String username, String email, String password);
}
```

#### PostProvider

```dart
class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  PostStats? _stats;

  Future<void> fetchPosts({bool refresh = false});
  Future<void> loadMore();
  void setFilters({String? search, String? sortBy, ...});
  void clearFilters();
}
```

#### AnalyticsProvider

```dart
class AnalyticsProvider with ChangeNotifier {
  AnalyticsData? _data;

  Future<void> fetchAnalytics(String insightType);
  Future<void> fetchStatistics();
}
```

### 3. Data Models

Shared data structure between backend and frontend:

```dart
class Post {
  final int id;
  final String postId;
  final String title;
  final DateTime date;
  final int likes;
  final int views;
  final int comments;
  final int shares;
  final int duration;
  final String? coverUrl;
  final String? videoLink;
  final List<String> hashtags;
  final bool isPrivate;
  final bool isPinned;
  final double engagementRatio;
  final int totalEngagement;

  // JSON serialization
  factory Post.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### 4. Screen Integration Examples

#### Posts List Screen

```dart
class PostListScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => postProvider.fetchPosts(refresh: true),
        child: ListView.builder(
          itemCount: postProvider.posts.length,
          itemBuilder: (context, index) {
            final post = postProvider.posts[index];
            return PostCard(
              post: post,
              onTap: () => context.go('/posts/${post.id}', extra: post),
            );
          },
        ),
      ),
    );
  }
}
```

#### Analytics Dashboard

```dart
class AnalyticsDashboardScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final analyticsProvider = context.watch<AnalyticsProvider>();

    return TabBarView(
      children: [
        // Trends tab
        TrendsChart(data: analyticsProvider.trendsData),

        // Top posts tab
        TopPostsWidget(posts: analyticsProvider.topPosts),

        // Keywords tab
        KeywordChart(data: analyticsProvider.keywordData),

        // Engagement tab
        EngagementChart(data: analyticsProvider.engagementData),
      ],
    );
  }
}
```

## Environment Configuration

### Backend (.env)

```env
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### Frontend (environment.dart)

```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );
}
```

## Authentication Flow

1. **Login Request**: Flutter app sends credentials to `/api/auth/login/`
2. **Token Response**: Backend returns authentication token
3. **Token Storage**: Flutter stores token in secure storage (flutter_secure_storage)
4. **API Requests**: ApiService automatically includes token in Authorization header
5. **Token Refresh**: AuthProvider checks token validity and refreshes if needed
6. **Logout**: Token is removed from secure storage

## CORS Configuration

Backend is configured to accept requests from Flutter development server:

```python
# backend/backend/settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
]

CORS_ALLOW_CREDENTIALS = True
```

## Error Handling

### Backend Error Responses

```json
{
  "detail": "Error message",
  "status_code": 400
}
```

### Frontend Error Handling

```dart
try {
  final posts = await apiService.fetchPosts();
} on ApiException catch (e) {
  // Handle API errors (4xx, 5xx)
  showError(e.message);
} on TimeoutException catch (e) {
  // Handle timeout errors
  showError('Request timed out');
} catch (e) {
  // Handle other errors
  showError('An unexpected error occurred');
}
```

## Testing Integration

### Backend API Tests

```python
# backend/posts/tests/test_views.py
def test_list_posts(self):
    response = self.client.get('/api/posts/')
    self.assertEqual(response.status_code, 200)
    self.assertIn('results', response.data)
```

### Frontend Integration Tests

```dart
// frontend/test/integration/api_test.dart
testWidgets('fetches posts from API', (tester) async {
  final apiService = ApiService();
  final response = await apiService.fetchPosts();

  expect(response.results, isNotEmpty);
  expect(response.results.first, isA<Post>());
});
```

## Running the Full Stack

### 1. Start Backend

```bash
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
python manage.py runserver
```

Server runs at: `http://127.0.0.1:8000`

### 2. Start Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome  # or your preferred device
```

### 3. Verify Integration

1. Open Flutter app in browser/device
2. Navigate to Posts screen
3. Check that posts load from backend
4. Test filtering, search, and pagination
5. Navigate to Analytics screen
6. Verify charts and insights load correctly

## Deployment Considerations

### Backend Deployment

- Set `DEBUG=False` in production
- Use PostgreSQL instead of SQLite
- Configure proper `ALLOWED_HOSTS`
- Set secure `SECRET_KEY`
- Use environment variables for sensitive data
- Enable HTTPS
- Configure production CORS origins

### Frontend Deployment

- Build for production: `flutter build web`
- Configure production API endpoint
- Enable caching for static assets
- Use CDN for images
- Implement proper error tracking
- Configure analytics

## Troubleshooting

### Common Issues

#### 1. CORS Errors

**Problem**: Browser blocks API requests
**Solution**: Ensure backend CORS settings include frontend origin

#### 2. Connection Refused

**Problem**: Flutter can't connect to backend
**Solution**:

- Verify backend is running
- Check API_BASE_URL in environment.dart
- Ensure no firewall blocking port 8000

#### 3. 401 Unauthorized

**Problem**: API returns unauthorized error
**Solution**:

- Check authentication token is valid
- Verify token is included in request headers
- Re-authenticate if token expired

#### 4. Slow API Responses

**Problem**: API requests take too long
**Solution**:

- Add database indexes for frequently queried fields
- Implement pagination (already done)
- Use database query optimization
- Consider caching frequently accessed data

## Best Practices

1. **Error Handling**: Always handle API errors gracefully
2. **Loading States**: Show loading indicators during API calls
3. **Retry Logic**: Implement automatic retry for failed requests
4. **Caching**: Cache frequently accessed data
5. **Pagination**: Load data in chunks for better performance
6. **Validation**: Validate data on both frontend and backend
7. **Security**: Never expose sensitive data in client-side code
8. **Testing**: Write integration tests for critical user flows
9. **Monitoring**: Implement logging and error tracking
10. **Documentation**: Keep API documentation up-to-date

## Resources

- **Backend API**: http://127.0.0.1:8000/api/
- **Admin Panel**: http://127.0.0.1:8000/admin/
- **API Documentation**: http://127.0.0.1:8000/api/docs/ (if configured)
- **Frontend Guide**: [FRONTEND_GUIDE.md](./FRONTEND_GUIDE.md)
- **Backend Testing Guide**: [BACKEND_TESTING_GUIDE.md](./BACKEND_TESTING_GUIDE.md)

## Next Steps

- [ ] Add real-time updates with WebSockets
- [ ] Implement offline support with local database
- [ ] Add push notifications
- [ ] Implement data export functionality
- [ ] Add user preferences and settings
- [ ] Implement advanced analytics features
- [ ] Add multi-language support
