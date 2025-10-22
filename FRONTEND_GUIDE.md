# Frontend Development Guide

## Overview

This Flutter application is a comprehensive TikTok Analytics dashboard that allows users to view, analyze, and manage TikTok post data. The frontend communicates with a Django REST API backend and implements modern Flutter best practices including state management, routing, and responsive design.

## Table of Contents

- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Routing](#routing)
- [State Management](#state-management)
- [API Integration](#api-integration)
- [Responsive Design](#responsive-design)
- [Testing](#testing)
- [Running the App](#running-the-app)
- [Best Practices](#best-practices)

## Technology Stack

### Core Dependencies
- **Flutter SDK**: ^3.0.0
- **Dart**: ^3.0.0

### Key Packages
- **provider** (^6.0.0): State management solution
- **go_router** (^14.0.0): Declarative routing with deep linking
- **http** (^1.0.0): HTTP client for API requests
- **flutter_secure_storage** (^9.0.0): Secure storage for authentication tokens
- **fl_chart** (^0.69.0): Beautiful and interactive charts
- **cached_network_image** (^3.3.0): Image caching for performance
- **intl** (^0.19.0): Internationalization and date formatting
- **url_launcher** (^6.2.0): Opening external URLs

## Project Structure

```
frontend/
├── lib/
│   ├── config/
│   │   ├── environment.dart       # Environment configuration
│   │   └── router.dart            # Go Router configuration
│   ├── models/
│   │   ├── analytics.dart         # Analytics data models
│   │   └── post.dart              # Post and related models
│   ├── providers/
│   │   ├── analytics_provider.dart # Analytics state management
│   │   ├── auth_provider.dart     # Authentication state
│   │   └── post_provider.dart     # Post list state management
│   ├── screens/
│   │   ├── analytics_dashboard_screen.dart
│   │   ├── login_screen.dart
│   │   ├── post_detail_screen.dart
│   │   ├── post_list_screen.dart
│   │   └── register_screen.dart
│   ├── services/
│   │   ├── api_service.dart       # HTTP client for backend API
│   │   └── auth_service.dart      # Authentication service
│   ├── utils/
│   │   └── responsive.dart        # Responsive layout utilities
│   ├── widgets/
│   │   ├── engagement_chart.dart
│   │   ├── keyword_chart.dart
│   │   ├── top_posts_widget.dart
│   │   └── trends_chart.dart
│   └── main.dart                  # App entry point
├── test/
│   ├── post_detail_screen_test.dart
│   └── widget_test.dart
└── pubspec.yaml
```

## Routing

### Go Router Configuration

The app uses `go_router` for declarative routing with authentication guards and deep linking support.

#### Route Structure

```dart
/ (root)                    → Dashboard (requires auth)
/login                      → Login Screen
/register                   → Register Screen
/posts                      → Posts List (requires auth)
/posts/:id                  → Post Detail (requires auth)
/analytics                  → Analytics Dashboard (requires auth)
```

#### Authentication Guards

Routes are protected using a global redirect function that checks authentication status:

```dart
redirect: (context, state) {
  final authenticated = isAuthenticated();
  final loggingIn = state.matchedLocation == '/login' || 
                     state.matchedLocation == '/register';

  // Redirect to login if not authenticated
  if (!authenticated && !loggingIn) {
    return '/login';
  }

  // Redirect to home if authenticated and on login page
  if (authenticated && loggingIn) {
    return '/';
  }

  return null; // No redirect needed
}
```

#### Shell Route with Bottom Navigation

The main app uses a shell route to maintain persistent bottom navigation:

```dart
ShellRoute(
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(path: '/', name: 'dashboard', builder: ...),
    GoRoute(path: '/posts', name: 'posts', builder: ...),
    GoRoute(path: '/analytics', name: 'analytics', builder: ...),
  ],
)
```

#### Navigation Examples

```dart
// Navigate to post detail
context.go('/posts/${post.id}', extra: post);

// Push navigation (keeps previous route in stack)
context.push('/posts/$id', extra: post);

// Go back
context.pop();

// Replace current route
context.replace('/login');
```

## State Management

### Provider Architecture

The app uses the **Provider** package for state management with three main providers:

#### 1. AuthProvider

Manages authentication state and user session.

```dart
class AuthProvider extends ChangeNotifier {
  bool isAuthenticated;
  String? token;
  
  Future<void> login(String username, String password);
  Future<void> logout();
  Future<void> register(String username, String email, String password);
}
```

**Usage:**
```dart
// In widget
final authProvider = context.watch<AuthProvider>();
if (authProvider.isAuthenticated) {
  // Show authenticated content
}

// Trigger login
await context.read<AuthProvider>().login(username, password);
```

#### 2. PostProvider

Manages post list, filtering, sorting, and pagination.

```dart
class PostProvider extends ChangeNotifier {
  List<Post> posts;
  bool isLoading;
  String? error;
  PostStats? stats;
  
  // Filters
  String? searchQuery;
  String sortBy;
  int? minLikes, maxLikes;
  int? minViews, maxViews;
  
  Future<void> fetchPosts({bool refresh = false});
  Future<void> fetchStats();
  void setSearchQuery(String query);
  void setSortBy(String sortBy);
  void setLikesFilter({int? min, int? max});
  void setViewsFilter({int? min, int? max});
  void clearFilters();
}
```

**Usage:**
```dart
// Fetch posts
await context.read<PostProvider>().fetchPosts(refresh: true);

// Apply filter
context.read<PostProvider>().setSearchQuery('flutter');

// Listen to changes
Consumer<PostProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) return CircularProgressIndicator();
    return ListView(children: provider.posts.map(buildPost).toList());
  },
)
```

#### 3. AnalyticsProvider

Manages analytics data including trends, insights, and charts.

```dart
class AnalyticsProvider extends ChangeNotifier {
  TrendsResponse? trends;
  InsightsResponse? insights;
  EngagementRatioResponse? engagementData;
  
  bool trendsLoading, insightsLoading;
  String? trendsError, insightsError;
  
  Future<void> fetchTrends();
  Future<void> fetchInsights();
  Future<void> fetchEngagement();
  Future<void> fetchAllAnalytics();
}
```

**Usage:**
```dart
// Fetch all analytics
await context.read<AnalyticsProvider>().fetchAllAnalytics();

// Listen to specific data
Consumer<AnalyticsProvider>(
  builder: (context, provider, child) {
    if (provider.trendsLoading) return Loading();
    return TrendsChart(data: provider.trends);
  },
)
```

### Provider Setup

All providers are initialized in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
    ChangeNotifierProvider(create: (_) => PostProvider()),
    ChangeNotifierProvider(create: (_) => AnalyticsProvider(apiService)),
  ],
  child: MyApp(),
)
```

## API Integration

### ApiService

The `ApiService` class handles all HTTP requests to the backend API.

#### Configuration

```dart
class ApiService {
  final String baseUrl = Environment.apiBaseUrl; // From environment config
  final AuthService _authService;
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }
}
```

#### API Methods

**Fetch Posts (with pagination and filters)**
```dart
Future<PostListResponse> fetchPosts({
  int page = 1,
  int pageSize = 20,
  Map<String, String>? filters,
});
```

**Fetch Single Post**
```dart
Future<Post> fetchPost(int id);
```

**Import Posts**
```dart
Future<void> importPosts(List<Map<String, dynamic>> posts);
```

**Fetch Statistics**
```dart
Future<PostStats> fetchStatistics();
```

**Fetch Insights**
```dart
Future<InsightsResponse> fetchInsights();
```

#### Error Handling

```dart
try {
  final posts = await apiService.fetchPosts();
} catch (e) {
  if (e is HttpException) {
    // Handle HTTP errors
    if (e.statusCode == 401) {
      // Unauthorized - redirect to login
    }
  } else {
    // Handle network errors
  }
}
```

### AuthService

Manages authentication tokens securely using `flutter_secure_storage`.

```dart
class AuthService {
  final storage = FlutterSecureStorage();
  
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<bool> isAuthenticated();
}
```

## Responsive Design

### Responsive Utility

The app includes a comprehensive responsive utility (`lib/utils/responsive.dart`) for adaptive layouts.

#### Breakpoints

```dart
class Responsive {
  static const double mobile = 600;   // < 600px
  static const double tablet = 900;   // 600-900px
  static const double desktop = 1200; // > 1200px
}
```

#### Usage Examples

**Check Device Type**
```dart
if (Responsive.isMobile(context)) {
  // Show mobile layout
} else if (Responsive.isTablet(context)) {
  // Show tablet layout
} else {
  // Show desktop layout
}
```

**Responsive Grid**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: Responsive.getGridCrossAxisCount(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    ),
  ),
)
```

**Responsive Values**
```dart
final fontSize = Responsive.getValue(
  context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);
```

**Extension Methods**
```dart
// Using context extensions
if (context.isMobile) {
  // Mobile layout
}

final columns = context.gridColumns(mobile: 1, tablet: 2, desktop: 3);
final padding = context.responsivePadding();
```

## Testing

### Widget Testing

The app includes comprehensive widget tests for key components.

#### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/post_detail_screen_test.dart

# Run with coverage
flutter test --coverage
```

#### Example Test

```dart
testWidgets('displays post title correctly', (WidgetTester tester) async {
  final testPost = Post(
    id: 1,
    postId: 'test123',
    title: 'Test Post',
    // ... other fields
  );

  await tester.pumpWidget(
    MaterialApp(
      home: PostDetailScreen(post: testPost),
    ),
  );

  expect(find.text('Test Post'), findsOneWidget);
});
```

#### Testing Best Practices

1. **Arrange-Act-Assert Pattern**: Structure tests clearly
2. **Mock Data**: Use consistent test fixtures
3. **Test User Interactions**: Verify button taps, scrolling, etc.
4. **Test Error States**: Ensure error handling works
5. **Test Edge Cases**: Null values, empty lists, etc.

### Integration Testing

For full app integration tests:

```bash
flutter test integration_test/app_test.dart
```

## Running the App

### Prerequisites

1. **Flutter SDK**: Install from [flutter.dev](https://flutter.dev)
2. **IDE**: VS Code or Android Studio with Flutter plugins
3. **Device**: Android emulator, iOS simulator, or physical device

### Setup

```bash
# Clone the repository
cd frontend

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
```

### Environment Configuration

Create or modify `lib/config/environment.dart`:

```dart
class Environment {
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const bool isDevelopment = true;
}
```

### Running

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

### Hot Reload

While running, press:
- `r` to hot reload
- `R` to hot restart
- `q` to quit

## Best Practices

### Code Organization

1. **Feature-Based Structure**: Group related files together
2. **Separation of Concerns**: Keep business logic in providers, UI in widgets
3. **Reusable Widgets**: Extract common UI components
4. **Constants**: Define magic numbers and strings as constants

### State Management

1. **Minimal Rebuilds**: Use `Consumer` for targeted rebuilds
2. **Avoid Overuse**: Don't put everything in providers
3. **Immutable State**: Never modify state directly
4. **Error Handling**: Always handle loading and error states

### Performance

1. **Image Caching**: Use `CachedNetworkImage` for network images
2. **Lazy Loading**: Implement pagination for large lists
3. **Const Constructors**: Use `const` where possible
4. **Avoid Rebuilds**: Use `const` widgets and `RepaintBoundary`

### UI/UX

1. **Loading States**: Show progress indicators during async operations
2. **Error Messages**: Provide clear, actionable error messages
3. **Empty States**: Display helpful messages when no data exists
4. **Pull-to-Refresh**: Implement for list views
5. **Responsive Design**: Adapt UI for different screen sizes

### Security

1. **Secure Storage**: Use `flutter_secure_storage` for tokens
2. **HTTPS**: Always use HTTPS in production
3. **Input Validation**: Validate user input on frontend and backend
4. **Token Refresh**: Implement token refresh logic

### Code Quality

1. **Linting**: Enable and follow lint rules
2. **Formatting**: Use `dart format` before committing
3. **Documentation**: Add comments for complex logic
4. **Type Safety**: Avoid dynamic types where possible

### Git Workflow

1. **Meaningful Commits**: Write clear commit messages
2. **Feature Branches**: Use branches for new features
3. **Code Review**: Review code before merging
4. **Version Tags**: Tag releases with semantic versioning

## Common Issues & Solutions

### Issue: Token Not Persisting

**Solution**: Ensure `flutter_secure_storage` is properly configured for your platform.

### Issue: API Connection Failed

**Solution**: 
1. Check backend is running
2. Verify `apiBaseUrl` in environment config
3. For Android emulator, use `http://10.0.2.2:8000` instead of `localhost`

### Issue: Hot Reload Not Working

**Solution**:
1. Try hot restart (`R`)
2. Restart the app
3. Clean build: `flutter clean && flutter pub get`

### Issue: Widget Tests Failing

**Solution**:
1. Ensure test data is consistent
2. Use `await tester.pump()` after interactions
3. Check widget tree structure with `tester.widget<Type>(find...)`

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Provider Package](https://pub.dev/packages/provider)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [FL Chart Examples](https://github.com/imaNNeo/fl_chart)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)

## Contributing

1. Follow the existing code style
2. Write tests for new features
3. Update documentation
4. Submit pull requests for review

## License

This project is part of the TikTok Analytics application.
