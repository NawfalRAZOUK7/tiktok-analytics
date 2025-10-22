from django.db import models
from django.contrib.postgres.fields import ArrayField
from django.core.validators import MinValueValidator


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
