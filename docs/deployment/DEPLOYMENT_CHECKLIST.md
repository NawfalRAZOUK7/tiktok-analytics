# 🚀 Deployment Checklist

## Pre-Deployment

### Security

- [ ] Generate new `DJANGO_SECRET_KEY` for production
- [ ] Set `DJANGO_DEBUG=False`
- [ ] Review and update `DJANGO_ALLOWED_HOSTS`
- [ ] Use strong database passwords (min 20 characters)
- [ ] Enable HTTPS/SSL
- [ ] Configure security headers
- [ ] Review CORS settings
- [ ] Remove any hardcoded secrets from code
- [ ] Audit dependencies for vulnerabilities

### Database

- [ ] Set up PostgreSQL database
- [ ] Create database backup strategy
- [ ] Configure database connection pooling
- [ ] Set up database migrations
- [ ] Test database connectivity
- [ ] Configure database backup schedule

### Static Files

- [ ] Configure static file serving
- [ ] Run `python manage.py collectstatic`
- [ ] Test static file access
- [ ] Consider CDN for static files (optional)
- [ ] Configure media file storage

### Environment

- [ ] Create `.env.production` file
- [ ] Verify all environment variables
- [ ] Test with production settings locally
- [ ] Configure logging
- [ ] Set up error monitoring (Sentry, etc.)

### Testing

- [ ] Run all backend tests
- [ ] Run all frontend tests
- [ ] Test authentication flow
- [ ] Test API endpoints
- [ ] Load testing (optional)
- [ ] Security testing (optional)

---

## Backend Deployment

### Django Configuration

- [ ] Set `DEBUG=False`
- [ ] Configure `ALLOWED_HOSTS`
- [ ] Set up proper `SECRET_KEY`
- [ ] Configure database (PostgreSQL recommended)
- [ ] Set up static file serving (WhiteNoise or S3)
- [ ] Configure email backend
- [ ] Set up logging
- [ ] Enable security middleware

### Database Setup

```bash
# Create PostgreSQL database
createdb tiktok_analytics

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput
```

### Server Setup

**Option 1: Gunicorn (Linux)**

```bash
# Install gunicorn
pip install gunicorn

# Test run
gunicorn backend.wsgi:application --bind 0.0.0.0:8000

# Production run with process manager (systemd/supervisor)
gunicorn backend.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 3 \
  --timeout 120 \
  --access-logfile /var/log/gunicorn/access.log \
  --error-logfile /var/log/gunicorn/error.log \
  --daemon
```

**Option 2: Docker**

```bash
# Build image
docker build -t tiktok-analytics-backend .

# Run with docker-compose
docker-compose up -d
```

**Option 3: Platform as a Service**

- Heroku
- Railway
- Render
- AWS Elastic Beanstalk
- Google Cloud Run
- Azure App Service

### Post-Deployment Backend Checks

- [ ] Server is running
- [ ] Database connection successful
- [ ] Admin panel accessible
- [ ] API endpoints responding
- [ ] Authentication working
- [ ] Static files loading
- [ ] HTTPS configured
- [ ] Logs being written

---

## Frontend Deployment

### Flutter Web

**Build for Web:**

```bash
cd frontend

# Build production web app
flutter build web \
  --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# Output in: build/web/
```

**Deploy to:**

- [ ] Firebase Hosting
- [ ] Netlify
- [ ] Vercel
- [ ] GitHub Pages
- [ ] AWS S3 + CloudFront
- [ ] Azure Static Web Apps

**Example: Firebase Hosting**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting

# Deploy
firebase deploy
```

### Flutter Mobile (Android)

**Build Android APK:**

```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# Output in: build/app/outputs/flutter-apk/app-release.apk
```

**Build Android App Bundle (for Play Store):**

```bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api

# Output in: build/app/outputs/bundle/release/app-release.aab
```

**Deploy to:**

- [ ] Google Play Store
- [ ] Internal testing track
- [ ] Beta testing track
- [ ] Production track

### Flutter Mobile (iOS)

**Build iOS App:**

```bash
flutter build ios --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

**Deploy to:**

- [ ] TestFlight (beta)
- [ ] App Store (production)

### Post-Deployment Frontend Checks

- [ ] App builds successfully
- [ ] API connectivity working
- [ ] Authentication functional
- [ ] All features working
- [ ] No console errors
- [ ] Performance acceptable
- [ ] Responsive on all devices

---

## Platform-Specific Guides

### Heroku

**Backend:**

```bash
# Login
heroku login

# Create app
heroku create your-app-name

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set DJANGO_SECRET_KEY=your-secret-key
heroku config:set DJANGO_DEBUG=False
heroku config:set DJANGO_ALLOWED_HOSTS=your-app-name.herokuapp.com

# Deploy
git push heroku main

# Run migrations
heroku run python backend/manage.py migrate

# Create superuser
heroku run python backend/manage.py createsuperuser
```

### Railway

**Backend:**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize
railway init

# Deploy
railway up

# Set environment variables in Railway dashboard
```

### Render

**Backend:**

1. Connect GitHub repo
2. Select "Web Service"
3. Configure:
   - Build Command: `pip install -r backend/requirements.prod.txt`
   - Start Command: `cd backend && gunicorn backend.wsgi:application`
4. Add environment variables
5. Deploy

### Docker Deployment

```bash
# Build and run with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Rebuild
docker-compose up -d --build
```

---

## Monitoring & Maintenance

### Set Up Monitoring

- [ ] Error tracking (Sentry, Rollbar)
- [ ] Application monitoring (New Relic, DataDog)
- [ ] Uptime monitoring (UptimeRobot, Pingdom)
- [ ] Log aggregation (Papertrail, Loggly)

### Regular Maintenance

- [ ] Schedule database backups
- [ ] Monitor disk space
- [ ] Review logs regularly
- [ ] Update dependencies
- [ ] Security patches
- [ ] Performance optimization
- [ ] SSL certificate renewal

### Backup Strategy

```bash
# Database backup
pg_dump tiktok_analytics > backup_$(date +%Y%m%d).sql

# Media files backup
tar -czf media_backup_$(date +%Y%m%d).tar.gz media/

# Automated backups (cron example)
0 2 * * * /path/to/backup_script.sh
```

---

## Rollback Plan

### Backend Rollback

```bash
# Revert to previous deployment
git revert HEAD
git push origin main

# Or use platform-specific rollback
heroku rollback
# or
railway rollback
```

### Database Rollback

```bash
# Restore from backup
psql tiktok_analytics < backup_20241022.sql

# Rollback migrations
python manage.py migrate app_name migration_name
```

---

## Post-Deployment

### Verify Everything Works

- [ ] Homepage loads
- [ ] Authentication works
- [ ] API endpoints respond
- [ ] Database queries succeed
- [ ] Static files load
- [ ] Media files upload
- [ ] Email sending works
- [ ] Logs are being written
- [ ] SSL certificate valid
- [ ] CORS configured correctly

### Performance Testing

```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 https://api.yourdomain.com/api/posts/

# Or use artillery
npm install -g artillery
artillery quick --count 100 --num 10 https://api.yourdomain.com/api/posts/
```

### Update Documentation

- [ ] Update README with production URLs
- [ ] Document deployment process
- [ ] Update team on changes
- [ ] Create runbook for common issues

---

## Troubleshooting

### Common Issues

**Issue: Static files not loading**

```bash
# Solution
python manage.py collectstatic --clear --noinput
```

**Issue: Database connection failed**

```bash
# Check connection
python manage.py dbshell

# Verify credentials in .env
```

**Issue: CORS errors**

```python
# Update settings.py
CORS_ALLOWED_ORIGINS = [
    'https://yourdomain.com',
    'https://www.yourdomain.com',
]
```

**Issue: 502 Bad Gateway**

- Check if backend is running
- Verify port binding
- Check firewall rules
- Review server logs

---

## Security Hardening

### SSL/TLS Configuration

- [ ] Install SSL certificate
- [ ] Enable HTTPS redirect
- [ ] Configure HSTS headers
- [ ] Update CORS to HTTPS origins

### Additional Security

- [ ] Enable rate limiting
- [ ] Configure fail2ban
- [ ] Set up firewall rules
- [ ] Regular security audits
- [ ] Penetration testing (optional)

---

## Costs Estimation

### Backend Hosting

- **Heroku**: $7-$25/month
- **Railway**: $5-$20/month
- **Render**: $7-$25/month
- **DigitalOcean**: $5-$24/month
- **AWS**: Variable, ~$10-$50/month

### Database

- **Heroku Postgres**: $9-$50/month
- **AWS RDS**: $15-$100/month
- **Railway**: Included
- **Render**: Included

### Frontend Hosting (Web)

- **Firebase**: Free tier available
- **Netlify**: Free tier available
- **Vercel**: Free tier available
- **Cloudflare Pages**: Free

### Monitoring

- **Sentry**: Free tier for small apps
- **New Relic**: Free tier available
- **LogRocket**: Free tier available

---

## Success Criteria

### Performance

- [ ] Page load time < 3 seconds
- [ ] API response time < 500ms
- [ ] Database query time < 100ms
- [ ] 99.9% uptime

### Functionality

- [ ] All features working
- [ ] No critical bugs
- [ ] Authentication secure
- [ ] Data integrity maintained

### Security

- [ ] HTTPS enabled
- [ ] No exposed secrets
- [ ] Rate limiting active
- [ ] Security headers configured

---

**Deployment complete! Your app is now live! 🎉**

Remember to monitor logs and performance metrics after deployment.
