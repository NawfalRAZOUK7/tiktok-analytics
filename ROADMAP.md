# TikTok Analytics — Project Roadmap

## Vision (TikTok-only)

Import and analyze TikTok post metrics (likes, titles, dates, covers), surface trends and insights.

## Data Source

TikTok export JSON file (path to be configured later). Example file currently available from the user's export.

## Milestones

### 0. Foundations ✅

- Initialize Django & Flutter scaffolds ✅
- Configure .env management and README structure ✅
- Connect repo to GitHub ✅
- Define sample TikTok JSON schema (fields: id, title, likes, date, cover_url, video_link) ✅

### 1. Data Ingest (Backend) ✅

- Add DRF; endpoints to upload/read TikTok JSON ✅
- Validate schema; normalize posts ✅
- Basic list endpoint ✅
- Import endpoint with JSON schema validation ✅
- Statistics endpoint ✅
- Filtering, search, and pagination ✅

### 2. Browse (Frontend) ✅

- Post list with sort/filter ✅
- Detail page (cover, title, likes, date) ✅
- Search functionality ✅
- Pull-to-refresh ✅
- Statistics bar with aggregates ✅
- Infinite scroll pagination ✅

### 3. Insights ✅

- Trend detection (views/likes over time) ✅
- Top posts by time window (daily, weekly, monthly) ✅
- Keyword frequency (common words in titles/descriptions) ✅
- Engagement ratio (likes per day since post date) ✅

### 4. Auth & Deploy

- Simple auth ✅
- Environment configs ✅
- CI/CD ✅

---

## Backend Testing & Commands ✅

- ✅ DRF setup; serializers/models for Posts (date, video_link(s), likes, title, cover, flags)
- ✅ Management command to import from TikTok JSON (`import_tiktok_json`)
- ✅ Pagination, filtering (date range, like thresholds)
- ✅ CORS, logging, settings split, .env management
- ✅ Unit and integration tests for API endpoints (105+ tests, 70%+ coverage)

## Frontend Enhancement ✅

- ✅ Go Router setup with auth guards and deep linking
- ✅ Screens: Dashboard, Posts List, Post Detail, Login, Register
- ✅ API client with error handling and loading states
- ✅ Pull-to-refresh and infinite scroll pagination
- ✅ Interactive charts with fl_chart (engagement, trends, keywords)
- ✅ Responsive layout utilities for mobile/tablet/desktop
- ✅ Widget tests for PostDetailScreen
- ✅ State management with Provider (Auth, Posts, Analytics)
- ✅ Comprehensive documentation (FRONTEND_GUIDE.md)

---

## Integration Plan

- REST endpoints under `/api/posts/`
- Flutter service layer for API communication
- Use Provider or Riverpod for state management
- Shared data model (Post) between backend and frontend

---

## Notes

- Keep scope TikTok-only until phase 3
- Avoid extra generated files beyond official scaffolds + this documentation trio
- Later phases will include comprehensive unit and integration tests
