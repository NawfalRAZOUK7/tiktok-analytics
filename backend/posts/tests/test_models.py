"""
Unit tests for Post model.
"""

import pytest
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.utils import timezone
from datetime import timedelta
from posts.models import Post


@pytest.mark.django_db
@pytest.mark.unit
class TestPostModel:
    """Test Post model functionality."""

    def test_create_post_with_required_fields(self, create_post):
        """Test creating a post with only required fields."""
        post = create_post(
            post_id='1234567890123456789',
            title='Test Post',
            likes=100,
            date=timezone.now(),
            cover_url='https://example.com/cover.jpg',
            video_link='https://tiktok.com/@user/video/123'
        )
        
        assert post.post_id == '1234567890123456789'
        assert post.title == 'Test Post'
        assert post.likes == 100
        assert post.cover_url == 'https://example.com/cover.jpg'
        assert post.video_link == 'https://tiktok.com/@user/video/123'
        assert post.views is None
        assert post.comments is None
        assert post.shares is None

    def test_create_post_with_all_fields(self, create_post):
        """Test creating a post with all fields populated."""
        post = create_post(
            post_id='1234567890123456789',
            title='Complete Post',
            likes=1000,
            date=timezone.now(),
            cover_url='https://example.com/cover.jpg',
            video_link='https://tiktok.com/@user/video/123',
            views=50000,
            comments=200,
            shares=50,
            bookmarks=30,
            duration=45,
            hashtags=['fyp', 'viral'],
            music='Song Name - Artist',
            location='Los Angeles, CA'
        )
        
        assert post.views == 50000
        assert post.comments == 200
        assert post.shares == 50
        assert post.bookmarks == 30
        assert post.duration == 45
        assert post.hashtags == ['fyp', 'viral']
        assert post.music == 'Song Name - Artist'
        assert post.location == 'Los Angeles, CA'

    def test_post_id_must_be_unique(self, create_post):
        """Test that post_id must be unique."""
        create_post(post_id='1234567890123456789')
        
        with pytest.raises(IntegrityError):
            create_post(post_id='1234567890123456789')

    def test_likes_cannot_be_negative(self, create_post):
        """Test that likes cannot be negative."""
        with pytest.raises(ValidationError):
            post = Post(
                post_id='1234567890123456789',
                title='Test',
                likes=-10,  # Invalid
                date=timezone.now(),
                cover_url='https://example.com/cover.jpg',
                video_link='https://tiktok.com/@user/video/123'
            )
            post.full_clean()

    def test_views_cannot_be_negative(self, create_post):
        """Test that views cannot be negative."""
        with pytest.raises(ValidationError):
            post = Post(
                post_id='1234567890123456789',
                title='Test',
                likes=100,
                views=-100,  # Invalid
                date=timezone.now(),
                cover_url='https://example.com/cover.jpg',
                video_link='https://tiktok.com/@user/video/123'
            )
            post.full_clean()

    def test_str_representation(self, create_post):
        """Test string representation of Post."""
        post = create_post(
            post_id='1234567890123456789',
            title='My TikTok Video'
        )
        
        assert str(post) == 'My TikTok Video (1234567890123456789)'

    def test_engagement_rate_property(self, create_post):
        """Test engagement_rate calculated property."""
        post = create_post(
            likes=1000,
            views=10000
        )
        
        assert post.engagement_rate == 0.1  # 1000/10000 = 10%

    def test_engagement_rate_with_zero_views(self, create_post):
        """Test engagement_rate when views is zero."""
        post = create_post(
            likes=1000,
            views=0
        )
        
        assert post.engagement_rate == 0.0

    def test_engagement_rate_with_null_views(self, create_post):
        """Test engagement_rate when views is null."""
        post = create_post(
            likes=1000,
            views=None
        )
        
        assert post.engagement_rate == 0.0

    def test_days_since_posted_property(self, create_post):
        """Test days_since_posted calculated property."""
        past_date = timezone.now() - timedelta(days=10)
        post = create_post(date=past_date)
        
        assert post.days_since_posted == 10

    def test_post_ordering(self, create_multiple_posts):
        """Test that posts are ordered by date (newest first)."""
        posts = create_multiple_posts(count=5)
        
        all_posts = Post.objects.all()
        
        # Should be ordered newest first
        assert all_posts[0].date > all_posts[1].date
        assert all_posts[1].date > all_posts[2].date

    def test_post_queryset_count(self, create_multiple_posts):
        """Test counting posts."""
        create_multiple_posts(count=10)
        
        assert Post.objects.count() == 10

    def test_filter_posts_by_likes(self, create_multiple_posts):
        """Test filtering posts by likes."""
        create_multiple_posts(count=10)
        
        high_likes_posts = Post.objects.filter(likes__gte=500)
        
        assert high_likes_posts.count() == 5  # Posts 5-10 have >= 500 likes

    def test_filter_posts_by_date_range(self, create_multiple_posts):
        """Test filtering posts by date range."""
        posts = create_multiple_posts(count=10)
        
        start_date = posts[2].date
        end_date = posts[7].date
        
        filtered_posts = Post.objects.filter(
            date__gte=start_date,
            date__lte=end_date
        )
        
        assert filtered_posts.count() == 6  # Posts 2-7 (inclusive)

    def test_search_posts_by_title(self, create_post):
        """Test searching posts by title."""
        create_post(title='My #fyp TikTok video', post_id='111')
        create_post(title='Another post', post_id='222')
        create_post(title='FYP content here', post_id='333')
        
        results = Post.objects.filter(title__icontains='fyp')
        
        assert results.count() == 2

    def test_hashtags_field(self, create_post):
        """Test hashtags array field."""
        post = create_post(
            hashtags=['fyp', 'viral', 'trending', 'music']
        )
        
        assert len(post.hashtags) == 4
        assert 'fyp' in post.hashtags
        assert 'viral' in post.hashtags

    def test_empty_hashtags(self, create_post):
        """Test post with empty hashtags."""
        post = create_post(hashtags=[])
        
        assert post.hashtags == []

    def test_null_optional_fields(self, create_post):
        """Test that optional fields can be null."""
        post = create_post(
            views=None,
            comments=None,
            shares=None,
            bookmarks=None,
            duration=None,
            music=None,
            location=None
        )
        
        assert post.views is None
        assert post.comments is None
        assert post.shares is None
        assert post.bookmarks is None
        assert post.duration is None
        assert post.music is None
        assert post.location is None

    def test_update_post_fields(self, create_post):
        """Test updating post fields."""
        post = create_post(likes=100, views=1000)
        
        post.likes = 500
        post.views = 5000
        post.save()
        
        updated_post = Post.objects.get(pk=post.pk)
        assert updated_post.likes == 500
        assert updated_post.views == 5000

    def test_delete_post(self, create_post):
        """Test deleting a post."""
        post = create_post()
        post_id = post.pk
        
        post.delete()
        
        assert not Post.objects.filter(pk=post_id).exists()

    def test_bulk_create_posts(self):
        """Test bulk creating multiple posts."""
        posts_data = [
            Post(
                post_id=f'123456789012345678{i}',
                title=f'Post {i}',
                likes=i * 100,
                date=timezone.now(),
                cover_url=f'https://example.com/cover{i}.jpg',
                video_link=f'https://tiktok.com/@user/video/{i}'
            )
            for i in range(5)
        ]
        
        Post.objects.bulk_create(posts_data)
        
        assert Post.objects.count() == 5
