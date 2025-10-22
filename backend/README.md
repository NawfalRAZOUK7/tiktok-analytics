# Backend (Django)

Django REST Framework backend for TikTok Analytics - provides endpoints to import, query, and analyze TikTok post data.

## 🚀 Quick Start

### Prerequisites
- Python 3.10 or higher
- pip (Python package manager)

### Installation

1. **Create and activate virtual environment:**
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate  # On macOS/Linux
   # or
   venv\Scripts\activate  # On Windows
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables:**
   - Copy `.env.example` to `.env`
   - Adjust settings as needed (defaults work for development)

4. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

5. **Create superuser (optional, for admin access):**
   ```bash
   python manage.py createsuperuser
   ```

6. **Start development server:**
   ```bash
   python manage.py runserver
   ```

Server will be available at: `http://127.0.0.1:8000`

## 📡 API Documentation

### Base URL
```
http://127.0.0.1:8000/api/
```

### Authentication
Currently open (no authentication required for development).

---

### Endpoints

#### 1️⃣ Import TikTok JSON Data

**POST** `/api/posts/import/`

Import TikTok posts from JSON file format.

**Request Body:**
```json
{
  "metadata": {
    "exported_at": "2025-01-15T10:30:00Z",
    "total_posts": 3,
    "export_version": "1.0"
  },
  "posts": [
    {
      "post_id": "7298765432109876543",
      "title": "Just tried this amazing recipe! 🍕",
      "likes": 15420,
      "date": "2025-09-15T14:23:00Z",
      "cover_url": "https://p16-sign.tiktokcdn.com/example.jpg",
      "video_link": "https://www.tiktok.com/@user/video/7298765432109876543",
      "views": 234567,
      "comments": 423,
      "shares": 89,
      "duration": 45,
      "hashtags": ["cooking", "foodie", "homemade"],
      "is_private": false,
      "is_pinned": false
    }
  ]
}
```

**Response (Success - 201):**
```json
{
  "status": "success",
  "message": "Import complete",
  "statistics": {
    "total_in_file": 3,
    "imported": 3,
    "created": 2,
    "updated": 1,
    "failed": 0
  },
  "metadata": {
    "exported_at": "2025-01-15T10:30:00Z",
    "total_posts": 3,
    "export_version": "1.0"
  }
}
```

**Response (Validation Error - 400):**
```json
{
  "posts": [
    {
      "post_id": ["This field is required."]
    }
  ],
  "metadata": {
    "total_posts": ["This field is required."]
  }
}
```

**Notes:**
- Posts are validated against the JSON schema in `data/schema.json`
- Duplicate `post_id` values will update existing records
- All fields except `post_id`, `title`, `likes`, and `date` are optional

---

#### 2️⃣ List Posts

**GET** `/api/posts/`

Retrieve paginated list of TikTok posts.

**Query Parameters:**
| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `page` | integer | Page number (default: 1) | `?page=2` |
| `page_size` | integer | Items per page (max: 100, default: 20) | `?page_size=50` |
| `ordering` | string | Sort field (prefix `-` for descending) | `?ordering=-likes` |
| `search` | string | Search in title, post_id, hashtags | `?search=cooking` |
| `likes__gte` | integer | Minimum likes | `?likes__gte=10000` |
| `likes__lte` | integer | Maximum likes | `?likes__lte=50000` |
| `views__gte` | integer | Minimum views | `?views__gte=100000` |
| `views__lte` | integer | Maximum views | `?views__lte=500000` |
| `date__gte` | date | Posts after date (ISO 8601) | `?date__gte=2025-01-01` |
| `date__lte` | date | Posts before date (ISO 8601) | `?date__lte=2025-12-31` |
| `is_private` | boolean | Filter by privacy | `?is_private=false` |
| `is_pinned` | boolean | Filter by pinned status | `?is_pinned=true` |

**Response (200):**
```json
{
  "count": 100,
  "next": "http://127.0.0.1:8000/api/posts/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "post_id": "7298765432109876543",
      "title": "Just tried this amazing recipe! 🍕 #cooking #foodie #homemade...",
      "likes": 15420,
      "date": "2025-09-15T14:23:00Z",
      "cover_url": "https://p16-sign.tiktokcdn.com/example.jpg",
      "video_link": "https://www.tiktok.com/@user/video/7298765432109876543",
      "views": 234567,
      "comments": 423,
      "shares": 89,
      "duration": 45,
      "hashtags": ["cooking", "foodie", "homemade"],
      "is_private": false,
      "is_pinned": false,
      "engagement_ratio": 0.0657,
      "total_engagement": 15932
    }
  ]
}
```

**Examples:**
```bash
# Get all posts
curl http://127.0.0.1:8000/api/posts/

# Search for cooking-related posts
curl "http://127.0.0.1:8000/api/posts/?search=cooking"

# Get viral posts (>100k views, sorted by likes)
curl "http://127.0.0.1:8000/api/posts/?views__gte=100000&ordering=-likes"

# Get recent posts from 2025
curl "http://127.0.0.1:8000/api/posts/?date__gte=2025-01-01&ordering=-date"
```

---

#### 3️⃣ Get Post Details

**GET** `/api/posts/{id}/`

Retrieve detailed information for a specific post.

**Response (200):**
```json
{
  "id": 1,
  "post_id": "7298765432109876543",
  "title": "Just tried this amazing recipe! 🍕 #cooking #foodie #homemade...",
  "likes": 15420,
  "date": "2025-09-15T14:23:00Z",
  "cover_url": "https://p16-sign.tiktokcdn.com/example.jpg",
  "video_link": "https://www.tiktok.com/@user/video/7298765432109876543",
  "views": 234567,
  "comments": 423,
  "shares": 89,
  "duration": 45,
  "hashtags": ["cooking", "foodie", "homemade"],
  "is_private": false,
  "is_pinned": false,
  "engagement_ratio": 0.0657,
  "total_engagement": 15932
}
```

**Response (Not Found - 404):**
```json
{
  "detail": "Not found."
}
```

---

#### 4️⃣ Get Statistics

**GET** `/api/posts/stats/`

Get aggregate statistics across all posts.

**Response (200):**
```json
{
  "total_posts": 100,
  "total_likes": 1234567,
  "total_views": 9876543,
  "total_comments": 45678,
  "total_shares": 12345,
  "avg_likes": 12345.67,
  "avg_views": 98765.43,
  "avg_comments": 456.78,
  "avg_shares": 123.45,
  "avg_engagement_ratio": 0.0542,
  "date_range": {
    "earliest": "2024-01-01T00:00:00Z",
    "latest": "2025-12-31T23:59:59Z"
  }
}
```

---

## 🧪 Testing

### Test the import endpoint:
```bash
python test_api.py
```

### Manual API testing with curl:

**Import sample data:**
```bash
curl -X POST http://127.0.0.1:8000/api/posts/import/ \
  -H "Content-Type: application/json" \
  -d @../data/sample.json
```

**List all posts:**
```bash
curl http://127.0.0.1:8000/api/posts/
```

**Get statistics:**
```bash
curl http://127.0.0.1:8000/api/posts/stats/
```

---

## 🗂️ Project Structure

```
backend/
├── backend/           # Django project settings
│   ├── settings.py   # Main configuration (DRF, CORS, DB)
│   ├── urls.py       # Root URL routing
│   └── wsgi.py       # WSGI entry point
├── posts/            # Posts app
│   ├── models.py     # Post model definition
│   ├── serializers.py # DRF serializers for API & import
│   ├── views.py      # ViewSets and endpoints
│   ├── urls.py       # App URL routing
│   ├── admin.py      # Django admin configuration
│   └── migrations/   # Database migrations
├── manage.py         # Django management script
├── requirements.txt  # Python dependencies
├── test_api.py       # Import testing script
└── README.md         # This file
```

---

## 🔧 Configuration

Key environment variables (`.env`):

```env
# Django
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database (SQLite default, PostgreSQL optional)
DATABASE_URL=sqlite:///db.sqlite3
# DATABASE_URL=postgresql://user:pass@localhost:5432/tiktok_analytics

# CORS (for Flutter frontend)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# TikTok Data
TIKTOK_JSON_IMPORT_PATH=../data/sample.json
```

---

## 📊 Data Model

### Post Model Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `post_id` | String | ✅ | TikTok post ID (unique) |
| `title` | String | ✅ | Post title/caption |
| `likes` | Integer | ✅ | Number of likes |
| `date` | DateTime | ✅ | Post date |
| `cover_url` | URL | ❌ | Cover image URL |
| `video_link` | URL | ❌ | TikTok video URL |
| `views` | Integer | ❌ | View count |
| `comments` | Integer | ❌ | Comment count |
| `shares` | Integer | ❌ | Share count |
| `duration` | Integer | ❌ | Video duration (seconds) |
| `hashtags` | JSON Array | ❌ | List of hashtags |
| `is_private` | Boolean | ❌ | Privacy status |
| `is_pinned` | Boolean | ❌ | Pinned to profile |

**Computed Properties:**
- `engagement_ratio`: (likes + comments + shares) / views
- `total_engagement`: likes + comments + shares

---

## 🛠️ Tech Stack

- **Django 4.2.25** - Web framework
- **Django REST Framework 3.16.1** - API framework
- **django-cors-headers 4.9.0** - CORS support for frontend
- **django-filter 24.3** - Advanced filtering
- **jsonschema 4.25.1** - JSON validation
- **python-decouple 3.8** - Environment management
- **psycopg2-binary 2.9.10** - PostgreSQL adapter

---

## 🎯 Next Steps

See `ROADMAP.md` in the repository root for upcoming features:
- ✅ Milestone 1: Data Ingest (Backend) - **COMPLETE**
- 🔄 Milestone 2: Basic Flutter UI (Frontend)
- 🔄 Milestone 3: Visualization (Frontend)
- 🔄 Milestone 4: Advanced Analytics (Backend)

---

## 📝 Admin Interface

Access Django admin at: `http://127.0.0.1:8000/admin/`

Create a superuser to access:
```bash
python manage.py createsuperuser
```

---

## 🐛 Troubleshooting

**Issue:** `externally-managed-environment` error  
**Solution:** Use a virtual environment (see Installation section)

**Issue:** Import errors in IDE  
**Solution:** Cosmetic only - ensure virtual environment is activated

**Issue:** Port 8000 already in use  
**Solution:** `python manage.py runserver 8001` or kill existing process

**Issue:** Migration conflicts  
**Solution:** `python manage.py migrate --run-syncdb`
