"""
Django management command to import TikTok data from JSON file.

Usage:
    python manage.py import_tiktok_json path/to/export.json
    python manage.py import_tiktok_json path/to/export.json --dry-run
    python manage.py import_tiktok_json path/to/export.json --clear-existing
    python manage.py import_tiktok_json path/to/export.json --posts-only
    python manage.py import_tiktok_json path/to/export.json --followers-only
"""

import json
import os
from datetime import datetime
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils.dateparse import parse_datetime
from django.contrib.auth import get_user_model
from posts.models import Post, Follower, Following, FollowerSnapshot

User = get_user_model()


class Command(BaseCommand):
    help = 'Import TikTok data (posts, followers, following) from a JSON export file'

    def add_arguments(self, parser):
        parser.add_argument(
            'json_file',
            type=str,
            help='Path to the TikTok JSON export file'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Validate the file without importing data'
        )
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Delete all existing data before importing'
        )
        parser.add_argument(
            '--skip-duplicates',
            action='store_true',
            default=True,
            help='Skip items that already exist (default: True)'
        )
        parser.add_argument(
            '--update-duplicates',
            action='store_true',
            help='Update existing items instead of skipping them'
        )
        parser.add_argument(
            '--posts-only',
            action='store_true',
            help='Import only posts (skip followers/following)'
        )
        parser.add_argument(
            '--followers-only',
            action='store_true',
            help='Import only followers and following (skip posts)'
        )
        parser.add_argument(
            '--user',
            type=str,
            help='Username to associate the data with (default: admin)'
        )

    def handle(self, *args, **options):
        json_file = options['json_file']
        dry_run = options['dry_run']
        clear_existing = options['clear_existing']
        skip_duplicates = options['skip_duplicates']
        update_duplicates = options['update_duplicates']

        # Validate file exists
        if not os.path.exists(json_file):
            raise CommandError(f'File not found: {json_file}')

        # Read and parse JSON
        self.stdout.write(self.style.MIGRATE_HEADING(f'\n📂 Reading file: {json_file}'))
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise CommandError(f'Invalid JSON file: {e}')
        except Exception as e:
            raise CommandError(f'Error reading file: {e}')

        # Validate data structure
        if not isinstance(data, list):
            raise CommandError('JSON file must contain a list of posts')

        total_posts = len(data)
        self.stdout.write(f'📊 Found {total_posts} posts in file\n')

        # Clear existing posts if requested
        if clear_existing and not dry_run:
            existing_count = Post.objects.count()
            if existing_count > 0:
                self.stdout.write(
                    self.style.WARNING(f'⚠️  Deleting {existing_count} existing posts...')
                )
                Post.objects.all().delete()
                self.stdout.write(self.style.SUCCESS('✅ Existing posts deleted\n'))

        # Process posts
        created_count = 0
        updated_count = 0
        skipped_count = 0
        error_count = 0
        errors = []

        self.stdout.write(self.style.MIGRATE_HEADING('Processing posts...'))

        with transaction.atomic():
            for index, post_data in enumerate(data, 1):
                try:
                    result = self._process_post(
                        post_data,
                        skip_duplicates=skip_duplicates,
                        update_duplicates=update_duplicates,
                        dry_run=dry_run
                    )
                    
                    if result == 'created':
                        created_count += 1
                    elif result == 'updated':
                        updated_count += 1
                    elif result == 'skipped':
                        skipped_count += 1

                    # Progress indicator
                    if index % 100 == 0 or index == total_posts:
                        self._print_progress(index, total_posts)

                except Exception as e:
                    error_count += 1
                    error_msg = f"Post #{index}: {str(e)}"
                    errors.append(error_msg)
                    if error_count <= 5:  # Show first 5 errors
                        self.stdout.write(self.style.ERROR(f'❌ {error_msg}'))

            if dry_run:
                self.stdout.write(
                    self.style.WARNING('\n🔄 DRY RUN - No data was imported (transaction rolled back)')
                )
                raise Exception("Dry run - rolling back transaction")

        # Print summary
        self.stdout.write('\n' + '=' * 70)
        self.stdout.write(self.style.MIGRATE_HEADING('IMPORT SUMMARY'))
        self.stdout.write('=' * 70)
        
        if not dry_run:
            self.stdout.write(f'✅ Created:  {created_count}')
            self.stdout.write(f'🔄 Updated:  {updated_count}')
            self.stdout.write(f'⏭️  Skipped:  {skipped_count}')
        
        if error_count > 0:
            self.stdout.write(self.style.ERROR(f'❌ Errors:   {error_count}'))
            if error_count > 5:
                self.stdout.write(
                    self.style.WARNING(f'   (showing first 5 of {error_count} errors)')
                )
        
        self.stdout.write(f'📊 Total:    {total_posts}')
        self.stdout.write('=' * 70 + '\n')

        if dry_run:
            self.stdout.write(
                self.style.SUCCESS('✅ Validation complete! File is ready to import.')
            )
            self.stdout.write(
                self.style.WARNING('Run without --dry-run to actually import the data.\n')
            )
        elif error_count == 0:
            self.stdout.write(
                self.style.SUCCESS(f'✅ Successfully imported {created_count + updated_count} posts!\n')
            )
        else:
            self.stdout.write(
                self.style.WARNING(
                    f'⚠️  Import completed with {error_count} errors. '
                    f'Check the output above for details.\n'
                )
            )

    def _process_post(self, post_data, skip_duplicates=True, update_duplicates=False, dry_run=False):
        """Process a single post from the JSON data."""
        
        # Validate required fields
        required_fields = ['id', 'title', 'likes', 'date', 'cover_url', 'video_link']
        for field in required_fields:
            if field not in post_data:
                raise ValueError(f'Missing required field: {field}')

        # Extract and validate data
        post_id = str(post_data['id'])
        title = post_data['title']
        likes = int(post_data['likes'])
        date_str = post_data['date']
        cover_url = post_data['cover_url']
        video_link = post_data['video_link']

        # Parse date
        date = parse_datetime(date_str)
        if not date:
            raise ValueError(f'Invalid date format: {date_str}')

        # Optional fields
        views = post_data.get('views')
        comments = post_data.get('comments')
        shares = post_data.get('shares')
        bookmarks = post_data.get('bookmarks')
        duration = post_data.get('duration')
        hashtags = post_data.get('hashtags', [])
        music = post_data.get('music')
        location = post_data.get('location')

        # Check if post exists
        existing_post = Post.objects.filter(post_id=post_id).first()

        if existing_post:
            if update_duplicates and not dry_run:
                # Update existing post
                existing_post.title = title
                existing_post.likes = likes
                existing_post.date = date
                existing_post.cover_url = cover_url
                existing_post.video_link = video_link
                existing_post.views = views
                existing_post.comments = comments
                existing_post.shares = shares
                existing_post.bookmarks = bookmarks
                existing_post.duration = duration
                existing_post.hashtags = hashtags
                existing_post.music = music
                existing_post.location = location
                existing_post.save()
                return 'updated'
            else:
                # Skip duplicate
                return 'skipped'
        else:
            # Create new post
            if not dry_run:
                Post.objects.create(
                    post_id=post_id,
                    title=title,
                    likes=likes,
                    date=date,
                    cover_url=cover_url,
                    video_link=video_link,
                    views=views,
                    comments=comments,
                    shares=shares,
                    bookmarks=bookmarks,
                    duration=duration,
                    hashtags=hashtags,
                    music=music,
                    location=location
                )
            return 'created'

    def _print_progress(self, current, total):
        """Print progress indicator."""
        percentage = (current / total) * 100
        bar_length = 50
        filled = int(bar_length * current / total)
        bar = '█' * filled + '░' * (bar_length - filled)
        
        self.stdout.write(
            f'\r[{bar}] {current}/{total} ({percentage:.1f}%)',
            ending=''
        )
        self.stdout.flush()
        
        if current == total:
            self.stdout.write('')  # New line after completion
