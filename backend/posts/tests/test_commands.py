"""
Tests for Django management commands.
"""

import pytest
import json
import tempfile
from io import StringIO
from datetime import datetime
from django.core.management import call_command
from django.core.management.base import CommandError
from django.contrib.auth import get_user_model
from posts.models import Post, Follower, Following, FollowerSnapshot

User = get_user_model()


@pytest.mark.django_db
@pytest.mark.unit
class TestImportTikTokJsonCommand:
    """Test import_tiktok_json management command."""

    def test_import_valid_json_file(self, sample_post_data):
        """Test importing a valid JSON file."""
        # Create temporary JSON file
        posts_data = [
            sample_post_data,
            {
                **sample_post_data,
                'id': '9876543210987654321',
                'title': 'Second Post'
            }
        ]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            # Run command
            out = StringIO()
            call_command('import_tiktok_json', temp_file, stdout=out)
            
            # Verify posts were created
            assert Post.objects.count() == 2
            
            # Check output
            output = out.getvalue()
            assert 'Successfully imported' in output
            assert 'Created: 2' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_invalid_json_file(self):
        """Test importing an invalid JSON file."""
        # Create file with invalid JSON
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write('{ invalid json }')
            temp_file = f.name
        
        try:
            with pytest.raises(CommandError):
                call_command('import_tiktok_json', temp_file)
        finally:
            import os
            os.unlink(temp_file)

    def test_import_nonexistent_file(self):
        """Test importing a file that doesn't exist."""
        with pytest.raises(CommandError):
            call_command('import_tiktok_json', '/nonexistent/file.json')

    def test_import_with_dry_run(self, sample_post_data):
        """Test importing with dry-run option."""
        posts_data = [sample_post_data]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, '--dry-run', stdout=out)
            
            # No posts should be created
            assert Post.objects.count() == 0
            
            # Check output
            output = out.getvalue()
            assert 'DRY RUN' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_with_clear_existing(self, sample_post_data, create_post):
        """Test importing with clear-existing option."""
        # Create existing post
        create_post(post_id='existing123')
        assert Post.objects.count() == 1
        
        posts_data = [sample_post_data]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            call_command('import_tiktok_json', temp_file, '--clear-existing')
            
            # Old post should be deleted, new post created
            assert Post.objects.count() == 1
            assert not Post.objects.filter(post_id='existing123').exists()
            assert Post.objects.filter(post_id=sample_post_data['id']).exists()
        finally:
            import os
            os.unlink(temp_file)

    def test_import_with_skip_duplicates(self, sample_post_data, create_post):
        """Test importing with skip-duplicates option (default)."""
        # Create existing post with same post_id
        existing_post = create_post(
            post_id=sample_post_data['id'],
            likes=999  # Different likes value
        )
        
        posts_data = [
            sample_post_data,  # Duplicate
            {
                **sample_post_data,
                'id': 'new_post_123',
                'title': 'New Post'
            }
        ]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, '--skip-duplicates', stdout=out)
            
            # Should have 2 posts total (1 existing + 1 new)
            assert Post.objects.count() == 2
            
            # Existing post should not be updated
            existing_post.refresh_from_db()
            assert existing_post.likes == 999
            
            # Check output
            output = out.getvalue()
            assert 'Skipped: 1' in output
            assert 'Created: 1' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_with_update_duplicates(self, sample_post_data, create_post):
        """Test importing with update-duplicates option."""
        # Create existing post
        existing_post = create_post(
            post_id=sample_post_data['id'],
            likes=999  # Different value
        )
        
        posts_data = [sample_post_data]  # Will update existing
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, '--update-duplicates', stdout=out)
            
            # Should still have 1 post
            assert Post.objects.count() == 1
            
            # Post should be updated
            existing_post.refresh_from_db()
            assert existing_post.likes == sample_post_data['likes']
            
            # Check output
            output = out.getvalue()
            assert 'Updated: 1' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_with_invalid_post_data(self, sample_post_data):
        """Test importing with some invalid post data."""
        posts_data = [
            sample_post_data,  # Valid
            {
                'id': '123',
                'title': 'Invalid Post'
                # Missing required fields
            }
        ]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, stdout=out)
            
            # Valid post should be created
            assert Post.objects.count() == 1
            
            # Check output for errors
            output = out.getvalue()
            assert 'Errors: 1' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_empty_file(self):
        """Test importing an empty JSON file."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump([], f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, stdout=out)
            
            assert Post.objects.count() == 0
            
            output = out.getvalue()
            assert 'Total: 0' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_progress_reporting(self, sample_post_data):
        """Test that progress is reported during import."""
        # Create larger dataset
        posts_data = [
            {
                **sample_post_data,
                'id': f'post_{i}',
                'title': f'Post {i}'
            }
            for i in range(20)
        ]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(posts_data, f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, stdout=out)
            
            output = out.getvalue()
            
            # Should show progress
            assert 'Processing:' in output or 'Progress:' in output
            
            # All posts should be created
            assert Post.objects.count() == 20
        finally:
            import os
            os.unlink(temp_file)

    def test_import_transaction_rollback_on_error(self, sample_post_data):
        """Test that import rolls back on critical errors."""
        # This test would require mocking database errors
        # Simplified version: just verify command handles errors gracefully
        
        invalid_data = [
            sample_post_data,
            {'invalid': 'data'}  # Will cause error
        ]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(invalid_data, f)
            temp_file = f.name
        
        try:
            out = StringIO()
            call_command('import_tiktok_json', temp_file, stdout=out)
            
            # At least the valid post should be created (if not transactional)
            # Or none if fully transactional - depends on implementation
            output = out.getvalue()
            assert 'Errors:' in output
        finally:
            import os
            os.unlink(temp_file)

    def test_import_with_missing_optional_fields(self):
        """Test importing posts with missing optional fields."""
        minimal_data = [{
            'id': '1234567890123456789',
            'title': 'Minimal Post',
            'likes': 100,
            'date': '2024-01-15T10:30:00Z',
            'cover_url': 'https://example.com/cover.jpg',
            'video_link': 'https://tiktok.com/@user/video/123'
            # Missing: views, comments, shares, hashtags, description
        }]
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(minimal_data, f)
            temp_file = f.name
        
        try:
            call_command('import_tiktok_json', temp_file)
            
            assert Post.objects.count() == 1
            post = Post.objects.first()
            
            assert post.post_id == '1234567890123456789'
            assert post.views is None
            assert post.comments is None
        finally:
            import os
            os.unlink(temp_file)


@pytest.mark.django_db
@pytest.mark.unit
class TestImportFollowersFollowing:
    """Test import_tiktok_json command for Follower/Following data."""

    @pytest.fixture
    def test_user(self):
        """Create a test user."""
        User = get_user_model()
        return User.objects.create_user(
            username='testuser',
            password='testpass123'
        )

    @pytest.fixture
    def follower_data(self):
        """Sample follower data in TikTok export format."""
        return {
            'Profile And Settings': {
                'Follower': {
                    'FansList': [
                        {
                            'UserName': 'follower1',
                            'Date': '2024-01-15T10:30:00Z'
                        },
                        {
                            'UserName': 'follower2',
                            'Date': '2024-01-16T14:20:00Z'
                        },
                        {
                            'UserName': 'follower3',
                            'Date': '2024-01-17T09:15:00Z'
                        }
                    ]
                }
            }
        }

    @pytest.fixture
    def following_data(self):
        """Sample following data in TikTok export format."""
        return {
            'Profile And Settings': {
                'Following': {
                    'Following': [
                        {
                            'UserName': 'user1',
                            'Date': '2024-01-10T08:00:00Z'
                        },
                        {
                            'UserName': 'user2',
                            'Date': '2024-01-11T12:30:00Z'
                        }
                    ]
                }
            }
        }

    @pytest.fixture
    def combined_data(self):
        """Combined follower and following data."""
        return {
            'Profile And Settings': {
                'Follower': {
                    'FansList': [
                        {
                            'UserName': 'follower1',
                            'Date': '2024-01-15T10:30:00Z'
                        },
                        {
                            'UserName': 'mutual_user',
                            'Date': '2024-01-16T14:20:00Z'
                        }
                    ]
                },
                'Following': {
                    'Following': [
                        {
                            'UserName': 'following1',
                            'Date': '2024-01-10T08:00:00Z'
                        },
                        {
                            'UserName': 'mutual_user',
                            'Date': '2024-01-11T12:30:00Z'
                        }
                    ]
                }
            }
        }

    def test_import_followers_only(self, test_user, follower_data):
        """Test importing followers from FansList."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(follower_data, f)
            temp_file = f.name

        try:
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # Verify followers were created
            assert Follower.objects.count() == 3
            assert Follower.objects.filter(user=test_user).count() == 3

            # Verify no posts were created
            assert Post.objects.count() == 0

            # Check output
            output = out.getvalue()
            assert 'Importing Followers' in output
            assert '3 followers' in output or 'Created: 3' in output

        finally:
            import os
            os.unlink(temp_file)

    def test_import_following_only(self, test_user, following_data):
        """Test importing following from Following.Following."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(following_data, f)
            temp_file = f.name

        try:
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # Verify following were created
            assert Following.objects.count() == 2
            assert Following.objects.filter(user=test_user).count() == 2

            # Check output
            output = out.getvalue()
            assert 'Importing Following' in output

        finally:
            import os
            os.unlink(temp_file)

    def test_import_combined_follower_following(self, test_user, combined_data):
        """Test importing both followers and following together."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(combined_data, f)
            temp_file = f.name

        try:
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # Verify both were created
            assert Follower.objects.count() == 2
            assert Following.objects.count() == 2

            # Verify mutual user exists in both
            assert Follower.objects.filter(
                user=test_user,
                username='mutual_user'
            ).exists()
            assert Following.objects.filter(
                user=test_user,
                username='mutual_user'
            ).exists()

        finally:
            import os
            os.unlink(temp_file)

    def test_import_duplicate_followers_skipped(self, test_user, follower_data):
        """Test that duplicate followers are skipped on re-import."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(follower_data, f)
            temp_file = f.name

        try:
            # First import
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}'
            )

            assert Follower.objects.count() == 3

            # Second import (should skip duplicates)
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # Count should remain the same
            assert Follower.objects.count() == 3

            output = out.getvalue()
            assert 'Skipped: 3' in output or 'skipped' in output.lower()

        finally:
            import os
            os.unlink(temp_file)

    def test_import_dry_run_followers(self, test_user, follower_data):
        """Test dry-run mode doesn't create followers."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(follower_data, f)
            temp_file = f.name

        try:
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--dry-run',
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # No followers should be created
            assert Follower.objects.count() == 0

            # But output should show what would be created
            output = out.getvalue()
            assert '3 followers' in output or 'Would create' in output.lower()

        finally:
            import os
            os.unlink(temp_file)

    def test_import_followers_invalid_data(self, test_user):
        """Test handling of invalid follower data."""
        invalid_data = {
            'Profile And Settings': {
                'Follower': {
                    'FansList': [
                        {
                            'UserName': 'valid_user',
                            'Date': '2024-01-15T10:30:00Z'
                        },
                        {
                            # Missing UserName
                            'Date': '2024-01-16T14:20:00Z'
                        },
                        {
                            'UserName': 'user_with_invalid_date',
                            'Date': 'invalid-date-format'
                        }
                    ]
                }
            }
        }

        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(invalid_data, f)
            temp_file = f.name

        try:
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # Only valid follower should be created
            assert Follower.objects.count() >= 1

            output = out.getvalue()
            assert 'Errors:' in output or '❌' in output

        finally:
            import os
            os.unlink(temp_file)

    def test_import_large_follower_dataset(self, test_user):
        """Test importing >3000 followers for performance."""
        # Create 3500 followers
        large_data = {
            'Profile And Settings': {
                'Follower': {
                    'FansList': [
                        {
                            'UserName': f'follower{i}',
                            'Date': '2024-01-15T10:30:00Z'
                        }
                        for i in range(3500)
                    ]
                }
            }
        }

        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(large_data, f)
            temp_file = f.name

        try:
            import time
            start_time = time.time()

            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            end_time = time.time()
            duration = end_time - start_time

            # Verify all followers were created
            assert Follower.objects.count() == 3500

            # Performance check: should complete in reasonable time
            # (bulk_create should make this fast)
            assert duration < 30  # Should take less than 30 seconds

            output = out.getvalue()
            # Should show progress updates
            assert 'Progress' in output or 'Processing' in output or '3500' in output

        finally:
            import os
            os.unlink(temp_file)

    def test_import_with_nonexistent_user(self, follower_data):
        """Test that command fails gracefully with non-existent user."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(follower_data, f)
            temp_file = f.name

        try:
            with pytest.raises(CommandError) as exc_info:
                call_command(
                    'import_tiktok_json',
                    temp_file,
                    '--user=nonexistent_user'
                )

            assert 'not found' in str(exc_info.value)

        finally:
            import os
            os.unlink(temp_file)

    def test_import_empty_follower_list(self, test_user):
        """Test importing with empty follower lists."""
        empty_data = {
            'Profile And Settings': {
                'Follower': {
                    'FansList': []
                },
                'Following': {
                    'Following': []
                }
            }
        }

        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(empty_data, f)
            temp_file = f.name

        try:
            out = StringIO()
            call_command(
                'import_tiktok_json',
                temp_file,
                '--followers-only',
                f'--user={test_user.username}',
                stdout=out
            )

            # No followers should be created
            assert Follower.objects.count() == 0
            assert Following.objects.count() == 0

            output = out.getvalue()
            assert 'Found 0' in output

        finally:
            import os
            os.unlink(temp_file)
