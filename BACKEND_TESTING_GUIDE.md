# Backend Testing & Management Commands - Complete Guide

## 📋 Overview

This document covers the comprehensive testing infrastructure and management commands for the SocialMedia backend. The project uses **pytest** with Django integration for testing and includes powerful management commands for data import.

## 📑 Table of Contents

1. [Test Infrastructure](#test-infrastructure)
2. [Running Tests](#running-tests)
3. [Test Coverage](#test-coverage)
4. [Management Commands](#management-commands)
5. [Writing Tests](#writing-tests)
6. [Continuous Integration](#continuous-integration)

---

## 🏗️ Test Infrastructure

### Testing Framework

- **pytest**: Modern testing framework with powerful features
- **pytest-django**: Django plugin for pytest
- **pytest-cov**: Coverage reporting plugin

### 📁 Test Structure

```
backend/posts/tests/
├── __init__.py
├── conftest.py                 # Pytest fixtures and utilities
├── test_models.py              # Model unit tests (30+ tests)
├── test_serializers.py         # Serializer tests (20+ tests)
├── test_views.py               # API integration tests (40+ tests)
└── test_commands.py            # Management command tests (15+ tests)
```

### ⚙️ Configuration

**pytest.ini**:

```ini
[pytest]
DJANGO_SETTINGS_MODULE = backend.settings
python_files = tests.py test_*.py *_tests.py
addopts =
    --cov=posts
    --cov=accounts
    --cov-report=html
    --cov-report=term-missing
    --cov-report=xml
    --cov-fail-under=70
    -v
    --tb=short

markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
    unit: marks tests as unit tests
```

### 🔧 Test Fixtures

Available fixtures in `conftest.py`:

1. **sample_post_data**: Valid post data dictionary
2. **create_post**: Factory function to create Post instances
3. **create_multiple_posts**: Factory to create N posts with incremental data
4. **api_client**: DRF APIClient for testing endpoints
5. **authenticated_client**: APIClient with authentication token
6. **sample_json_file**: Temporary JSON file for import tests

---

## 🚀 Running Tests

### Install Dependencies

```bash
cd backend
pip install pytest pytest-django pytest-cov
```

Or with requirements:

```bash
pip install -r requirements-dev.txt
```

### Run All Tests

```bash
cd backend
pytest
```

### Run Specific Test Files

```bash
# Model tests only
pytest posts/tests/test_models.py

# Serializer tests only
pytest posts/tests/test_serializers.py

# API/view tests only
pytest posts/tests/test_views.py

# Management command tests only
pytest posts/tests/test_commands.py
```

### Run Specific Test Classes

```bash
# Run all tests in TestPostModel class
pytest posts/tests/test_models.py::TestPostModel

# Run all tests in TestPostListView class
pytest posts/tests/test_views.py::TestPostListView
```

### Run Specific Test Methods

```bash
# Run single test method
pytest posts/tests/test_models.py::TestPostModel::test_create_post_with_required_fields
```

### Run Tests by Marker

```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Run only slow tests
pytest -m slow

# Exclude slow tests
pytest -m "not slow"
```

### Run Tests with Verbose Output

```bash
# More verbose output
pytest -v

# Even more verbose (show print statements)
pytest -vv -s
```

### Run Tests in Parallel

```bash
# Install pytest-xdist first
pip install pytest-xdist

# Run with 4 workers
pytest -n 4
```

---

## 📊 Test Coverage

### Generate Coverage Report

Coverage is automatically generated when running tests:

```bash
pytest
```

### View Coverage Reports

**Terminal Output**:

```bash
# Shows coverage summary in terminal
pytest --cov=posts --cov-report=term-missing
```

**HTML Report**:

```bash
# Generate HTML report
pytest --cov=posts --cov-report=html

# Open in browser (macOS)
open htmlcov/index.html

# Open in browser (Linux)
xdg-open htmlcov/index.html
```

**XML Report** (for CI/CD):

```bash
pytest --cov=posts --cov-report=xml
```

### Coverage Requirements

- **Minimum Coverage**: 70% (enforced by `--cov-fail-under=70`)
- Tests will fail if coverage drops below threshold
- Focus on critical paths: models, serializers, views

### Current Test Coverage

| Module                  | Tests     | Coverage |
| ----------------------- | --------- | -------- |
| **models.py**           | 30+ tests | ~95%     |
| **serializers.py**      | 20+ tests | ~90%     |
| **views.py**            | 40+ tests | ~85%     |
| **management/commands** | 15+ tests | ~90%     |

**Total**: 105+ comprehensive tests

---

## 🛠️ Management Commands

### import_tiktok_json Command

Import TikTok posts from JSON file with validation, duplicate handling, and progress reporting.

#### Basic Usage

```bash
cd backend
python manage.py import_tiktok_json path/to/posts.json
```

#### Command Options

```bash
python manage.py import_tiktok_json <json_file> [options]

Options:
  --dry-run              Validate without importing
  --clear-existing       Delete all existing posts before import
  --skip-duplicates      Skip posts with duplicate post_id (default)
  --update-duplicates    Update existing posts with new data
```

#### Examples

**1. Dry Run (Validation Only)**:

```bash
python manage.py import_tiktok_json posts.json --dry-run
```

- Validates JSON format and post data
- Shows what would be imported
- No data is actually created

**2. Standard Import**:

```bash
python manage.py import_tiktok_json posts.json
```

- Imports all valid posts
- Skips duplicates by default
- Shows progress bar

**3. Clear and Import**:

```bash
python manage.py import_tiktok_json posts.json --clear-existing
```

- ⚠️ **WARNING**: Deletes all existing posts
- Imports fresh data from JSON
- Use for complete data refresh

**4. Update Existing Posts**:

```bash
python manage.py import_tiktok_json posts.json --update-duplicates
```

- Updates posts with matching post_id
- Creates new posts for non-duplicates
- Preserves database integrity

#### JSON Format

Expected JSON structure:

```json
[
  {
    "id": "1234567890123456789",
    "title": "My TikTok Post #fyp #viral",
    "likes": 1000,
    "views": 50000,
    "comments": 100,
    "shares": 50,
    "date": "2024-01-15T10:30:00Z",
    "cover_url": "https://example.com/cover.jpg",
    "video_link": "https://tiktok.com/@user/video/123",
    "hashtags": ["fyp", "viral"],
    "description": "Check out my awesome video!"
  }
]
```

**Required Fields**:

- `id` (string): Unique post identifier
- `title` (string): Post title
- `likes` (integer): Number of likes
- `date` (ISO 8601 datetime): Post date
- `cover_url` (URL): Cover image URL
- `video_link` (URL): Video link

**Optional Fields**:

- `views` (integer): Number of views
- `comments` (integer): Number of comments
- `shares` (integer): Number of shares
- `hashtags` (array): List of hashtags
- `description` (string): Post description

#### Output Example

```
Importing posts from posts.json...

Processing: [====================================] 100%

Summary:
--------
Total: 150
Created: 145
Updated: 0
Skipped: 3
Errors: 2

Successfully imported 145 posts from posts.json
```

#### Error Handling

The command includes comprehensive error handling:

1. **File Validation**: Checks file exists and is valid JSON
2. **Data Validation**: Validates each post against model constraints
3. **Transaction Safety**: Rolls back on critical errors
4. **Error Reporting**: Shows first 5 errors with details
5. **Progress Tracking**: Real-time progress bar

---

## ✍️ Writing Tests

### Test Model Fields

```python
@pytest.mark.django_db
def test_create_post(create_post):
    """Test creating a post."""
    post = create_post(
        post_id='123',
        title='Test',
        likes=100
    )

    assert post.post_id == '123'
    assert post.title == 'Test'
    assert post.likes == 100
```

### Test Model Validation

```python
@pytest.mark.django_db
def test_negative_likes_raises_error(create_post):
    """Test that negative likes raise validation error."""
    with pytest.raises(ValidationError):
        post = create_post(likes=-100)
        post.full_clean()
```

### Test Serializers

```python
def test_serialize_post(sample_post_data):
    """Test serializing post data."""
    serializer = PostSerializer(data=sample_post_data)

    assert serializer.is_valid()
    post = serializer.save()

    assert post.title == sample_post_data['title']
```

### Test API Endpoints

```python
@pytest.mark.django_db
def test_list_posts(api_client, create_multiple_posts):
    """Test listing posts via API."""
    create_multiple_posts(count=10)

    url = reverse('post-list')
    response = api_client.get(url)

    assert response.status_code == 200
    assert response.data['count'] == 10
```

### Test Authentication

```python
@pytest.mark.django_db
def test_create_requires_auth(api_client, sample_post_data):
    """Test that creating post requires authentication."""
    url = reverse('post-list')
    response = api_client.post(url, sample_post_data, format='json')

    assert response.status_code in [401, 403]
```

### Test Management Commands

```python
@pytest.mark.django_db
def test_import_command(sample_post_data):
    """Test import management command."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json') as f:
        json.dump([sample_post_data], f)
        f.flush()

        call_command('import_tiktok_json', f.name)

        assert Post.objects.count() == 1
```

### Using Fixtures

```python
@pytest.fixture
def custom_post(create_post):
    """Create a post with specific data."""
    return create_post(
        likes=10000,
        views=500000,
        title='Viral Post'
    )

@pytest.mark.django_db
def test_with_custom_fixture(custom_post):
    """Test using custom fixture."""
    assert custom_post.likes == 10000
```

---

## 🔄 Continuous Integration

### GitHub Actions Integration

Tests run automatically on:

- **Push** to any branch
- **Pull Request** to develop/main
- **Scheduled** (daily)

### CI Workflow

`.github/workflows/backend-ci.yml`:

```yaml
- name: Run Tests
  run: |
    cd backend
    pytest --cov=posts --cov-report=xml

- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./backend/coverage.xml
```

### Coverage Reporting

Coverage is automatically uploaded to:

- **Codecov**: Public coverage reports
- **GitHub Actions**: Artifacts stored for 30 days

### Badge Status

[![Backend CI](https://github.com/username/socialmedia/workflows/Backend%20CI/badge.svg)](https://github.com/username/socialmedia/actions)
[![codecov](https://codecov.io/gh/username/socialmedia/branch/main/graph/badge.svg)](https://codecov.io/gh/username/socialmedia)

---

## 📝 Best Practices

### Testing Best Practices

1. **Isolation**: Each test should be independent
2. **Descriptive Names**: Use clear test method names
3. **Arrange-Act-Assert**: Follow AAA pattern
4. **Fixtures**: Use fixtures for common setup
5. **Markers**: Tag tests appropriately (unit/integration/slow)
6. **Coverage**: Aim for high coverage but focus on critical paths
7. **Fast Tests**: Keep unit tests fast, mark slow tests

### Management Command Best Practices

1. **Validation**: Always validate input before processing
2. **Progress**: Show progress for long-running operations
3. **Dry Run**: Support dry-run mode for testing
4. **Transactions**: Use transactions for data integrity
5. **Error Handling**: Provide clear error messages
6. **Logging**: Log important operations
7. **Documentation**: Document command usage and options

---

## 🔧 Troubleshooting

### Common Issues

**1. Import Errors**:

```bash
# Make sure you're in the backend directory
cd backend

# Ensure DJANGO_SETTINGS_MODULE is set
export DJANGO_SETTINGS_MODULE=backend.settings
```

**2. Database Errors**:

```bash
# Run migrations first
python manage.py migrate

# Use --create-db flag
pytest --create-db
```

**3. Coverage Not Generated**:

```bash
# Ensure pytest-cov is installed
pip install pytest-cov

# Run with explicit coverage
pytest --cov=posts --cov-report=html
```

**4. Tests Hanging**:

```bash
# Check for infinite loops or missing mocks
# Use -vv to see which test is running
pytest -vv
```

**5. Import Command Fails**:

```bash
# Check JSON format
python -m json.tool posts.json

# Run with --dry-run to validate
python manage.py import_tiktok_json posts.json --dry-run
```

### Getting Help

- Check test output for error messages
- Review test files for examples
- Check Django test documentation
- Review pytest documentation
- Open an issue on GitHub

---

## 📈 Summary

### Test Statistics

- **Total Tests**: 105+
- **Model Tests**: 30+
- **Serializer Tests**: 20+
- **API Tests**: 40+
- **Command Tests**: 15+
- **Coverage**: 70%+ (enforced)

### Key Features

✅ Comprehensive test suite with 105+ tests  
✅ pytest with Django integration  
✅ Coverage reporting (HTML/XML/Terminal)  
✅ CI/CD integration with GitHub Actions  
✅ Management command for data import  
✅ Fixtures for reusable test data  
✅ Authentication and permission tests  
✅ Transaction safety and rollback  
✅ Progress reporting for imports  
✅ Validation and error handling

---

## 🎯 Next Steps

1. **Run Tests**: `cd backend && pytest`
2. **View Coverage**: `open htmlcov/index.html`
3. **Import Data**: `python manage.py import_tiktok_json data.json`
4. **Write More Tests**: Add tests for new features
5. **Monitor CI**: Check GitHub Actions for automated test runs

For more information, see:

- [Django Testing Documentation](https://docs.djangoproject.com/en/stable/topics/testing/)
- [pytest Documentation](https://docs.pytest.org/)
- [pytest-django Documentation](https://pytest-django.readthedocs.io/)
- [CI/CD Guide](./CI_CD_GUIDE.md)
