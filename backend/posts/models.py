from django.db import models
from django.contrib.postgres.fields import ArrayField
from django.core.validators import MinValueValidator
from django.contrib.auth.models import User


class Post(models.Model):
    """
    TikTok Post model representing a single TikTok video with analytics data.
    
    Required fields match the TikTok JSON schema defined in data/schema.json
    """
    
    # Required fields (from schema)
    post_id = models.CharField(
        max_length=50,
        unique=True,
        db_index=True,
        help_text="TikTok post ID (19-digit numeric string)"
    )
    title = models.TextField(
        max_length=2200,
        help_text="Post caption/description"
    )
    likes = models.IntegerField(
        validators=[MinValueValidator(0)],
        help_text="Number of likes"
    )
    date = models.DateTimeField(
        db_index=True,
        help_text="Post creation date"
    )
    cover_url = models.URLField(
        max_length=500,
        help_text="Cover/thumbnail image URL"
    )
    video_link = models.URLField(
        max_length=500,
        help_text="TikTok video URL"
    )
    
    # Optional fields (from schema)
    views = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
        help_text="Number of views"
    )
    comments = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
        help_text="Number of comments"
    )
    shares = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
        help_text="Number of shares"
    )
    duration = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1)],
        help_text="Video duration in seconds"
    )
    hashtags = models.JSONField(
        null=True,
        blank=True,
        default=list,
        help_text="Array of hashtags"
    )
    is_private = models.BooleanField(
        default=False,
        help_text="Whether the post is private"
    )
    is_pinned = models.BooleanField(
        default=False,
        help_text="Whether the post is pinned to profile"
    )
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-date']  # Most recent posts first
        verbose_name = 'TikTok Post'
        verbose_name_plural = 'TikTok Posts'
        indexes = [
            models.Index(fields=['-date']),
            models.Index(fields=['post_id']),
            models.Index(fields=['-likes']),
        ]
    
    def __str__(self):
        return f"{self.post_id} - {self.title[:50]}"
    
    @property
    def engagement_ratio(self):
        """Calculate likes per view (if views available)"""
        if self.views and self.views > 0:
            return round(self.likes / self.views, 4)
        return None
    
    @property
    def total_engagement(self):
        """Calculate total engagement (likes + comments + shares)"""
        total = self.likes
        if self.comments:
            total += self.comments
        if self.shares:
            total += self.shares
        return total


class Follower(models.Model):
    """
    TikTok Follower model representing users who follow the account.
    
    Parsed from Follower.FansList section of TikTok export JSON.
    """
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='followers',
        help_text="User account this follower belongs to"
    )
    username = models.CharField(
        max_length=100,
        db_index=True,
        help_text="TikTok username of the follower"
    )
    date_followed = models.DateTimeField(
        db_index=True,
        help_text="Date when this user started following"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when this record was imported"
    )
    
    class Meta:
        ordering = ['-date_followed']
        verbose_name = 'Follower'
        verbose_name_plural = 'Followers'
        unique_together = [['user', 'username']]
        indexes = [
            models.Index(fields=['user', '-date_followed']),
            models.Index(fields=['username']),
        ]
    
    def __str__(self):
        return f"{self.username} (followed on {self.date_followed.date()})"


class Following(models.Model):
    """
    TikTok Following model representing users that the account follows.
    
    Parsed from Following.Following section of TikTok export JSON.
    """
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='following',
        help_text="User account this following relationship belongs to"
    )
    username = models.CharField(
        max_length=100,
        db_index=True,
        help_text="TikTok username being followed"
    )
    date_followed = models.DateTimeField(
        db_index=True,
        help_text="Date when this user was followed"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when this record was imported"
    )
    
    class Meta:
        ordering = ['-date_followed']
        verbose_name = 'Following'
        verbose_name_plural = 'Following'
        unique_together = [['user', 'username']]
        indexes = [
            models.Index(fields=['user', '-date_followed']),
            models.Index(fields=['username']),
        ]
    
    def __str__(self):
        return f"{self.username} (followed on {self.date_followed.date()})"


class FollowerSnapshot(models.Model):
    """
    Historical snapshot of follower/following counts for tracking growth over time.
    
    Allows analysis of follower growth trends and retention rates.
    """
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='follower_snapshots',
        help_text="User account this snapshot belongs to"
    )
    snapshot_date = models.DateTimeField(
        db_index=True,
        help_text="Date of this snapshot"
    )
    follower_count = models.IntegerField(
        validators=[MinValueValidator(0)],
        help_text="Total number of followers at this date"
    )
    following_count = models.IntegerField(
        validators=[MinValueValidator(0)],
        help_text="Total number of following at this date"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when this snapshot was created"
    )
    
    class Meta:
        ordering = ['-snapshot_date']
        verbose_name = 'Follower Snapshot'
        verbose_name_plural = 'Follower Snapshots'
        unique_together = [['user', 'snapshot_date']]
        indexes = [
            models.Index(fields=['user', '-snapshot_date']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.snapshot_date.date()} (Followers: {self.follower_count}, Following: {self.following_count})"
    
    @property
    def follower_ratio(self):
        """Calculate follower/following ratio"""
        if self.following_count > 0:
            return round(self.follower_count / self.following_count, 2)
        return None
