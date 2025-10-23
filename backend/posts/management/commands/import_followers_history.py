"""
Django management command to import multiple TikTok exports and track follower history.

This command analyzes multiple TikTok exports from different dates to:
- Create historical snapshots of follower/following counts
- Detect followers gained between exports
- Detect followers lost between exports
- Track growth trends over time

Usage:
    python manage.py import_followers_history export1.json export2.json export3.json
    python manage.py import_followers_history data/*.json --user admin
    python manage.py import_followers_history export1.json export2.json --dry-run
"""

import json
import os
from datetime import datetime
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils.dateparse import parse_datetime
from django.contrib.auth import get_user_model
from posts.models import Follower, Following, FollowerSnapshot

User = get_user_model()


class Command(BaseCommand):
    help = 'Import multiple TikTok exports to track follower/following history'

    def add_arguments(self, parser):
        parser.add_argument(
            'json_files',
            nargs='+',
            type=str,
            help='Paths to TikTok JSON export files (ordered by date)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Analyze without importing'
        )
        parser.add_argument(
            '--user',
            type=str,
            default='admin',
            help='Username to associate data with (default: admin)'
        )

    def handle(self, *args, **options):
        """Main command handler."""
        json_files = options['json_files']
        dry_run = options['dry_run']
        username = options['user']

        # Get user
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            raise CommandError(
                f'User "{username}" not found. Create user first.'
            )

        # Validate all files exist
        for json_file in json_files:
            if not os.path.exists(json_file):
                raise CommandError(f'File not found: {json_file}')

        self.stdout.write(
            self.style.MIGRATE_HEADING(
                f'\n📊 Analyzing {len(json_files)} TikTok exports for history tracking\n'
            )
        )

        # Parse all exports
        exports = []
        for i, json_file in enumerate(json_files, 1):
            self.stdout.write(f'📂 Reading file {i}/{len(json_files)}: {json_file}')
            
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                export_info = self._extract_export_info(data, json_file)
                exports.append(export_info)
                
                self.stdout.write(
                    f'  ✓ Date: {export_info["date"]}, '
                    f'Followers: {export_info["follower_count"]}, '
                    f'Following: {export_info["following_count"]}'
                )
                
            except Exception as e:
                raise CommandError(f'Error reading {json_file}: {e}')

        # Sort by date
        exports.sort(key=lambda x: x['date'])

        self.stdout.write(
            self.style.MIGRATE_HEADING('\n📈 Historical Analysis')
        )
        self.stdout.write('=' * 70)

        # Analyze changes between exports
        analysis = self._analyze_history(exports, user, dry_run)

        # Print detailed analysis
        self._print_analysis(analysis, dry_run)

        # Import if not dry run
        if not dry_run:
            self._import_history(exports, user, analysis)
            self.stdout.write(
                self.style.SUCCESS('\n✅ History imported successfully!\n')
            )
        else:
            self.stdout.write(
                self.style.WARNING('\n🔄 DRY RUN - No data imported\n')
            )

    def _extract_export_info(self, data, filename):
        """Extract follower/following info from export."""
        profile_settings = data.get('Profile And Settings', {})
        
        # Extract followers
        followers_data = profile_settings.get('Follower', {}).get('FansList', [])
        followers = set()
        latest_follower_date = None
        
        for item in followers_data:
            username = item.get('UserName', '').strip()
            if username:
                followers.add(username)
                date = parse_datetime(item.get('Date', ''))
                if date and (not latest_follower_date or date > latest_follower_date):
                    latest_follower_date = date

        # Extract following
        following_data = profile_settings.get('Following', {}).get('Following', [])
        following = set()
        latest_following_date = None
        
        for item in following_data:
            username = item.get('UserName', '').strip()
            if username:
                following.add(username)
                date = parse_datetime(item.get('Date', ''))
                if date and (not latest_following_date or date > latest_following_date):
                    latest_following_date = date

        # Use latest date from data or file modification time
        export_date = latest_follower_date or latest_following_date
        if not export_date:
            # Fallback to file modification time
            export_date = datetime.fromtimestamp(os.path.getmtime(filename))

        return {
            'filename': os.path.basename(filename),
            'date': export_date,
            'followers': followers,
            'following': following,
            'follower_count': len(followers),
            'following_count': len(following),
            'followers_data': followers_data,
            'following_data': following_data,
        }

    def _analyze_history(self, exports, user, dry_run):
        """Analyze changes between exports."""
        analysis = {
            'snapshots': [],
            'total_gained': set(),
            'total_lost': set(),
            'changes': []
        }

        for i, export in enumerate(exports):
            snapshot = {
                'date': export['date'],
                'filename': export['filename'],
                'follower_count': export['follower_count'],
                'following_count': export['following_count'],
                'followers': export['followers'],
                'following': export['following'],
            }

            if i > 0:
                prev_export = exports[i - 1]
                
                # Followers gained/lost
                gained_followers = export['followers'] - prev_export['followers']
                lost_followers = prev_export['followers'] - export['followers']
                
                # Following gained/lost
                gained_following = export['following'] - prev_export['following']
                lost_following = prev_export['following'] - export['following']

                change = {
                    'from_date': prev_export['date'],
                    'to_date': export['date'],
                    'from_file': prev_export['filename'],
                    'to_file': export['filename'],
                    'followers_gained': gained_followers,
                    'followers_lost': lost_followers,
                    'following_gained': gained_following,
                    'following_lost': lost_following,
                    'net_followers': len(gained_followers) - len(lost_followers),
                    'net_following': len(gained_following) - len(lost_following),
                }

                analysis['changes'].append(change)
                analysis['total_gained'].update(gained_followers)
                analysis['total_lost'].update(lost_followers)

                snapshot['gained_followers'] = gained_followers
                snapshot['lost_followers'] = lost_followers
                snapshot['gained_following'] = gained_following
                snapshot['lost_following'] = lost_following
            else:
                snapshot['gained_followers'] = set()
                snapshot['lost_followers'] = set()
                snapshot['gained_following'] = set()
                snapshot['lost_following'] = set()

            analysis['snapshots'].append(snapshot)

        return analysis

    def _print_analysis(self, analysis, dry_run):
        """Print detailed analysis."""
        snapshots = analysis['snapshots']
        changes = analysis['changes']

        # Print snapshots
        self.stdout.write('\n📊 SNAPSHOTS:')
        for snapshot in snapshots:
            self.stdout.write(
                f"\n  {snapshot['date'].strftime('%Y-%m-%d %H:%M')} - "
                f"{snapshot['filename']}"
            )
            self.stdout.write(
                f"    👥 Followers: {snapshot['follower_count']:,} "
                f"({len(snapshot['gained_followers']):+d} gained, "
                f"{len(snapshot['lost_followers']):+d} lost)"
            )
            self.stdout.write(
                f"    ➕ Following: {snapshot['following_count']:,} "
                f"({len(snapshot['gained_following']):+d} gained, "
                f"{len(snapshot['lost_following']):+d} lost)"
            )

        # Print changes summary
        if changes:
            self.stdout.write('\n' + '=' * 70)
            self.stdout.write(self.style.MIGRATE_HEADING('📈 GROWTH ANALYSIS:'))
            
            total_follower_growth = sum(c['net_followers'] for c in changes)
            total_following_growth = sum(c['net_following'] for c in changes)
            
            self.stdout.write(
                f"\n  Total Follower Growth: "
                f"{total_follower_growth:+,d} "
                f"({snapshots[0]['follower_count']:,} → "
                f"{snapshots[-1]['follower_count']:,})"
            )
            self.stdout.write(
                f"  Total Following Growth: "
                f"{total_following_growth:+,d} "
                f"({snapshots[0]['following_count']:,} → "
                f"{snapshots[-1]['following_count']:,})"
            )

            # Print period-by-period changes
            self.stdout.write('\n' + '=' * 70)
            self.stdout.write(self.style.MIGRATE_HEADING('📅 PERIOD CHANGES:'))
            
            for i, change in enumerate(changes, 1):
                days_between = (change['to_date'] - change['from_date']).days
                
                self.stdout.write(
                    f"\n  Period {i}: "
                    f"{change['from_date'].strftime('%Y-%m-%d')} → "
                    f"{change['to_date'].strftime('%Y-%m-%d')} "
                    f"({days_between} days)"
                )
                
                self.stdout.write(
                    f"    👥 Followers: {change['net_followers']:+d} "
                    f"(+{len(change['followers_gained'])} gained, "
                    f"-{len(change['followers_lost'])} lost)"
                )
                
                if len(change['followers_gained']) > 0 and len(change['followers_gained']) <= 10:
                    self.stdout.write(
                        f"       New: {', '.join(sorted(list(change['followers_gained'])[:10]))}"
                    )
                
                if len(change['followers_lost']) > 0 and len(change['followers_lost']) <= 10:
                    self.stdout.write(
                        f"       Lost: {', '.join(sorted(list(change['followers_lost'])[:10]))}"
                    )

                self.stdout.write(
                    f"    ➕ Following: {change['net_following']:+d} "
                    f"(+{len(change['following_gained'])} gained, "
                    f"-{len(change['following_lost'])} lost)"
                )

        self.stdout.write('=' * 70)

    def _import_history(self, exports, user, analysis):
        """Import historical data."""
        self.stdout.write(
            self.style.MIGRATE_HEADING('\n💾 Importing historical data...')
        )

        with transaction.atomic():
            # Import each snapshot
            for snapshot in analysis['snapshots']:
                # Create snapshot record
                snapshot_obj, created = FollowerSnapshot.objects.update_or_create(
                    user=user,
                    snapshot_date=snapshot['date'],
                    defaults={
                        'follower_count': snapshot['follower_count'],
                        'following_count': snapshot['following_count'],
                    }
                )
                
                action = "Created" if created else "Updated"
                self.stdout.write(
                    f"  ✓ {action} snapshot for {snapshot['date'].strftime('%Y-%m-%d')}"
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'\n✅ Imported {len(analysis["snapshots"])} snapshots'
            )
        )


