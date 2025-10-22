"""
Unit tests for Post serializers.
"""

import pytest
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from posts.serializers import PostSerializer, PostImportSerializer
from posts.models import Post


@pytest.mark.django_db
@pytest.mark.unit
class TestPostSerializer:
    """Test PostSerializer functionality."""

    def test_serialize_post(self, create_post):
        """Test serializing a post object."""
        post = create_post(
            post_id='1234567890123456789',
            title='Test Post',
            likes=1000,
            views=50000,
            comments=100
        )
        
        serializer = PostSerializer(post)
        data = serializer.data
        
        assert data['post_id'] == '1234567890123456789'
        assert data['title'] == 'Test Post'
        assert data['likes'] == 1000
        assert data['views'] == 50000
        assert data['comments'] == 100

    def test_serialize_post_with_null_fields(self, create_post):
        """Test serializing a post with null optional fields."""
        post = create_post(
            views=None,
            comments=None,
            shares=None
        )
        
        serializer = PostSerializer(post)
        data = serializer.data
        
        assert data['views'] is None
        assert data['comments'] is None
        assert data['shares'] is None

    def test_serialize_multiple_posts(self, create_multiple_posts):
        """Test serializing multiple posts."""
        posts = create_multiple_posts(count=5)
        
        serializer = PostSerializer(posts, many=True)
        data = serializer.data
        
        assert len(data) == 5
        assert all('post_id' in post for post in data)
        assert all('title' in post for post in data)

    def test_post_serializer_read_only_fields(self, sample_post_data):
        """Test that certain fields are read-only."""
        serializer = PostSerializer(data=sample_post_data)
        
        # PostSerializer should be read-only for API responses
        # ImportPostSerializer handles creation
        assert serializer.fields['post_id'].read_only
        assert serializer.fields['date'].read_only


@pytest.mark.django_db
@pytest.mark.unit
class TestPostImportSerializer:
    """Test PostImportSerializer functionality."""

    def test_deserialize_valid_post_data(self, sample_post_data):
        """Test deserializing valid post data."""
        serializer = PostImportSerializer(data=sample_post_data)
        
        assert serializer.is_valid()
        assert serializer.validated_data['id'] == '1234567890123456789'
        assert serializer.validated_data['title'] == 'Test TikTok Post #fyp #viral'
        assert serializer.validated_data['likes'] == 1000

    def test_create_post_from_serializer(self, sample_post_data):
        """Test creating a post from serializer."""
        serializer = PostImportSerializer(data=sample_post_data)
        
        assert serializer.is_valid()
        post = serializer.save()
        
        assert post.post_id == '1234567890123456789'
        assert post.title == 'Test TikTok Post #fyp #viral'
        assert post.likes == 1000
        assert post.views == 50000

    def test_required_fields_validation(self):
        """Test that required fields are validated."""
        incomplete_data = {
            'id': '1234567890123456789',
            'title': 'Test'
            # Missing likes, date, cover_url, video_link
        }
        
        serializer = PostImportSerializer(data=incomplete_data)
        
        assert not serializer.is_valid()
        assert 'likes' in serializer.errors
        assert 'date' in serializer.errors
        assert 'cover_url' in serializer.errors
        assert 'video_link' in serializer.errors

    def test_invalid_likes_value(self):
        """Test validation of invalid likes value."""
        invalid_data = {
            'id': '1234567890123456789',
            'title': 'Test',
            'likes': -100,  # Invalid
            'date': '2024-01-15T10:30:00Z',
            'cover_url': 'https://example.com/cover.jpg',
            'video_link': 'https://tiktok.com/@user/video/123'
        }
        
        serializer = PostImportSerializer(data=invalid_data)
        
        assert not serializer.is_valid()
        assert 'likes' in serializer.errors

    def test_invalid_date_format(self):
        """Test validation of invalid date format."""
        invalid_data = {
            'id': '1234567890123456789',
            'title': 'Test',
            'likes': 100,
            'date': 'not-a-valid-date',  # Invalid
            'cover_url': 'https://example.com/cover.jpg',
            'video_link': 'https://tiktok.com/@user/video/123'
        }
        
        serializer = PostImportSerializer(data=invalid_data)
        
        assert not serializer.is_valid()
        assert 'date' in serializer.errors

    def test_invalid_url_format(self):
        """Test validation of invalid URL format."""
        invalid_data = {
            'id': '1234567890123456789',
            'title': 'Test',
            'likes': 100,
            'date': '2024-01-15T10:30:00Z',
            'cover_url': 'not-a-valid-url',  # Invalid
            'video_link': 'https://tiktok.com/@user/video/123'
        }
        
        serializer = PostImportSerializer(data=invalid_data)
        
        assert not serializer.is_valid()
        assert 'cover_url' in serializer.errors

    def test_optional_fields(self, sample_post_data):
        """Test that optional fields are handled correctly."""
        minimal_data = {
            'id': sample_post_data['id'],
            'title': sample_post_data['title'],
            'likes': sample_post_data['likes'],
            'date': sample_post_data['date'],
            'cover_url': sample_post_data['cover_url'],
            'video_link': sample_post_data['video_link']
        }
        
        serializer = PostImportSerializer(data=minimal_data)
        
        assert serializer.is_valid()
        post = serializer.save()
        
        assert post.views is None
        assert post.comments is None
        assert post.shares is None

    def test_bulk_import_posts(self, sample_post_data):
        """Test importing multiple posts."""
        posts_data = [
            sample_post_data,
            {
                **sample_post_data,
                'id': '9876543210987654321',
                'title': 'Another Post'
            },
            {
                **sample_post_data,
                'id': '1111111111111111111',
                'title': 'Third Post'
            }
        ]
        
        for post_data in posts_data:
            serializer = PostImportSerializer(data=post_data)
            assert serializer.is_valid()
            serializer.save()
        
        assert Post.objects.count() == 3

    def test_duplicate_post_id(self, sample_post_data):
        """Test that duplicate post_id is handled."""
        # Create first post
        serializer1 = PostImportSerializer(data=sample_post_data)
        assert serializer1.is_valid()
        serializer1.save()
        
        # Try to create duplicate
        serializer2 = PostImportSerializer(data=sample_post_data)
        assert serializer2.is_valid()
        
        # PostImportSerializer uses update_or_create, so duplicate should update
        assert serializer2.is_valid()
        post2 = serializer2.save()
        
        # Should still have only 1 post (updated)
        assert Post.objects.count() == 1
