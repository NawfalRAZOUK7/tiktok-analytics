# Frontend (Flutter)

Flutter multi-platform app for TikTok Analytics - browse, filter, and analyze TikTok post data with an intuitive UI.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK (included with Flutter)
- Running Django backend at `http://127.0.0.1:8000`

### Installation

1. **Navigate to frontend directory:**

   ```bash
   cd frontend
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Ensure backend is running:**

   ```bash
   cd ../backend
   source venv/bin/activate
   python manage.py runserver
   ```

4. **Run the app:**

   ```bash
   # For web
   flutter run -d chrome

   # For macOS
   flutter run -d macos

   # For iOS (requires Xcode)
   flutter run -d ios

   # For Android (requires Android Studio/SDK)
   flutter run -d android
   ```

---

## 📱 Features

### Post List Screen

- **Browse all posts** with infinite scroll pagination
- **Search** by title, post ID, or hashtags
- **Sort** by date, likes, or views (ascending/descending)
- **Filter** by like count, view count, date range
- **Pull-to-refresh** to reload data
- **Statistics bar** showing aggregate metrics
- **Tap any post** to view details

### Post Detail Screen

- **Cover image** display
- **Full title** and metadata
- **Engagement metrics:** likes, views, comments, shares, duration
- **Calculated metrics:** engagement ratio, total engagement
- **Hashtags** display
- **Open in TikTok** button (if video link available)
- **Pinned/Private badges**

---

## 🏗️ Architecture

### Clean Architecture Pattern

```
lib/
├── main.dart                  # App entry point
├── models/
│   └── post.dart             # Data models (Post, PostListResponse, PostStats)
├── services/
│   └── api_service.dart      # HTTP client for backend API
├── providers/
│   └── post_provider.dart    # State management with Provider
└── screens/
    ├── post_list_screen.dart  # Main list view
    └── post_detail_screen.dart # Detail view
```

### State Management

- **Provider pattern** for reactive state updates
- **ChangeNotifier** for PostProvider
- **Consumer widgets** for rebuilding on state changes
- **Efficient pagination** with scroll controller

### Data Flow

1. User interacts with UI (search, filter, sort)
2. PostProvider updates filters and calls ApiService
3. ApiService makes HTTP request to Django backend
4. Response is parsed into Post models
5. Provider notifies listeners
6. UI rebuilds with new data

---

## 📡 API Integration

### Base URL

```dart
final String baseUrl = 'http://127.0.0.1:8000/api';
```

### Endpoints Used

- `GET /api/posts/` - Fetch paginated posts with filters
- `GET /api/posts/{id}/` - Fetch single post details
- `GET /api/posts/stats/` - Fetch aggregate statistics

### Query Parameters

All list endpoint filters are supported:

- `page`, `page_size` - Pagination
- `ordering` - Sort field
- `search` - Text search
- `likes__gte`, `likes__lte` - Like filters
- `views__gte`, `views__lte` - View filters
- `date__gte`, `date__lte` - Date range
- `is_private`, `is_pinned` - Boolean filters

---

## 🎨 UI Components

### PostListScreen

- **AppBar** with filter button
- **Search bar** with real-time query
- **Sort chips** for quick access to sorting
- **Statistics bar** showing totals and averages
- **Post cards** with thumbnail, title, metrics
- **Infinite scroll** with loading indicator
- **Pull-to-refresh** gesture
- **Error handling** with retry button

### PostDetailScreen

- **Hero image** at top
- **Title** and badges (pinned, private)
- **Metrics card** with icons and values
- **Engagement card** with calculated stats
- **Hashtag chips** for visual appeal
- **Information card** with metadata
- **External link** button for TikTok

### FilterDialog

- **Numeric inputs** for min/max likes and views
- **Apply** and **Cancel** buttons
- **Real-time validation**

---

## 🔧 Configuration

### Environment Variables (`.env`)

```env
API_BASE_URL=http://127.0.0.1:8000/api
APP_NAME=TikTok Analytics
DEBUG_MODE=true
```

### pubspec.yaml Dependencies

```yaml
dependencies:
  http: ^1.2.0 # HTTP client
  provider: ^6.1.1 # State management
  intl: ^0.19.0 # Date formatting
  flutter_dotenv: ^5.1.0 # Environment variables
  cached_network_image: ^3.3.1 # Image caching
  url_launcher: ^6.2.4 # Open external links
```

---

## 🧪 Testing

### Run the app

```bash
# Web (recommended for development)
flutter run -d chrome

# macOS desktop
flutter run -d macos
```

### Test Features

1. **Browse posts:** Verify all 3 sample posts appear
2. **Search:** Try "cooking", "project", "morning"
3. **Sort:** Test each sort option (newest, oldest, most liked, etc.)
4. **Filter:** Set min likes to 10000, max to 20000
5. **Detail view:** Tap a post, verify all fields display
6. **Pagination:** Scroll down (if >20 posts)
7. **Refresh:** Pull down to refresh
8. **Stats bar:** Verify metrics match backend

### Expected Data (from sample.json)

- **3 posts total**
- Post IDs: 7298765432109876543, 7287654321098765432, 7276543210987654321
- Likes range: 8,932 - 24,567
- Views range: 156,789 - 487,623

---

## 📊 Data Models

### Post Model

```dart
class Post {
  final int id;
  final String postId;
  final String title;
  final int likes;
  final DateTime date;
  final String? coverUrl;
  final String? videoLink;
  final int? views;
  final int? comments;
  final int? shares;
  final int? duration;
  final List<String> hashtags;
  final bool isPrivate;
  final bool isPinned;
  final double? engagementRatio;
  final int? totalEngagement;
}
```

**Helper Methods:**

- `formattedDuration` - Converts seconds to MM:SS
- `formattedViews` - Formats numbers (K, M notation)
- `formattedLikes` - Formats numbers (K, M notation)

---

## 🛠️ Tech Stack

- **Flutter 3.9.2** - UI framework
- **Dart 3.x** - Programming language
- **Provider 6.1.1** - State management
- **HTTP 1.2.0** - API client
- **Intl 0.19.0** - Internationalization & date formatting
- **Cached Network Image 3.3.1** - Image caching
- **URL Launcher 6.2.4** - External link handling

---

## 🎯 Next Steps

See `ROADMAP.md` in the repository root for upcoming features:

- ✅ Milestone 2: Browse (Frontend) - **COMPLETE**
- 🔄 Milestone 3: Visualization (Charts)
- 🔄 Milestone 4: Advanced Analytics

**Planned Features:**

- Charts (engagement over time, top content)
- Trend detection graphs
- Keyword frequency analysis
- Export functionality
- Dark mode support

---

## 🖥️ Platform Support

Tested and working on:

- ✅ **Web** (Chrome, Safari, Firefox)
- ✅ **macOS** (Desktop app)
- ⚠️ **iOS** (Requires Xcode setup)
- ⚠️ **Android** (Requires Android Studio)
- ⚠️ **Windows** (Not tested)
- ⚠️ **Linux** (Not tested)

---

## 🐛 Troubleshooting

**Issue:** "Connection refused" or API errors  
**Solution:** Ensure Django backend is running on port 8000

**Issue:** Images not loading  
**Solution:** Check that cover URLs are valid and accessible

**Issue:** No posts appear  
**Solution:** Run `backend/test_api.py` to import sample data

**Issue:** Gradle/Xcode build errors  
**Solution:** Try running on web first with `flutter run -d chrome`

**Issue:** Hot reload not working  
**Solution:** Use `r` in terminal or `R` for full restart

---

## 📱 Screenshots

### Post List Screen

- Displays all posts in a scrollable list
- Search bar at top
- Sort and filter chips below search
- Statistics bar showing aggregate data
- Post cards with thumbnails and metrics

### Post Detail Screen

- Full cover image at top
- Detailed metrics with icons
- Engagement calculations
- Hashtag display
- External link to TikTok video

---

## 🔗 Related Documentation

- [Backend API Documentation](../backend/README.md)
- [Project Roadmap](../ROADMAP.md)
- [Schema Documentation](../data/SCHEMA.md)
- [Flutter Docs](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)

---

**Frontend Status:** ✅ **COMPLETE**  
**Milestone 2:** Browse (Frontend) - Implemented post list with sort/filter and detail view
