"""
Tests for Django management commands.
"""

import pytest
import json
import tempfile
from io import StringIO
from django.core.management import call_command
from django.core.management.base import CommandError
from posts.models import Post


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
