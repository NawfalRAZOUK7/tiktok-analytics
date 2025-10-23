# CI/CD Documentation

## 🚀 Overview

This project uses **GitHub Actions** for continuous integration and continuous deployment (CI/CD). Our pipeline automates testing, building, security scanning, and deployment for both backend (Django) and frontend (Flutter).

---

## 📋 Table of Contents

1. [Workflows Overview](#workflows-overview)
2. [Backend CI/CD](#backend-cicd)
3. [Frontend CI/CD](#frontend-cicd)
4. [Docker Build & Push](#docker-build--push)
5. [Dependency Updates](#dependency-updates)
6. [Pull Request Checks](#pull-request-checks)
7. [Setup Instructions](#setup-instructions)
8. [Secrets Configuration](#secrets-configuration)
9. [Monitoring & Badges](#monitoring--badges)
10. [Troubleshooting](#troubleshooting)

---

## 🔄 Workflows Overview

### Active Workflows

| Workflow               | File                     | Trigger                    | Purpose                               |
| ---------------------- | ------------------------ | -------------------------- | ------------------------------------- |
| **Backend CI/CD**      | `backend-ci.yml`         | Push to main/develop, PRs  | Test, lint, build, deploy backend     |
| **Frontend CI/CD**     | `frontend-ci.yml`        | Push to main/develop, PRs  | Test, analyze, build, deploy frontend |
| **Docker Build**       | `docker-build.yml`       | Push to main/develop, tags | Build and push Docker images          |
| **Dependency Updates** | `dependency-updates.yml` | Weekly schedule, manual    | Auto-update dependencies              |
| **PR Checks**          | `pr-checks.yml`          | Pull requests              | Validate PR format, size, conflicts   |

### Workflow Status Badges

Add these to your README.md (replace `YOUR_USERNAME` with your GitHub username):

```markdown
[![Backend CI/CD](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/backend-ci.yml)
[![Frontend CI/CD](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/frontend-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/frontend-ci.yml)
[![Docker Build](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/docker-build.yml/badge.svg)](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/docker-build.yml)
```

---

## 🐍 Backend CI/CD

**File:** `.github/workflows/backend-ci.yml`

### Jobs

#### 1. **Test** (Matrix: Python 3.11, 3.12)

- ✅ Code formatting check (Black)
- ✅ Import sorting check (isort)
- ✅ Linting (flake8)
- ✅ Django system checks
- ✅ Database migrations
- ✅ Unit tests with coverage
- ✅ Upload coverage to Codecov

#### 2. **Security**

- 🔒 Vulnerability scanning (Safety)
- 🔒 Security issue detection (Bandit)
- 🔒 Upload security reports

#### 3. **Build & Validate**

- 📦 Install production dependencies
- 📦 Collect static files
- 📦 Run deployment checks

#### 4. **Deploy Staging** (develop branch)

- 🚀 Deploy to staging environment
- 🧪 Run smoke tests

#### 5. **Deploy Production** (main branch)

- 🚀 Deploy to production environment
- 🧪 Run smoke tests
- 📋 Create GitHub release

### Triggers

```yaml
on:
  push:
    branches: [main, develop]
    paths:
      - "backend/**"
  pull_request:
    branches: [main, develop]
    paths:
      - "backend/**"
```

### Environment Variables

```yaml
DJANGO_SECRET_KEY: test-secret-key-for-ci
DJANGO_DEBUG: "False"
ENVIRONMENT: test
```

### Tools Used

- **Black** - Code formatting
- **isort** - Import sorting
- **flake8** - Linting
- **pytest** - Testing framework
- **pytest-cov** - Coverage reporting
- **Safety** - Vulnerability scanning
- **Bandit** - Security analysis

---

## 📱 Frontend CI/CD

**File:** `.github/workflows/frontend-ci.yml`

### Jobs

#### 1. **Test**

- ✅ Flutter code analysis
- ✅ Dart formatting check
- ✅ Run tests with coverage
- ✅ Upload coverage to Codecov

#### 2. **Build Web**

- 🌐 Build Flutter web app (development)
- 📦 Upload build artifact

#### 3. **Build Android**

- 🤖 Build Android APK (development)
- 📦 Upload APK artifact

#### 4. **Build iOS** (disabled by default)

- 🍎 Build iOS app (requires Apple Developer account)

#### 5. **Deploy Web Staging** (develop branch)

- 🚀 Deploy to Firebase/Netlify staging
- 🧪 Run smoke tests

#### 6. **Deploy Web Production** (main branch)

- 🚀 Deploy to Firebase/Netlify production
- 🧪 Run smoke tests
- 📋 Create GitHub release

#### 7. **Deploy Android** (disabled by default)

- 📱 Deploy to Google Play Store

### Triggers

```yaml
on:
  push:
    branches: [main, develop]
    paths:
      - "frontend/**"
  pull_request:
    branches: [main, develop]
    paths:
      - "frontend/**"
```

### Build Configurations

```bash
# Development
flutter build web \
  --release \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_BASE_URL=https://api-dev.yourdomain.com/api

# Production
flutter build web \
  --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=${{ secrets.PRODUCTION_API_URL }}
```

### Supported Platforms

- ✅ **Web** - Deployed to Firebase/Netlify
- ✅ **Android** - APK built and uploaded
- ⏸️ **iOS** - Requires Apple Developer setup
- ⏸️ **Desktop** - Windows, macOS, Linux (can be added)

---

## 🐳 Docker Build & Push

**File:** `.github/workflows/docker-build.yml`

### Jobs

#### 1. **Build and Push**

- 🐳 Build Docker image with BuildX
- 🏷️ Auto-generate tags (branch, SHA, semver, latest)
- 📤 Push to GitHub Container Registry
- 🔒 Vulnerability scan (Trivy)
- 📊 Upload results to GitHub Security

#### 2. **Test Docker Image**

- 🧪 Pull and test image
- 🧪 Run Django checks in container
- 🧪 Validate docker-compose config

#### 3. **Deploy Docker** (main branch)

- 🚀 Deploy to production (placeholder)

### Container Registry

Images are pushed to **GitHub Container Registry (GHCR)**:

```
ghcr.io/YOUR_USERNAME/socialmedia:latest
ghcr.io/YOUR_USERNAME/socialmedia:main
ghcr.io/YOUR_USERNAME/socialmedia:v1.0.0
ghcr.io/YOUR_USERNAME/socialmedia:main-abc123
```

### Triggers

```yaml
on:
  push:
    branches: [main, develop]
    tags:
      - "v*"
  pull_request:
    branches: [main]
```

### Pull Docker Image

```bash
# Pull latest image
docker pull ghcr.io/YOUR_USERNAME/socialmedia:latest

# Run container
docker run -d \
  -e DJANGO_SECRET_KEY=your-secret \
  -e ENVIRONMENT=production \
  -p 8000:8000 \
  ghcr.io/YOUR_USERNAME/socialmedia:latest
```

### Multi-Platform Support

Images are built for:

- ✅ `linux/amd64` (x86_64)
- ✅ `linux/arm64` (ARM64/Apple Silicon)

---

## 🔄 Dependency Updates

**File:** `.github/workflows/dependency-updates.yml`

### Jobs

#### 1. **Update Python Dependencies**

- 📦 Check for updates (pip-upgrader)
- 🔒 Run security audit (Safety)
- 🔀 Create PR with updates

#### 2. **Update Flutter Dependencies**

- 📦 Upgrade packages (flutter pub upgrade)
- 🧪 Run tests to verify compatibility
- 🔀 Create PR with updates

#### 3. **Security Audit**

- 🔒 Run Safety check (Python)
- 🔒 Run Bandit scan (Python)
- 📊 Upload security reports

### Schedule

Runs **every Monday at 9 AM UTC**:

```yaml
schedule:
  - cron: "0 9 * * 1"
```

### Manual Trigger

You can also trigger manually:

```bash
# Go to Actions → Dependency Updates → Run workflow
```

### Automated PRs

Creates PRs with labels:

- `dependencies` - Dependency update
- `automated` - Automated change

---

## ✅ Pull Request Checks

**File:** `.github/workflows/pr-checks.yml`

### Jobs

#### 1. **PR Information**

- 📝 Display PR details (title, author, files changed)

#### 2. **Validate PR**

- ✅ Check PR title format (conventional commits)
- ✅ Check PR has description
- ⚠️ Check for breaking changes

#### 3. **Auto Label PR**

- 🏷️ Label based on files changed

#### 4. **Size Label**

- 🏷️ Add size labels (XS, S, M, L, XL)
- ⚠️ Warn if PR is very large

#### 5. **Check for Conflicts**

- 🔍 Detect merge conflicts

#### 6. **Lint Commit Messages**

- 📝 Validate commit message format

### PR Title Format

Use **Conventional Commits** format:

```
feat: add new feature
fix: resolve bug in authentication
docs: update README
style: format code
refactor: restructure components
test: add unit tests
chore: update dependencies
perf: improve performance
ci: update CI/CD workflow
```

### Size Labels

| Label     | Files Changed |
| --------- | ------------- |
| `size/XS` | < 10          |
| `size/S`  | 10-100        |
| `size/M`  | 100-500       |
| `size/L`  | 500-1000      |
| `size/XL` | > 1000        |

---

## ⚙️ Setup Instructions

### 1. Enable GitHub Actions

GitHub Actions is enabled by default for public repositories.

For private repositories:

1. Go to **Settings** → **Actions** → **General**
2. Enable **Allow all actions and reusable workflows**

### 2. Configure Secrets

Go to **Settings** → **Secrets and variables** → **Actions**

#### Required Secrets

| Secret               | Purpose                 | Example                          |
| -------------------- | ----------------------- | -------------------------------- |
| `PRODUCTION_API_URL` | Production API endpoint | `https://api.yourdomain.com/api` |
| `FIREBASE_TOKEN`     | Firebase deployment     | Run `firebase login:ci`          |
| `NETLIFY_TOKEN`      | Netlify deployment      | Get from Netlify dashboard       |
| `CODECOV_TOKEN`      | Coverage reporting      | Get from Codecov.io              |

#### Optional Secrets

| Secret                        | Purpose               |
| ----------------------------- | --------------------- |
| `DOCKER_USERNAME`             | Docker Hub username   |
| `DOCKER_PASSWORD`             | Docker Hub password   |
| `HEROKU_API_KEY`              | Heroku deployment     |
| `AWS_ACCESS_KEY_ID`           | AWS deployment        |
| `AWS_SECRET_ACCESS_KEY`       | AWS deployment        |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Play Store deployment |

### 3. Configure Environments

Go to **Settings** → **Environments**

Create three environments:

1. **staging** - Staging environment
2. **production** - Production environment (add protection rules)
3. **frontend-production** - Frontend production

#### Protection Rules for Production

- ✅ Required reviewers (1-2 people)
- ✅ Wait timer (5 minutes)
- ✅ Branch restrictions (main only)

### 4. Enable Dependabot (Optional)

Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"

  - package-ecosystem: "pub"
    directory: "/frontend"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### 5. Enable Branch Protection

Go to **Settings** → **Branches** → **Add rule**

For `main` branch:

- ✅ Require pull request reviews (1 approval)
- ✅ Require status checks to pass:
  - `Test Backend`
  - `Test Frontend`
  - `Security Scan`
- ✅ Require branches to be up to date
- ✅ Include administrators

---

## 🔐 Secrets Configuration

### Backend Secrets

```bash
# Production API URL
PRODUCTION_API_URL=https://api.yourdomain.com

# Django settings
DJANGO_SECRET_KEY=your-secret-key
DJANGO_ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Database (if not using platform env vars)
DB_NAME=tiktok_analytics
DB_USER=postgres
DB_PASSWORD=secure_password
DB_HOST=your-db-host
DB_PORT=5432

# CORS
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

### Frontend Secrets

```bash
# Firebase deployment
FIREBASE_TOKEN=your-firebase-token

# Netlify deployment
NETLIFY_TOKEN=your-netlify-token
NETLIFY_SITE_ID=your-site-id

# API endpoint
PRODUCTION_API_URL=https://api.yourdomain.com/api
```

### Platform-Specific Secrets

#### Heroku

```bash
# Get API key from Heroku dashboard
HEROKU_API_KEY=your-heroku-api-key
HEROKU_APP_NAME=your-app-name
HEROKU_EMAIL=your-email@example.com
```

#### Railway

```bash
# Get token from Railway dashboard
RAILWAY_TOKEN=your-railway-token
RAILWAY_SERVICE_ID=your-service-id
```

#### Docker Registry

```bash
# GitHub Container Registry (automatic with GITHUB_TOKEN)
# Or Docker Hub:
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password
```

---

## 📊 Monitoring & Badges

### Status Badges

Add to `README.md`:

```markdown
![Backend CI/CD](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/backend-ci.yml/badge.svg)
![Frontend CI/CD](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/frontend-ci.yml/badge.svg)
![Docker Build](https://github.com/YOUR_USERNAME/SocialMedia/actions/workflows/docker-build.yml/badge.svg)
```

### Coverage Badges

Sign up at [Codecov.io](https://codecov.io) and add:

```markdown
[![codecov](https://codecov.io/gh/YOUR_USERNAME/SocialMedia/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/SocialMedia)
```

### View Workflow Runs

1. Go to **Actions** tab in GitHub
2. Select workflow from left sidebar
3. Click on specific run to see details
4. View logs for each job/step

### Workflow Artifacts

Download build artifacts:

1. Go to workflow run
2. Scroll to **Artifacts** section
3. Download:
   - Web build
   - Android APK
   - Security reports
   - Coverage reports

---

## 🔧 Troubleshooting

### Common Issues

#### 1. **Workflow Not Triggering**

**Symptoms:** Push to branch but no workflow runs

**Solutions:**

- Check workflow file syntax (use YAML validator)
- Verify `paths` filter matches changed files
- Ensure Actions are enabled in repository settings
- Check branch name matches trigger configuration

#### 2. **Test Failures**

**Symptoms:** Tests pass locally but fail in CI

**Solutions:**

```bash
# Ensure environment variables are set
env:
  DJANGO_SECRET_KEY: test-secret-key
  ENVIRONMENT: test

# Check for missing dependencies
pip install -r requirements.txt

# Verify database setup
python manage.py migrate
```

#### 3. **Docker Build Fails**

**Symptoms:** Docker image fails to build

**Solutions:**

```bash
# Test locally first
docker build -t test-image .

# Check Dockerfile syntax
docker build --no-cache -t test-image .

# Verify build context
ls -la  # Ensure Dockerfile is in root
```

#### 4. **Deployment Fails**

**Symptoms:** Build succeeds but deployment fails

**Solutions:**

- Verify secrets are set correctly
- Check environment is configured
- Ensure platform credentials are valid
- Review deployment logs in Actions

#### 5. **Permission Denied**

**Symptoms:** `Permission denied` errors

**Solutions:**

```yaml
# Add required permissions to job
permissions:
  contents: read
  packages: write
  pull-requests: write
```

### Debug Tips

#### Enable Debug Logging

Add to workflow:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

#### Test Workflow Locally

Use [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow
act -j test  # Run specific job
act push     # Simulate push event
```

#### View Workflow Syntax

```bash
# Validate workflow syntax
yamllint .github/workflows/backend-ci.yml

# Use GitHub CLI to view runs
gh workflow list
gh run list
gh run view <run-id>
```

---

## 🚀 Advanced Configuration

### Custom Deployment

#### Heroku Deployment

Add to `deploy-production` job:

```yaml
- name: Deploy to Heroku
  uses: akhileshns/heroku-deploy@v3.12.14
  with:
    heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
    heroku_app_name: "your-app-name"
    heroku_email: "your-email@example.com"
```

#### Railway Deployment

```yaml
- name: Deploy to Railway
  run: |
    npm install -g @railway/cli
    railway link ${{ secrets.RAILWAY_SERVICE_ID }}
    railway up
  env:
    RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

#### Firebase Hosting

```yaml
- name: Deploy to Firebase
  uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: "${{ secrets.GITHUB_TOKEN }}"
    firebaseServiceAccount: "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}"
    channelId: live
```

### Matrix Testing

Test multiple versions:

```yaml
strategy:
  matrix:
    python-version: ["3.10", "3.11", "3.12"]
    django-version: ["4.2", "5.0"]
```

### Scheduled Workflows

```yaml
on:
  schedule:
    - cron: "0 0 * * 0" # Weekly
    - cron: "0 */6 * * *" # Every 6 hours
    - cron: "0 9 * * 1-5" # Weekdays at 9 AM
```

---

## 📚 Additional Resources

### Documentation

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/ci)
- [Django Testing](https://docs.djangoproject.com/en/stable/topics/testing/)

### Tools

- [Act](https://github.com/nektos/act) - Run workflows locally
- [Nektos Act Docker](https://github.com/nektos/act) - Local testing
- [Workflow Visualizer](https://github.com/marketplace/actions/workflow-visualizer)

### Marketplaces

- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [Codecov](https://codecov.io)
- [Snyk](https://snyk.io) - Security scanning

---

## ✅ CI/CD Checklist

### Initial Setup

- [ ] Workflows committed to `.github/workflows/`
- [ ] Secrets configured in repository settings
- [ ] Environments created (staging, production)
- [ ] Branch protection rules enabled
- [ ] Status badges added to README
- [ ] Codecov integration enabled (optional)

### Testing

- [ ] Backend tests pass locally
- [ ] Frontend tests pass locally
- [ ] Docker build succeeds locally
- [ ] All workflows trigger correctly
- [ ] Test matrix covers required versions

### Security

- [ ] Security scanning enabled (Safety, Bandit, Trivy)
- [ ] Dependabot configured
- [ ] Secret scanning enabled
- [ ] No secrets in code
- [ ] Protected branches configured

### Deployment

- [ ] Staging environment working
- [ ] Production environment working
- [ ] Smoke tests passing
- [ ] Rollback strategy defined
- [ ] Monitoring enabled

### Documentation

- [ ] CI/CD process documented
- [ ] Deployment process documented
- [ ] Troubleshooting guide created
- [ ] Team trained on workflows

---

**CI/CD implementation complete! 🎉**

Your project now has automated testing, security scanning, building, and deployment pipelines for both backend and frontend.
