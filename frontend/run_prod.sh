#!/bin/bash
# Run Flutter app in production mode

echo "🚀 Starting Flutter app in PRODUCTION mode..."
echo "⚠️  Make sure your production API is running!"
echo ""

flutter run --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api \
  --dart-define=API_TIMEOUT=30 \
  --dart-define=APP_NAME="TikTok Analytics" \
  --dart-define=ENABLE_DEBUG_MODE=false \
  --dart-define=ENABLE_LOGGING=false
