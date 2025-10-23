# GitHub Actions Deployment Setup

This document explains how to configure GitHub Environments and Secrets for CI/CD deployment.

## Current Status

✅ **CI/CD Workflows Created**:

- `backend-ci.yml` - Backend testing, security scanning, and deployment
- `frontend-ci.yml` - Flutter web/mobile builds and deployment
- `docker-build.yml` - Docker image building and deployment

⚠️ **Deployment Steps Disabled**: Environment configurations are commented out until you're ready to deploy.

---

## Setup Instructions

### 1. Create GitHub Environments

Go to **Settings → Environments** in your GitHub repository and create:

1. **`staging`** (for backend staging)

   - URL: `https://staging.yourdomain.com`
   - Protection rules: None (auto-deploy on push to `develop` branch)

2. **`production`** (for backend production)

   - URL: `https://yourdomain.com`
   - Protection rules: Require reviewers (recommended)

3. **`frontend-staging`** (for frontend staging)

   - URL: `https://staging-app.yourdomain.com`
   - Protection rules: None

4. **`frontend-production`** (for frontend production)

   - URL: `https://app.yourdomain.com`
   - Protection rules: Require reviewers

5. **`docker-production`** (for Docker deployment)

   - URL: `https://yourdomain.com`
   - Protection rules: Require reviewers

6. **`android-production`** (for Play Store deployment)
   - URL: Your Play Store app URL
   - Protection rules: Require reviewers

---

### 2. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

#### Backend Secrets:

```
HEROKU_API_KEY              # Heroku deployment token (if using Heroku)
AWS_ACCESS_KEY_ID           # AWS credentials (if using AWS)
AWS_SECRET_ACCESS_KEY       # AWS credentials (if using AWS)
DIGITALOCEAN_TOKEN          # DigitalOcean token (if using DO)
DOCKER_USERNAME             # Docker Hub username
DOCKER_PASSWORD             # Docker Hub password/token
```

#### Frontend Secrets:

```
PRODUCTION_API_URL          # Production API URL (e.g., https://api.yourdomain.com)
STAGING_API_URL             # Staging API URL (e.g., https://staging-api.yourdomain.com)
FIREBASE_TOKEN              # Firebase CI token (run: firebase login:ci)
NETLIFY_TOKEN               # Netlify personal access token
ANDROID_KEYSTORE_BASE64     # Base64-encoded keystore file
ANDROID_KEY_ALIAS           # Keystore alias
ANDROID_KEY_PASSWORD        # Key password
ANDROID_STORE_PASSWORD      # Keystore password
```

---

### 3. Enable Deployment Steps

Once environments and secrets are configured:

1. **Backend CI** (`backend-ci.yml`):

   - Uncomment the `environment:` blocks in `deploy-staging` and `deploy-production` jobs
   - Update deployment commands with your actual deployment strategy

2. **Frontend CI** (`frontend-ci.yml`):

   - Uncomment the `environment:` blocks in deploy jobs
   - Uncomment and configure Firebase/Netlify deployment commands
   - Remove `&& false` from Android deploy job when ready

3. **Docker Build** (`docker-build.yml`):
   - Uncomment the `environment:` block in `deploy` job
   - Add actual deployment commands

---

## Deployment Strategies

### Option 1: Heroku (Easiest)

**Backend**:

```yaml
- name: Deploy to Heroku
  uses: akhileshns/heroku-deploy@v3.12.12
  with:
    heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
    heroku_app_name: "your-app-name"
    heroku_email: "your-email@example.com"
```

**Frontend**: Deploy to Netlify or Firebase Hosting

### Option 2: Docker + DigitalOcean

**Backend**:

```yaml
- name: Deploy to DigitalOcean
  run: |
    doctl auth init --access-token ${{ secrets.DIGITALOCEAN_TOKEN }}
    doctl apps create-deployment $APP_ID
```

**Frontend**: Use DigitalOcean App Platform or Spaces + CDN

### Option 3: AWS (Advanced)

**Backend**: Deploy to EC2, ECS, or Elastic Beanstalk
**Frontend**: Deploy to S3 + CloudFront

---

## Testing Locally

Before enabling deployment:

1. **Test workflows locally** with [act](https://github.com/nektos/act):

   ```bash
   brew install act
   act -j test  # Run test job locally
   ```

2. **Validate workflow syntax**:

   ```bash
   # GitHub CLI
   gh workflow view backend-ci.yml
   ```

3. **Dry-run deployment**:
   - Add `--dry-run` flags to deployment commands
   - Test with staging environment first

---

## Monitoring

After deployment is enabled:

- **GitHub Actions**: Monitor workflow runs in the Actions tab
- **Environments**: View deployment history in Settings → Environments
- **Notifications**: Configure email/Slack notifications for failed deployments

---

## Security Best Practices

✅ **Do**:

- Use GitHub Environments for deployment protection
- Require manual approval for production deployments
- Rotate secrets regularly
- Use least-privilege access tokens
- Enable branch protection rules

❌ **Don't**:

- Commit secrets to the repository
- Share tokens between environments
- Use personal tokens for production
- Skip security scanning jobs

---

## Current Configuration Status

| Component    | Status            | Notes                            |
| ------------ | ----------------- | -------------------------------- |
| Backend CI   | ✅ Ready          | Tests + security scanning active |
| Frontend CI  | ✅ Ready          | Web + Android builds working     |
| Docker Build | ✅ Ready          | Multi-stage builds optimized     |
| Deployment   | ⏸️ Paused         | Uncomment when ready to deploy   |
| Secrets      | ⚠️ Not configured | Add in GitHub Settings           |
| Environments | ⚠️ Not configured | Create in GitHub Settings        |

---

## Quick Start Checklist

When you're ready to deploy:

- [ ] Choose deployment platform (Heroku/AWS/DigitalOcean/etc.)
- [ ] Create GitHub Environments
- [ ] Add required secrets to GitHub
- [ ] Update workflow files with actual deployment commands
- [ ] Uncomment `environment:` blocks
- [ ] Test with staging environment first
- [ ] Enable production deployment after testing
- [ ] Set up monitoring and alerts
- [ ] Document your deployment process

---

## Support

For help with specific deployment platforms:

- **Heroku**: https://devcenter.heroku.com/articles/github-integration
- **Netlify**: https://docs.netlify.com/site-deploys/create-deploys/
- **Firebase**: https://firebase.google.com/docs/hosting/github-integration
- **AWS**: https://aws.amazon.com/blogs/devops/complete-ci-cd-with-aws-codecommit-aws-codebuild-aws-codedeploy-and-aws-codepipeline/
- **DigitalOcean**: https://docs.digitalocean.com/products/app-platform/how-to/manage-deployments/
