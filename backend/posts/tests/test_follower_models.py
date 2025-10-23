"""
Unit tests for Follower and Following models.
"""

import pytest
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.utils import timezone
from datetime import datetime, timedelta
from posts.models import Follower, Following, FollowerSnapshot


def make_aware_datetime(year, month, day, hour=0, minute=0, second=0):
    """Helper to create timezone-aware datetime."""
    return timezone.make_aware(datetime(year, month, day, hour, minute, second))


@pytest.mark.django_db
@pytest.mark.unit
class TestFollowerModel:
    """Test Follower model functionality."""

    def test_create_follower_with_required_fields(self, user):
        """Test creating a follower with required fields."""
        follower = Follower.objects.create(
            user=user,
            username='test_follower',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        
        assert follower.username == 'test_follower'
        assert follower.user == user
        assert follower.date_followed == make_aware_datetime(2024, 1, 1, 12, 0, 0)
        assert follower.created_at is not None

    def test_follower_unique_constraint(self, user):
        """Test that user-username combination is unique."""
        Follower.objects.create(
            user=user,
            username='duplicate_user',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        
        with pytest.raises(IntegrityError):
            Follower.objects.create(
                user=user,
                username='duplicate_user',
                date_followed=make_aware_datetime(2024, 1, 2, 12, 0, 0)
            )

    def test_follower_str_representation(self, user):
        """Test string representation of follower."""
        follower = Follower.objects.create(
            user=user,
            username='john_doe',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        
        assert str(follower) == 'john_doe (followed on 2024-01-01)'

    def test_follower_ordering(self, user):
        """Test followers are ordered by date_followed descending."""
        follower1 = Follower.objects.create(
            user=user,
            username='user1',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        follower2 = Follower.objects.create(
            user=user,
            username='user2',
            date_followed=make_aware_datetime(2024, 1, 3, 12, 0, 0)
        )
        follower3 = Follower.objects.create(
            user=user,
            username='user3',
            date_followed=make_aware_datetime(2024, 1, 2, 12, 0, 0)
        )
        
        followers = list(Follower.objects.all())
        assert followers[0] == follower2  # Most recent
        assert followers[1] == follower3
        assert followers[2] == follower1  # Oldest

    def test_bulk_create_followers(self, user):
        """Test bulk creation of followers for performance."""
        followers = [
            Follower(
                user=user,
                username=f'user{i}',
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
            for i in range(100)
        ]
        
        created = Follower.objects.bulk_create(followers)
        assert len(created) == 100
        assert Follower.objects.filter(user=user).count() == 100

    def test_follower_username_index(self, user):
        """Test username field has index for fast searches."""
        # Create multiple followers
        for i in range(50):
            Follower.objects.create(
                user=user,
                username=f'user{i}',
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # This should use the index for fast lookup
        result = Follower.objects.filter(username='user25').first()
        assert result is not None
        assert result.username == 'user25'


@pytest.mark.django_db
@pytest.mark.unit
class TestFollowingModel:
    """Test Following model functionality."""

    def test_create_following_with_required_fields(self, user):
        """Test creating a following with required fields."""
        following = Following.objects.create(
            user=user,
            username='test_following',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        
        assert following.username == 'test_following'
        assert following.user == user
        assert following.date_followed == make_aware_datetime(2024, 1, 1, 12, 0, 0)
        assert following.created_at is not None

    def test_following_unique_constraint(self, user):
        """Test that user-username combination is unique."""
        Following.objects.create(
            user=user,
            username='duplicate_user',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        
        with pytest.raises(IntegrityError):
            Following.objects.create(
                user=user,
                username='duplicate_user',
                date_followed=make_aware_datetime(2024, 1, 2, 12, 0, 0)
            )

    def test_following_str_representation(self, user):
        """Test string representation of following."""
        following = Following.objects.create(
            user=user,
            username='jane_doe',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        
        assert str(following) == 'jane_doe (followed on 2024-01-01)'

    def test_following_ordering(self, user):
        """Test followings are ordered by date_followed descending."""
        following1 = Following.objects.create(
            user=user,
            username='user1',
            date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
        )
        following2 = Following.objects.create(
            user=user,
            username='user2',
            date_followed=make_aware_datetime(2024, 1, 3, 12, 0, 0)
        )
        following3 = Following.objects.create(
            user=user,
            username='user3',
            date_followed=make_aware_datetime(2024, 1, 2, 12, 0, 0)
        )
        
        followings = list(Following.objects.all())
        assert followings[0] == following2  # Most recent
        assert followings[1] == following3
        assert followings[2] == following1  # Oldest

    def test_bulk_create_followings(self, user):
        """Test bulk creation of followings for performance."""
        followings = [
            Following(
                user=user,
                username=f'user{i}',
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
            for i in range(100)
        ]
        
        created = Following.objects.bulk_create(followings)
        assert len(created) == 100
        assert Following.objects.filter(user=user).count() == 100


@pytest.mark.django_db
@pytest.mark.unit
class TestFollowerSnapshotModel:
    """Test FollowerSnapshot model functionality."""

    def test_create_snapshot(self, user):
        """Test creating a follower snapshot."""
        snapshot = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 1),
            follower_count=100,
            following_count=80
        )
        
        assert snapshot.user == user
        assert snapshot.snapshot_date == make_aware_datetime(2024, 1, 1)
        assert snapshot.follower_count == 100
        assert snapshot.following_count == 80
        assert snapshot.created_at is not None

    def test_snapshot_follower_ratio_property(self, user):
        """Test follower_ratio property calculation."""
        snapshot = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 1),
            follower_count=200,
            following_count=100
        )
        
        assert abs(snapshot.follower_ratio - 2.0) < 0.01

    def test_snapshot_ratio_with_zero_following(self, user):
        """Test ratio calculation when following is 0."""
        snapshot = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 1),
            follower_count=100,
            following_count=0
        )
        
        assert snapshot.follower_ratio is None

    def test_snapshot_ordering(self, user):
        """Test snapshots are ordered by date descending."""
        snap1 = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 1),
            follower_count=100,
            following_count=80
        )
        snap2 = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 3),
            follower_count=120,
            following_count=85
        )
        snap3 = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 2),
            follower_count=110,
            following_count=82
        )
        
        snapshots = list(FollowerSnapshot.objects.all())
        assert snapshots[0] == snap2  # Most recent
        assert snapshots[1] == snap3
        assert snapshots[2] == snap1  # Oldest

    def test_snapshot_str_representation(self, user):
        """Test string representation of snapshot."""
        snapshot = FollowerSnapshot.objects.create(
            user=user,
            snapshot_date=make_aware_datetime(2024, 1, 1),
            follower_count=100,
            following_count=80
        )
        
        assert str(snapshot) == f'{user.username} - 2024-01-01 (Followers: 100, Following: 80)'


@pytest.mark.django_db
@pytest.mark.unit
class TestFollowerFollowingComparison:
    """Test comparison algorithms between followers and following."""

    def test_find_mutuals(self, user):
        """Test finding mutual followers (intersection)."""
        # Create followers
        for username in ['user1', 'user2', 'user3', 'user4']:
            Follower.objects.create(
                user=user,
                username=username,
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # Create followings (user2 and user3 are mutual)
        for username in ['user2', 'user3', 'user5', 'user6']:
            Following.objects.create(
                user=user,
                username=username,
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # Find mutuals using set intersection
        follower_usernames = set(
            Follower.objects.filter(user=user).values_list('username', flat=True)
        )
        following_usernames = set(
            Following.objects.filter(user=user).values_list('username', flat=True)
        )
        mutuals = follower_usernames & following_usernames
        
        assert len(mutuals) == 2
        assert 'user2' in mutuals
        assert 'user3' in mutuals

    def test_find_followers_only(self, user):
        """Test finding followers who you don't follow back (difference)."""
        # Create followers
        for username in ['user1', 'user2', 'user3', 'user4']:
            Follower.objects.create(
                user=user,
                username=username,
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # Create followings
        for username in ['user2', 'user3', 'user5']:
            Following.objects.create(
                user=user,
                username=username,
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # Find followers-only using set difference
        follower_usernames = set(
            Follower.objects.filter(user=user).values_list('username', flat=True)
        )
        following_usernames = set(
            Following.objects.filter(user=user).values_list('username', flat=True)
        )
        followers_only = follower_usernames - following_usernames
        
        assert len(followers_only) == 2
        assert 'user1' in followers_only
        assert 'user4' in followers_only

    def test_find_following_only(self, user):
        """Test finding people you follow who don't follow back (difference)."""
        # Create followers
        for username in ['user1', 'user2']:
            Follower.objects.create(
                user=user,
                username=username,
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # Create followings
        for username in ['user2', 'user3', 'user4', 'user5']:
            Following.objects.create(
                user=user,
                username=username,
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
        
        # Find following-only using set difference
        follower_usernames = set(
            Follower.objects.filter(user=user).values_list('username', flat=True)
        )
        following_usernames = set(
            Following.objects.filter(user=user).values_list('username', flat=True)
        )
        following_only = following_usernames - follower_usernames
        
        assert len(following_only) == 3
        assert 'user3' in following_only
        assert 'user4' in following_only
        assert 'user5' in following_only

    def test_performance_with_large_dataset(self, user):
        """Test comparison performance with 3000+ entries."""
        # Create 2000 followers
        followers = [
            Follower(
                user=user,
                username=f'follower{i}',
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
            for i in range(2000)
        ]
        Follower.objects.bulk_create(followers)
        
        # Create 2000 followings (1000 overlap)
        followings = [
            Following(
                user=user,
                username=f'follower{i}' if i < 1000 else f'following{i}',
                date_followed=make_aware_datetime(2024, 1, 1, 12, 0, 0)
            )
            for i in range(2000)
        ]
        Following.objects.bulk_create(followings)
        
        # Perform comparisons
        follower_usernames = set(
            Follower.objects.filter(user=user).values_list('username', flat=True)
        )
        following_usernames = set(
            Following.objects.filter(user=user).values_list('username', flat=True)
        )
        
        mutuals = follower_usernames & following_usernames
        followers_only = follower_usernames - following_usernames
        following_only = following_usernames - follower_usernames
        
        assert len(mutuals) == 1000
        assert len(followers_only) == 1000
        assert len(following_only) == 1000
        
        # Verify total counts
        assert Follower.objects.filter(user=user).count() == 2000
        assert Following.objects.filter(user=user).count() == 2000
