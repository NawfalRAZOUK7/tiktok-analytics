"""
Test fixtures and utilities for posts app tests.
"""

from datetime import datetime, timedelta
from django.utils import timezone
import pytest
from posts.models import Post


@pytest.fixture
def sample_post_data():
    """Sample valid post data for testing."""
    return {
        'id': '1234567890123456789',
        'title': 'Test TikTok Post #fyp #viral',
        'likes': 1000,
        'date': '2024-01-15T10:30:00Z',
        'cover_url': 'https://example.com/cover.jpg',
        'video_link': 'https://tiktok.com/@user/video/1234567890123456789',
        'views': 50000,
        'comments': 100,
        'shares': 50,
        'bookmarks': 25,
        'duration': 30,
        'hashtags': ['fyp', 'viral', 'trending'],
        'music': 'Original Sound - Username',
        'location': 'New York, USA'
    }


@pytest.fixture
def create_post():
    """Factory function to create posts for testing."""
    def _create_post(**kwargs):
        defaults = {
            'post_id': '1234567890123456789',
            'title': 'Test Post',
            'likes': 100,
            'date': timezone.now(),
            'cover_url': 'https://example.com/cover.jpg',
            'video_link': 'https://tiktok.com/@user/video/1234567890123456789',
        }
        defaults.update(kwargs)
        return Post.objects.create(**defaults)
    return _create_post


@pytest.fixture
def create_multiple_posts(create_post):
    """Create multiple posts for testing."""
    def _create_multiple(count=10, **kwargs):
        posts = []
        base_date = timezone.now() - timedelta(days=count)
        
        for i in range(count):
            post_data = {
                'post_id': f'123456789012345678{i}',
                'title': f'Test Post {i + 1}',
                'likes': (i + 1) * 100,
                'views': (i + 1) * 1000,
                'comments': (i + 1) * 10,
                'date': base_date + timedelta(days=i),
                **kwargs
            }
            posts.append(create_post(**post_data))
        
        return posts
    return _create_multiple


@pytest.fixture
def api_client():
    """DRF API client for testing."""
    from rest_framework.test import APIClient
    return APIClient()


@pytest.fixture
def authenticated_client(api_client, django_user_model):
    """Authenticated API client."""
    from rest_framework.authtoken.models import Token
    
    user = django_user_model.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='testpass123'
    )
    token, created = Token.objects.get_or_create(user=user)
    api_client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
    api_client.user = user
    return api_client


@pytest.fixture
def sample_json_file(tmp_path, sample_post_data):
    """Create a temporary JSON file with sample data."""
    import json
    
    json_file = tmp_path / "test_posts.json"
    posts_data = [
        sample_post_data,
        {
            **sample_post_data,
            'id': '9876543210987654321',
            'title': 'Another Test Post',
            'likes': 2000,
        }
    ]
    
    with open(json_file, 'w') as f:
        json.dump(posts_data, f)
    
    return str(json_file)


def assert_post_equal(post, expected_data):
    """Helper to assert post fields match expected data."""
    assert post.post_id == str(expected_data['id'])
    assert post.title == expected_data['title']
    assert post.likes == expected_data['likes']
    assert post.cover_url == expected_data['cover_url']
    assert post.video_link == expected_data['video_link']
    
    if 'views' in expected_data:
        assert post.views == expected_data['views']
    if 'comments' in expected_data:
        assert post.comments == expected_data['comments']
    if 'hashtags' in expected_data:
        assert post.hashtags == expected_data['hashtags']
