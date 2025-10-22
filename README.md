# TikTok Analytics — Full-Stack Application

A full-stack application for importing and analyzing TikTok post metrics, built with Django (backend) and Flutter (frontend).

## 🎯 Project Overview

This application allows you to:

- Import TikTok export JSON data
- Analyze post metrics (likes, views, engagement trends)
- Visualize analytics through interactive charts
- Browse and filter posts with detailed metrics

**Current Status:** Scaffold phase — foundations complete ✅

---

## 📁 Project Structure

```
SocialMedia/
├── backend/           # Django REST API
│   ├── README.md      # Backend-specific documentation
│   ├── .env.example   # Backend environment template
│   └── manage.py      # Django management script
├── frontend/          # Flutter multi-platform app
│   ├── README.md      # Frontend-specific documentation
│   ├── .env.example   # Frontend environment template
│   └── lib/           # Flutter source code
├── data/              # TikTok export JSON files (gitignored)
├── .env.example       # Root environment template
├── .gitignore         # Git ignore rules
└── ROADMAP.md         # Development roadmap
```

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.10+** (for Django backend)
- **Flutter 3.0+** (for Flutter frontend)
- **Git** (for version control)

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd SocialMedia
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies (when available)
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Run migrations (when models are created)
python manage.py migrate

# Start development server
python manage.py runserver
```

Backend will be available at `http://localhost:8000`

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Configure environment
cp .env.example .env
# Edit .env with your API settings

# Run the app
flutter run
```

Choose your target platform when prompted (web, mobile, desktop).

---

## ⚙️ Environment Configuration

### Root `.env` (Optional)

Copy `.env.example` to `.env` and configure shared settings.

### Backend `.env`

Located in `backend/.env`:

- `SECRET_KEY` — Django secret key
- `DEBUG` — Debug mode (True/False)
- `DATABASE_*` — Database configuration
- `CORS_ALLOWED_ORIGINS` — Allowed frontend origins
- `TIKTOK_JSON_IMPORT_PATH` — Path to TikTok JSON file

### Frontend `.env`

Located in `frontend/.env`:

- `API_BASE_URL` — Backend API URL
- `API_TIMEOUT` — Request timeout in seconds
- Feature flags for offline mode, analytics, etc.

---

## 📊 Data Source

### TikTok Export JSON

The application expects TikTok export data in JSON format with the following structure:

```json
{
  "posts": [
    {
      "id": "unique_post_id",
      "title": "Post title/description",
      "likes": 1234,
      "date": "2025-01-15T10:30:00Z",
      "cover_url": "https://example.com/cover.jpg",
      "video_link": "https://tiktok.com/@user/video/123"
    }
  ]
}
```

Place your TikTok export file in the `data/` directory (gitignored for privacy).

---

## 🗺️ Development Roadmap

See [ROADMAP.md](./ROADMAP.md) for detailed milestones and future tasks.

**Current Milestone:** 0. Foundations ✅

- [x] Initialize Django & Flutter scaffolds
- [x] Configure .env management
- [x] Structure README documentation
- [ ] Connect repo to GitHub
- [ ] Define complete TikTok JSON schema

---

## 🛠️ Technology Stack

### Backend

- **Django 4.x** — Web framework
- **Django REST Framework** (planned) — API
- **SQLite** (dev) / **PostgreSQL** (prod) — Database
- **python-decouple** (planned) — Environment management

### Frontend

- **Flutter 3.x** — Multi-platform framework
- **Provider/Riverpod** (planned) — State management
- **dio** (planned) — HTTP client
- **fl_chart** (planned) — Data visualization

---

## 📝 Documentation

- [Backend README](./backend/README.md) — Django-specific details
- [Frontend README](./frontend/README.md) — Flutter-specific details
- [ROADMAP](./ROADMAP.md) — Development plan and milestones

---

## 🧪 Testing

Testing infrastructure will be added in later milestones:

- Backend: Unit tests, integration tests (Django TestCase)
- Frontend: Widget tests, integration tests (Flutter)

---

## 🤝 Contributing

This is currently a personal project. Contributions, issues, and feature requests are welcome once the MVP is complete.

---

## 📄 License

[Specify your license here — e.g., MIT, Apache 2.0]

---

## 📧 Contact

[Your contact information or links]

---

**Note:** This project is in active development. Features described in the roadmap are planned but not yet implemented.
