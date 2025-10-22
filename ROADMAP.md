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
- CI/CD

---

## Backend (Future Tasks)

- DRF setup; serializers/models for Posts (date, video_link(s), likes, title, cover, flags)
- Management command to import from TikTok JSON
- Pagination, filtering (date range, like thresholds)
- CORS, logging, settings split, .env management
- Unit and integration tests for API endpoints

## Frontend (Future Tasks)

- Routing + screens (Dashboard, Posts, Post Detail)
- API client, error states, pull-to-refresh
- Charts (engagement over time, top content)
- Responsive layout for web/desktop/mobile
- Widget tests for key components

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
