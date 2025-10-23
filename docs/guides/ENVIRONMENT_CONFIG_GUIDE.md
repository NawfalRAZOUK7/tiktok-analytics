# 🔧 Environment Configuration Guide

## Overview

This project uses environment-specific configurations for both backend (Django) and frontend (Flutter). This allows you to easily switch between development, staging, and production environments.

---

## 📁 Configuration Files

### Root Level

- `.env.example` - Template with all available variables
- `.env.development` - Development defaults (safe to commit)
- `.env.production.example` - Production template (customize and create `.env.production`)
- `.env` - Your local environment file (DO NOT COMMIT)

### Backend

- `backend/backend/settings.py` - Django settings that read from environment variables

### Frontend

- `frontend/lib/config/environment.dart` - Environment configuration class
- `frontend/.vscode/launch.json` - VS Code launch configurations
- `frontend/run_dev.sh` - Development run script
- `frontend/run_prod.sh` - Production run script

---

## 🚀 Quick Start

### 1. Setup Local Environment

```bash
# Copy the example file
cp .env.example .env

# Edit with your values (optional for development)
nano .env
```

For development, you can use the defaults in `.env.development`.

### 2. Backend Setup

```bash
cd backend

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate  # Windows

# Run with default development settings
python manage.py runserver

# Or specify environment file
export $(cat ../.env.development | xargs)
python manage.py runserver
```

### 3. Frontend Setup

**Option A: Using Scripts (Recommended)**

```bash
cd frontend

# Development mode
./run_dev.sh

# Production mode
./run_prod.sh
```

**Option B: Manual Flutter Command**

```bash
cd frontend

# Development
flutter run \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

# Production
flutter run --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

**Option C: VS Code Launch Configurations**

1. Open `frontend` folder in VS Code
2. Go to Run & Debug (⇧⌘D)
3. Select configuration:
   - "Development"
   - "Staging"
   - "Production"
   - "Development (Chrome)"
4. Click Start Debugging (F5)

---

## 📋 Environment Variables

### Backend Variables

| Variable               | Description       | Default               | Required             |
| ---------------------- | ----------------- | --------------------- | -------------------- |
| `ENVIRONMENT`          | Environment name  | `development`         | No                   |
| `DJANGO_SECRET_KEY`    | Django secret key | Generated             | **Yes (Production)** |
| `DJANGO_DEBUG`         | Enable debug mode | `True`                | No                   |
| `DJANGO_ALLOWED_HOSTS` | Allowed hosts     | `localhost,127.0.0.1` | Yes                  |
| `DB_ENGINE`            | Database engine   | `sqlite3`             | No                   |
| `DB_NAME`              | Database name     | `db.sqlite3`          | No                   |
| `DB_USER`              | Database user     | -                     | For PostgreSQL       |
| `DB_PASSWORD`          | Database password | -                     | For PostgreSQL       |
| `DB_HOST`              | Database host     | `localhost`           | For PostgreSQL       |
| `DB_PORT`              | Database port     | `5432`                | For PostgreSQL       |
| `CORS_ALLOWED_ORIGINS` | CORS origins      | `localhost URLs`      | Yes                  |
| `API_RATE_LIMIT`       | API rate limit    | `1000/hour`           | No                   |
| `API_PAGE_SIZE`        | Default page size | `20`                  | No                   |
| `API_MAX_PAGE_SIZE`    | Max page size     | `100`                 | No                   |
| `STATIC_URL`           | Static files URL  | `/static/`            | No                   |
| `STATIC_ROOT`          | Static files root | `staticfiles/`        | For production       |
| `MEDIA_URL`            | Media files URL   | `/media/`             | No                   |
| `MEDIA_ROOT`           | Media files root  | `media/`              | For production       |
| `LOG_LEVEL`            | Logging level     | `INFO`                | No                   |
| `LOG_FILE`             | Log file path     | `logs/django.log`     | No                   |

### Frontend Variables

| Variable            | Description               | Default                     | Required |
| ------------------- | ------------------------- | --------------------------- | -------- |
| `ENVIRONMENT`       | Environment name          | `development`               | No       |
| `API_BASE_URL`      | Backend API URL           | `http://127.0.0.1:8000/api` | **Yes**  |
| `API_TIMEOUT`       | Request timeout (seconds) | `30`                        | No       |
| `APP_NAME`          | Application name          | `TikTok Analytics`          | No       |
| `APP_VERSION`       | Application version       | `1.0.0`                     | No       |
| `ENABLE_DEBUG_MODE` | Enable debug features     | `true`                      | No       |
| `ENABLE_LOGGING`    | Enable logging            | `true`                      | No       |

---

## 🔒 Security Best Practices

### 1. Secret Key Generation

**Generate a new Django secret key for production:**

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 2. Never Commit Secrets

Add to `.gitignore`:

```
.env
.env.production
.env.local
*.secret
```

### 3. Use Strong Passwords

For production databases, use strong passwords:

```bash
# Generate secure password
openssl rand -base64 32
```

### 4. Production Checklist

- [ ] Generate new `DJANGO_SECRET_KEY`
- [ ] Set `DJANGO_DEBUG=False`
- [ ] Configure proper `DJANGO_ALLOWED_HOSTS`
- [ ] Use PostgreSQL instead of SQLite
- [ ] Set strong database passwords
- [ ] Configure HTTPS/SSL
- [ ] Enable security headers
- [ ] Set up proper CORS origins
- [ ] Configure email backend
- [ ] Set up logging
- [ ] Test all endpoints

---

## 🌍 Environment-Specific Configurations

### Development

```bash
# .env.development
ENVIRONMENT=development
DJANGO_DEBUG=True
DB_ENGINE=django.db.backends.sqlite3
API_BASE_URL=http://127.0.0.1:8000/api
LOG_LEVEL=DEBUG
ENABLE_LOGGING=true
```

**Features:**

- Debug mode enabled
- SQLite database
- Verbose logging
- Local API endpoint
- Console email backend

### Staging

```bash
# .env.staging
ENVIRONMENT=staging
DJANGO_DEBUG=False
DB_ENGINE=django.db.backends.postgresql
API_BASE_URL=https://staging-api.yourdomain.com/api
LOG_LEVEL=INFO
ENABLE_LOGGING=true
```

**Features:**

- Debug mode disabled
- PostgreSQL database
- Standard logging
- Staging API endpoint
- SMTP email backend

### Production

```bash
# .env.production
ENVIRONMENT=production
DJANGO_DEBUG=False
DB_ENGINE=django.db.backends.postgresql
API_BASE_URL=https://api.yourdomain.com/api
LOG_LEVEL=WARNING
ENABLE_LOGGING=false
SECURE_SSL_REDIRECT=True
```

**Features:**

- Debug mode disabled
- PostgreSQL database
- Minimal logging
- Production API endpoint
- SSL/HTTPS enforced
- Security headers enabled

---

## 🔄 Switching Environments

### Backend

**Method 1: Environment File**

```bash
# Load development environment
export $(cat .env.development | xargs)
python manage.py runserver

# Load production environment
export $(cat .env.production | xargs)
gunicorn backend.wsgi:application
```

**Method 2: Direct Variables**

```bash
DJANGO_DEBUG=False ENVIRONMENT=production python manage.py runserver
```

### Frontend

**Method 1: Scripts**

```bash
# Development
./run_dev.sh

# Production
./run_prod.sh
```

**Method 2: VS Code**

- Select configuration in Run & Debug panel
- Press F5 to start

**Method 3: Manual**

```bash
flutter run --dart-define=ENVIRONMENT=production
```

---

## 📊 Verifying Configuration

### Backend

```python
# Run Django shell
python manage.py shell

# Check current settings
from django.conf import settings
print(f"Environment: {settings.ENVIRONMENT}")
print(f"Debug: {settings.DEBUG}")
print(f"Database: {settings.DATABASES['default']['ENGINE']}")
print(f"Allowed Hosts: {settings.ALLOWED_HOSTS}")
```

### Frontend

```dart
// In your Dart code
import 'package:your_app/config/environment.dart';

void main() {
  // Print current configuration
  Environment.printConfig();

  // Check environment
  if (Environment.isDevelopment) {
    print('Running in development mode');
  }
}
```

---

## 🐛 Troubleshooting

### Issue: "Environment variable not found"

**Solution:** Make sure the `.env` file exists and is in the correct location

```bash
# Check if .env exists
ls -la .env

# If not, copy from example
cp .env.example .env
```

### Issue: "CORS error in Flutter"

**Solution:** Add your Flutter dev server URL to `CORS_ALLOWED_ORIGINS`

```bash
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8080
```

### Issue: "API connection refused"

**Solution:** Check if backend is running and URL is correct

```bash
# Test backend
curl http://127.0.0.1:8000/api/posts/

# Check Flutter environment
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

### Issue: "Database connection error"

**Solution:** Verify database credentials

```bash
# For PostgreSQL, test connection
psql -h localhost -U postgres -d tiktok_analytics

# Check Django settings
python manage.py check
```

---

## 📚 Additional Resources

### Django Deployment

- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
- [Environment Variables Guide](https://django-environ.readthedocs.io/)

### Flutter Configuration

- [Flutter Build Flavors](https://flutter.dev/docs/deployment/flavors)
- [Environment Variables](https://dartcode.org/docs/using-dart-define-in-flutter/)

### Security

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Django Security](https://docs.djangoproject.com/en/stable/topics/security/)

---

## ✅ Configuration Checklist

Before deploying to production:

**Backend:**

- [ ] Generated new secret key
- [ ] Set `DEBUG=False`
- [ ] Configured allowed hosts
- [ ] Using PostgreSQL
- [ ] Set strong database password
- [ ] Configured CORS properly
- [ ] Set up static file serving
- [ ] Configured logging
- [ ] Enabled security headers
- [ ] Set up email backend
- [ ] Tested all endpoints

**Frontend:**

- [ ] Updated API_BASE_URL
- [ ] Disabled debug mode
- [ ] Disabled logging in production
- [ ] Built release version
- [ ] Tested on target platforms
- [ ] Verified API connectivity

**General:**

- [ ] All secrets in `.env` file
- [ ] `.env` added to `.gitignore`
- [ ] Documentation updated
- [ ] Team informed of changes
- [ ] Backup plan ready

---

**Configuration complete! Your app is ready for any environment! 🎉**
