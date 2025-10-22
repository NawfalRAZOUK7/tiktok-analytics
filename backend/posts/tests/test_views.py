"""
Integration tests for Post API views and endpoints.
"""

import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from posts.models import Post
from django.contrib.auth.models import User


@pytest.mark.django_db
@pytest.mark.integration
class TestPostListView:
    """Test POST list API endpoint."""

    def test_list_posts_empty(self, api_client):
        """Test listing posts when database is empty."""
        url = reverse('post-list')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['count'] == 0
        assert response.data['results'] == []

    def test_list_posts(self, api_client, create_multiple_posts):
        """Test listing posts."""
        create_multiple_posts(count=10)
        
        url = reverse('post-list')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['count'] == 10
        assert len(response.data['results']) == 10

    def test_list_posts_pagination(self, api_client, create_multiple_posts):
        """Test pagination of post list."""
        create_multiple_posts(count=25)
        
        url = reverse('post-list')
        response = api_client.get(url, {'page': 1})
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['count'] == 25
        # Default page size is usually 10 or 20
        assert len(response.data['results']) <= 20

    def test_list_posts_ordering(self, api_client, create_multiple_posts):
        """Test posts are ordered by date (newest first)."""
        posts = create_multiple_posts(count=5)
        
        url = reverse('post-list')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        results = response.data['results']
        
        # Verify ordering by checking post_ids (decreasing)
        post_ids = [result['post_id'] for result in results]
        assert post_ids == sorted(post_ids, reverse=True)

    def test_filter_posts_by_likes(self, api_client, create_multiple_posts):
        """Test filtering posts by minimum likes."""
        create_multiple_posts(count=10)
        
        url = reverse('post-list')
        response = api_client.get(url, {'min_likes': 500})
        
        assert response.status_code == status.HTTP_200_OK
        results = response.data['results']
        
        # Posts with likes >= 500 (posts 5-10)
        assert len(results) == 5
        assert all(post['likes'] >= 500 for post in results)

    def test_filter_posts_by_date_range(self, api_client, create_post):
        """Test filtering posts by date range."""
        from datetime import datetime, timedelta
        
        today = datetime.now()
        yesterday = today - timedelta(days=1)
        tomorrow = today + timedelta(days=1)
        
        # Create posts with different dates
        create_post(post_id='111', date=yesterday)
        create_post(post_id='222', date=today)
        create_post(post_id='333', date=tomorrow)
        
        url = reverse('post-list')
        response = api_client.get(url, {
            'start_date': today.strftime('%Y-%m-%d'),
            'end_date': tomorrow.strftime('%Y-%m-%d')
        })
        
        assert response.status_code == status.HTTP_200_OK
        results = response.data['results']
        
        # Should return posts from today and tomorrow
        assert len(results) == 2

    def test_search_posts_by_title(self, api_client, create_post):
        """Test searching posts by title."""
        create_post(post_id='111', title='Python Django Tutorial')
        create_post(post_id='222', title='React Frontend Guide')
        create_post(post_id='333', title='Django REST Framework')
        
        url = reverse('post-list')
        response = api_client.get(url, {'search': 'django'})
        
        assert response.status_code == status.HTTP_200_OK
        results = response.data['results']
        
        assert len(results) == 2
        assert all('django' in post['title'].lower() for post in results)


@pytest.mark.django_db
@pytest.mark.integration
class TestPostDetailView:
    """Test Post detail API endpoint."""

    def test_retrieve_post(self, api_client, create_post):
        """Test retrieving a single post."""
        post = create_post(
            post_id='1234567890123456789',
            title='Test Post',
            likes=1000
        )
        
        url = reverse('post-detail', kwargs={'pk': post.pk})
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['post_id'] == '1234567890123456789'
        assert response.data['title'] == 'Test Post'
        assert response.data['likes'] == 1000

    def test_retrieve_nonexistent_post(self, api_client):
        """Test retrieving a post that doesn't exist."""
        url = reverse('post-detail', kwargs={'pk': 99999})
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.django_db
@pytest.mark.integration
class TestPostCreateView:
    """Test Post creation API endpoint."""

    def test_create_post_requires_authentication(self, api_client, sample_post_data):
        """Test that creating a post requires authentication."""
        url = reverse('post-list')
        response = api_client.post(url, sample_post_data, format='json')
        
        # Should require authentication
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]

    def test_create_post_authenticated(self, authenticated_client, sample_post_data):
        """Test creating a post with authentication."""
        url = reverse('post-list')
        response = authenticated_client.post(url, sample_post_data, format='json')
        
        assert response.status_code == status.HTTP_201_CREATED
        assert Post.objects.count() == 1
        
        post = Post.objects.first()
        assert post.post_id == sample_post_data['id']
        assert post.title == sample_post_data['title']

    def test_create_post_invalid_data(self, authenticated_client):
        """Test creating a post with invalid data."""
        invalid_data = {
            'id': '123',
            'title': 'Test'
            # Missing required fields
        }
        
        url = reverse('post-list')
        response = authenticated_client.post(url, invalid_data, format='json')
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert Post.objects.count() == 0


@pytest.mark.django_db
@pytest.mark.integration
class TestPostUpdateView:
    """Test Post update API endpoint."""

    def test_update_post_requires_authentication(self, api_client, create_post):
        """Test that updating a post requires authentication."""
        post = create_post()
        
        url = reverse('post-detail', kwargs={'pk': post.pk})
        response = api_client.patch(url, {'likes': 2000}, format='json')
        
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]

    def test_update_post_authenticated(self, authenticated_client, create_post):
        """Test updating a post with authentication."""
        post = create_post(likes=1000)
        
        url = reverse('post-detail', kwargs={'pk': post.pk})
        response = authenticated_client.patch(url, {'likes': 2000}, format='json')
        
        assert response.status_code == status.HTTP_200_OK
        
        post.refresh_from_db()
        assert post.likes == 2000

    def test_full_update_post(self, authenticated_client, create_post, sample_post_data):
        """Test full update (PUT) of a post."""
        post = create_post()
        
        url = reverse('post-detail', kwargs={'pk': post.pk})
        response = authenticated_client.put(url, sample_post_data, format='json')
        
        assert response.status_code == status.HTTP_200_OK
        
        post.refresh_from_db()
        assert post.title == sample_post_data['title']
        assert post.likes == sample_post_data['likes']


@pytest.mark.django_db
@pytest.mark.integration
class TestPostDeleteView:
    """Test Post deletion API endpoint."""

    def test_delete_post_requires_authentication(self, api_client, create_post):
        """Test that deleting a post requires authentication."""
        post = create_post()
        
        url = reverse('post-detail', kwargs={'pk': post.pk})
        response = api_client.delete(url)
        
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]

    def test_delete_post_authenticated(self, authenticated_client, create_post):
        """Test deleting a post with authentication."""
        post = create_post()
        post_id = post.pk
        
        url = reverse('post-detail', kwargs={'pk': post_id})
        response = authenticated_client.delete(url)
        
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not Post.objects.filter(pk=post_id).exists()

    def test_delete_nonexistent_post(self, authenticated_client):
        """Test deleting a post that doesn't exist."""
        url = reverse('post-detail', kwargs={'pk': 99999})
        response = authenticated_client.delete(url)
        
        assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.django_db
@pytest.mark.integration
class TestPostImportView:
    """Test Post bulk import API endpoint."""

    def test_import_posts_requires_authentication(self, api_client):
        """Test that importing posts requires authentication."""
        url = reverse('post-import')
        response = api_client.post(url, {'posts': []}, format='json')
        
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]

    def test_import_posts_authenticated(self, authenticated_client, sample_post_data):
        """Test importing multiple posts with authentication."""
        posts_data = [
            sample_post_data,
            {
                **sample_post_data,
                'id': '9876543210987654321',
                'title': 'Second Post'
            }
        ]
        
        url = reverse('post-import')
        response = authenticated_client.post(url, {'posts': posts_data}, format='json')
        
        assert response.status_code == status.HTTP_201_CREATED
        assert Post.objects.count() == 2
        assert 'created' in response.data
        assert response.data['created'] == 2

    def test_import_posts_with_duplicates(self, authenticated_client, sample_post_data, create_post):
        """Test importing posts with duplicate handling."""
        # Create existing post
        create_post(post_id=sample_post_data['id'])
        
        posts_data = [
            sample_post_data,  # Duplicate
            {
                **sample_post_data,
                'id': '9876543210987654321',
                'title': 'New Post'
            }
        ]
        
        url = reverse('post-import')
        response = authenticated_client.post(url, {'posts': posts_data}, format='json')
        
        assert response.status_code == status.HTTP_201_CREATED
        # Should only create 1 new post (skipping duplicate)
        assert Post.objects.count() == 2

    def test_import_posts_invalid_data(self, authenticated_client):
        """Test importing posts with invalid data."""
        invalid_data = {
            'posts': [
                {'id': '123'}  # Missing required fields
            ]
        }
        
        url = reverse('post-import')
        response = authenticated_client.post(url, invalid_data, format='json')
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert Post.objects.count() == 0


@pytest.mark.django_db
@pytest.mark.integration
class TestPostStatisticsView:
    """Test Post statistics API endpoint."""

    def test_statistics_empty(self, api_client):
        """Test statistics when no posts exist."""
        url = reverse('post-statistics')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['total_posts'] == 0

    def test_statistics_with_posts(self, api_client, create_multiple_posts):
        """Test statistics with actual posts."""
        create_multiple_posts(count=10)
        
        url = reverse('post-statistics')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['total_posts'] == 10
        assert response.data['total_likes'] == 5500  # Sum of 100, 200, ..., 1000
        assert 'avg_likes' in response.data
        assert 'avg_views' in response.data


@pytest.mark.django_db
@pytest.mark.integration
class TestPostInsightsView:
    """Test Post insights API endpoint."""

    def test_insights_empty(self, api_client):
        """Test insights when no posts exist."""
        url = reverse('post-insights')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert 'trends' in response.data
        assert 'top_posts' in response.data
        assert 'popular_keywords' in response.data

    def test_insights_with_posts(self, api_client, create_multiple_posts):
        """Test insights with actual posts."""
        create_multiple_posts(count=10)
        
        url = reverse('post-insights')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        
        # Check trends
        assert 'trends' in response.data
        assert len(response.data['trends']) > 0
        
        # Check top posts
        assert 'top_posts' in response.data
        assert len(response.data['top_posts']) > 0

    def test_insights_top_posts_ordering(self, api_client, create_post):
        """Test that top posts are ordered by engagement."""
        create_post(post_id='111', likes=100, views=1000)
        create_post(post_id='222', likes=500, views=5000)
        create_post(post_id='333', likes=1000, views=10000)
        
        url = reverse('post-insights')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        
        top_posts = response.data['top_posts']
        
        # Verify posts are ordered by engagement (highest first)
        if len(top_posts) >= 2:
            likes_1 = top_posts[0]['likes']
            likes_2 = top_posts[1]['likes']
            assert likes_1 >= likes_2


@pytest.mark.django_db
@pytest.mark.integration
class TestPostPermissions:
    """Test API endpoint permissions."""

    def test_read_permissions(self, api_client, create_post):
        """Test that reading posts doesn't require authentication."""
        create_post()
        
        # List view
        url = reverse('post-list')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        
        # Detail view
        post = Post.objects.first()
        url = reverse('post-detail', kwargs={'pk': post.pk})
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        
        # Statistics
        url = reverse('post-statistics')
        response = api_client.get(url)
        assert response.status_code == status.HTTP_200_OK

    def test_write_permissions(self, api_client, sample_post_data):
        """Test that write operations require authentication."""
        # Create
        url = reverse('post-list')
        response = api_client.post(url, sample_post_data, format='json')
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]
        
        # Import
        url = reverse('post-import')
        response = api_client.post(url, {'posts': [sample_post_data]}, format='json')
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]
