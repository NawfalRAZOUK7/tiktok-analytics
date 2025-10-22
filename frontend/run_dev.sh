#!/bin/bash
# Run Flutter app in development mode

echo "🚀 Starting Flutter app in DEVELOPMENT mode..."
echo "API: http://127.0.0.1:8000/api"
echo ""

flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api \
  --dart-define=API_TIMEOUT=30 \
  --dart-define=APP_NAME="TikTok Analytics (Dev)" \
  --dart-define=ENABLE_DEBUG_MODE=true \
  --dart-define=ENABLE_LOGGING=true
