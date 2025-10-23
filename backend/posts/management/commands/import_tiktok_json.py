"""
Django management command to import TikTok data from JSON export file.

This command supports importing:
- Posts from Post.Posts.VideoList
- Followers from Follower.FansList  
- Following from Following.Following

Usage:
    python manage.py import_tiktok_json path/to/export.json
    python manage.py import_tiktok_json path/to/export.json --dry-run
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
    help = 'Import TikTok data (posts, followers, following) from JSON export'

    def add_arguments(self, parser):
        parser.add_argument(
            'json_file',
            type=str,
            help='Path to TikTok JSON export file'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Validate without importing'
        )
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Delete all existing data before import'
        )
        parser.add_argument(
            '--posts-only',
            action='store_true',
            help='Import only posts'
        )
        parser.add_argument(
            '--followers-only',
            action='store_true',
            help='Import only followers/following'
        )
        parser.add_argument(
            '--user',
            type=str,
            default='admin',
            help='Username to associate data with (default: admin)'
        )

    def handle(self, *args, **options):
        """Main command handler."""
        json_file = options['json_file']
        dry_run = options['dry_run']
        clear_existing = options['clear_existing']
        posts_only = options['posts_only']
        followers_only = options['followers_only']
        username = options['user']

        # Validate file
        if not os.path.exists(json_file):
            raise CommandError(f'File not found: {json_file}')

        # Get or create user
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(
                f'User "{username}" not found. Create user first or use --user option.'
            )

        # Read JSON
        self.stdout.write(
            self.style.MIGRATE_HEADING(f'\n📂 Reading: {json_file}')
        )
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise CommandError(f'Invalid JSON: {e}')
        except Exception as e:
            raise CommandError(f'Error reading file: {e}')

        # Determine what to import
        import_posts = not followers_only
        import_followers = not posts_only

        # Clear existing data if requested
        if clear_existing and not dry_run:
            self._clear_existing_data(user, import_posts, import_followers)

        # Import data
        stats = {
            'posts_created': 0,
            'posts_skipped': 0,
            'posts_errors': 0,
            'followers_created': 0,
            'followers_skipped': 0,
            'followers_errors': 0,
            'following_created': 0,
            'following_skipped': 0,
            'following_errors': 0,
        }

        try:
            with transaction.atomic():
                # Import posts
                if import_posts:
                    posts_stats = self._import_posts(data, user, dry_run)
                    stats.update(posts_stats)

                # Import followers
                if import_followers:
                    followers_stats = self._import_followers(data, user, dry_run)
                    stats.update(followers_stats)
                    
                    following_stats = self._import_following(data, user, dry_run)
                    stats.update(following_stats)

                    # Create snapshot
                    if not dry_run:
                        snapshot_stats = self._create_snapshot(user, data)
                        stats.update(snapshot_stats)

                if dry_run:
                    self.stdout.write(
                        self.style.WARNING(
                            '\n🔄 DRY RUN - No data imported (rolling back)'
                        )
                    )
                    raise CommandError("Dry run")

        except CommandError:
            if not dry_run:
                raise

        # Print summary
        self._print_summary(stats, dry_run)

    def _clear_existing_data(self, user, clear_posts, clear_followers):
        """Clear existing data."""
        if clear_posts:
            count = Post.objects.count()
            if count > 0:
                self.stdout.write(
                    self.style.WARNING(f'⚠️  Deleting {count} posts...')
                )
                Post.objects.all().delete()

        if clear_followers:
            f_count = Follower.objects.filter(user=user).count()
            fg_count = Following.objects.filter(user=user).count()
            if f_count > 0 or fg_count > 0:
                self.stdout.write(
                    self.style.WARNING(
                        f'⚠️  Deleting {f_count} followers, {fg_count} following...'
                    )
                )
                Follower.objects.filter(user=user).delete()
                Following.objects.filter(user=user).delete()

    def _import_posts(self, data, user, dry_run):
        """Import posts from Post.Posts.VideoList."""
        self.stdout.write(
            self.style.MIGRATE_HEADING('\n📹 Importing Posts...')
        )

        # Extract posts from nested structure
        posts_data = []
        if isinstance(data, dict) and 'Post' in data:
            posts_data = data.get('Post', {}).get('Posts', {}).get('VideoList', [])
        elif isinstance(data, list):
            posts_data = data  # Old format

        total = len(posts_data)
        self.stdout.write(f'Found {total} posts')

        created = 0
        skipped = 0
        errors = 0

        for i, post_data in enumerate(posts_data, 1):
            try:
                # Convert TikTok export format to our format
                converted = self._convert_post_format(post_data)
                result = self._save_post(converted, dry_run)
                
                if result == 'created':
                    created += 1
                else:
                    skipped += 1

                if i % 100 == 0 or i == total:
                    self._print_progress(i, total, 'posts')

            except Exception as e:
                errors += 1
                if errors <= 5:
                    self.stdout.write(
                        self.style.ERROR(f'\n❌ Post #{i}: {str(e)}')
                    )

        return {
            'posts_created': created,
            'posts_skipped': skipped,
            'posts_errors': errors
        }

    def _import_followers(self, data, user, dry_run):
        """Import followers from Profile And Settings > Follower > FansList."""
        self.stdout.write(
            self.style.MIGRATE_HEADING('\n👥 Importing Followers...')
        )

        followers_data = []
        if isinstance(data, dict):
            # TikTok export structure: Profile And Settings > Follower > FansList
            profile_settings = data.get('Profile And Settings', {})
            if 'Follower' in profile_settings:
                followers_data = profile_settings['Follower'].get('FansList', [])

        total = len(followers_data)
        self.stdout.write(f'Found {total} followers')

        if total == 0:
            return {
                'followers_created': 0,
                'followers_skipped': 0,
                'followers_errors': 0
            }

        created = 0
        skipped = 0
        errors = 0

        # Bulk create for performance
        followers_to_create = []

        for i, follower_data in enumerate(followers_data, 1):
            try:
                username = follower_data.get('UserName', '').strip()
                date_str = follower_data.get('Date', '')

                if not username:
                    raise ValueError("Missing UserName")

                # Parse date
                date = parse_datetime(date_str)
                if not date:
                    raise ValueError(f"Invalid date: {date_str}")

                # Check if exists
                if not dry_run:
                    exists = Follower.objects.filter(
                        user=user,
                        username=username
                    ).exists()

                    if exists:
                        skipped += 1
                    else:
                        followers_to_create.append(
                            Follower(
                                user=user,
                                username=username,
                                date_followed=date
                            )
                        )
                        created += 1
                else:
                    created += 1

                if i % 500 == 0 or i == total:
                    self._print_progress(i, total, 'followers')

            except Exception as e:
                errors += 1
                if errors <= 5:
                    self.stdout.write(
                        self.style.ERROR(f'\n❌ Follower #{i}: {str(e)}')
                    )

        # Bulk insert
        if followers_to_create and not dry_run:
            Follower.objects.bulk_create(
                followers_to_create,
                ignore_conflicts=True
            )

        return {
            'followers_created': created,
            'followers_skipped': skipped,
            'followers_errors': errors
        }

    def _import_following(self, data, user, dry_run):
        """Import following from Profile And Settings > Following > Following."""
        self.stdout.write(
            self.style.MIGRATE_HEADING('\n➕ Importing Following...')
        )

        following_data = []
        if isinstance(data, dict):
            # TikTok export structure: Profile And Settings > Following > Following
            profile_settings = data.get('Profile And Settings', {})
            if 'Following' in profile_settings:
                following_data = profile_settings['Following'].get('Following', [])

        total = len(following_data)
        self.stdout.write(f'Found {total} following')

        if total == 0:
            return {
                'following_created': 0,
                'following_skipped': 0,
                'following_errors': 0
            }

        created = 0
        skipped = 0
        errors = 0

        # Bulk create for performance
        following_to_create = []

        for i, following_item in enumerate(following_data, 1):
            try:
                username = following_item.get('UserName', '').strip()
                date_str = following_item.get('Date', '')

                if not username:
                    raise ValueError("Missing UserName")

                # Parse date
                date = parse_datetime(date_str)
                if not date:
                    raise ValueError(f"Invalid date: {date_str}")

                # Check if exists
                if not dry_run:
                    exists = Following.objects.filter(
                        user=user,
                        username=username
                    ).exists()

                    if exists:
                        skipped += 1
                    else:
                        following_to_create.append(
                            Following(
                                user=user,
                                username=username,
                                date_followed=date
                            )
                        )
                        created += 1
                else:
                    created += 1

                if i % 500 == 0 or i == total:
                    self._print_progress(i, total, 'following')

            except Exception as e:
                errors += 1
                if errors <= 5:
                    self.stdout.write(
                        self.style.ERROR(f'\n❌ Following #{i}: {str(e)}')
                    )

        # Bulk insert
        if following_to_create and not dry_run:
            Following.objects.bulk_create(
                following_to_create,
                ignore_conflicts=True
            )

        return {
            'following_created': created,
            'following_skipped': skipped,
            'following_errors': errors
        }

    def _create_snapshot(self, user, data):
        """Create follower snapshot."""
        # Get counts from data or database
        if isinstance(data, dict):
            follower_count = len(data.get('Follower', {}).get('FansList', []))
            following_count = len(data.get('Following', {}).get('Following', []))
        else:
            follower_count = Follower.objects.filter(user=user).count()
            following_count = Following.objects.filter(user=user).count()

        if follower_count > 0 or following_count > 0:
            snapshot_date = datetime.now()
            FollowerSnapshot.objects.create(
                user=user,
                snapshot_date=snapshot_date,
                follower_count=follower_count,
                following_count=following_count
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f'\n📊 Created snapshot: {follower_count} followers, '
                    f'{following_count} following'
                )
            )

        return {}

    def _convert_post_format(self, post_data):
        """Convert TikTok export format to internal format."""
        # Handle both formats
        if 'Date' in post_data:  # TikTok export format
            return {
                'id': post_data.get('Link', '').split('/')[-1][:19],  # Extract ID
                'title': post_data.get('Title', ''),
                'likes': int(post_data.get('Likes', 0)),
                'date': post_data.get('Date'),
                'cover_url': post_data.get('CoverImage', post_data.get('Link', '')),
                'video_link': post_data.get('Link', ''),
            }
        else:  # Already in internal format
            return post_data

    def _save_post(self, post_data, dry_run):
        """Save a single post."""
        post_id = str(post_data['id'])
        
        if dry_run:
            return 'created'

        # Check if exists
        if Post.objects.filter(post_id=post_id).exists():
            return 'skipped'

        # Create post
        date = parse_datetime(post_data['date'])
        if not date:
            raise ValueError(f"Invalid date: {post_data['date']}")

        Post.objects.create(
            post_id=post_id,
            title=post_data['title'],
            likes=post_data['likes'],
            date=date,
            cover_url=post_data['cover_url'],
            video_link=post_data['video_link']
        )
        return 'created'

    def _print_progress(self, current, total, label):
        """Print progress bar."""
        percentage = (current / total) * 100
        bar_length = 40
        filled = int(bar_length * current / total)
        bar = '█' * filled + '░' * (bar_length - filled)
        
        self.stdout.write(
            f'\r[{bar}] {current}/{total} ({percentage:.1f}%) {label}',
            ending=''
        )
        self.stdout.flush()
        
        if current == total:
            self.stdout.write('')

    def _print_summary(self, stats, dry_run):
        """Print import summary."""
        self.stdout.write('\n' + '=' * 70)
        self.stdout.write(self.style.MIGRATE_HEADING('IMPORT SUMMARY'))
        self.stdout.write('=' * 70)

        # Posts
        posts_total = (stats['posts_created'] + stats['posts_skipped'] + 
                      stats['posts_errors'])
        if posts_total > 0:
            self.stdout.write(self.style.SUCCESS('\n📹 POSTS:'))
            if not dry_run:
                self.stdout.write(f'  ✅ Created:  {stats["posts_created"]}')
                self.stdout.write(f'  ⏭️  Skipped:  {stats["posts_skipped"]}')
            if stats['posts_errors'] > 0:
                self.stdout.write(
                    self.style.ERROR(f'  ❌ Errors:   {stats["posts_errors"]}')
                )
            self.stdout.write(f'  📊 Total:    {posts_total}')

        # Followers
        followers_total = (stats['followers_created'] + stats['followers_skipped'] + 
                          stats['followers_errors'])
        if followers_total > 0:
            self.stdout.write(self.style.SUCCESS('\n👥 FOLLOWERS:'))
            if not dry_run:
                self.stdout.write(f'  ✅ Created:  {stats["followers_created"]}')
                self.stdout.write(f'  ⏭️  Skipped:  {stats["followers_skipped"]}')
            if stats['followers_errors'] > 0:
                self.stdout.write(
                    self.style.ERROR(f'  ❌ Errors:   {stats["followers_errors"]}')
                )
            self.stdout.write(f'  📊 Total:    {followers_total}')

        # Following
        following_total = (stats['following_created'] + stats['following_skipped'] + 
                          stats['following_errors'])
        if following_total > 0:
            self.stdout.write(self.style.SUCCESS('\n➕ FOLLOWING:'))
            if not dry_run:
                self.stdout.write(f'  ✅ Created:  {stats["following_created"]}')
                self.stdout.write(f'  ⏭️  Skipped:  {stats["following_skipped"]}')
            if stats['following_errors'] > 0:
                self.stdout.write(
                    self.style.ERROR(f'  ❌ Errors:   {stats["following_errors"]}')
                )
            self.stdout.write(f'  📊 Total:    {following_total}')

        self.stdout.write('=' * 70)

        if dry_run:
            self.stdout.write(
                self.style.SUCCESS('\n✅ Validation complete! File ready to import.')
            )
            self.stdout.write(
                self.style.WARNING('Run without --dry-run to import.\n')
            )
        else:
            total_created = (stats['posts_created'] + stats['followers_created'] + 
                           stats['following_created'])
            self.stdout.write(
                self.style.SUCCESS(f'\n✅ Import complete! {total_created} items imported.\n')
            )
