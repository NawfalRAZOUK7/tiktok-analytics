from rest_framework import serializers
from .models import Post
from datetime import datetime
from dateutil import parser


class PostSerializer(serializers.ModelSerializer):
    """
    Serializer for TikTok Post model.
    Used for API responses (GET /api/posts/)
    """
    engagement_ratio = serializers.ReadOnlyField()
    total_engagement = serializers.ReadOnlyField()
    
    class Meta:
        model = Post
        fields = [
            'id',
            'post_id',
            'title',
            'likes',
            'date',
            'cover_url',
            'video_link',
            'views',
            'comments',
            'shares',
            'duration',
            'hashtags',
            'is_private',
            'is_pinned',
            'engagement_ratio',
            'total_engagement',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class PostImportSerializer(serializers.Serializer):
    """
    Serializer for importing TikTok posts from JSON schema format.
    Validates and normalizes data from TikTok export JSON.
    """
    id = serializers.CharField(max_length=50, required=True)
    title = serializers.CharField(max_length=2200, allow_blank=True, required=True)
    likes = serializers.IntegerField(min_value=0, required=True)
    date = serializers.DateTimeField(required=True)
    cover_url = serializers.URLField(max_length=500, required=True)
    video_link = serializers.URLField(max_length=500, required=True)
    
    # Optional fields
    views = serializers.IntegerField(min_value=0, required=False, allow_null=True)
    comments = serializers.IntegerField(min_value=0, required=False, allow_null=True)
    shares = serializers.IntegerField(min_value=0, required=False, allow_null=True)
    duration = serializers.IntegerField(min_value=1, max_value=600, required=False, allow_null=True)
    hashtags = serializers.ListField(
        child=serializers.CharField(max_length=100),
        required=False,
        allow_null=True,
        allow_empty=True
    )
    is_private = serializers.BooleanField(required=False, default=False)
    is_pinned = serializers.BooleanField(required=False, default=False)
    
    def validate_date(self, value):
        """Ensure date is not in the future"""
        if value > datetime.now(value.tzinfo):
            raise serializers.ValidationError("Post date cannot be in the future")
        return value
    
    def create(self, validated_data):
        """
        Create or update a Post instance from validated data.
        Uses post_id as the unique identifier (update if exists).
        """
        post_id = validated_data.pop('id')
        
        # Create or update post
        post, created = Post.objects.update_or_create(
            post_id=post_id,
            defaults={
                'title': validated_data.get('title', ''),
                'likes': validated_data.get('likes', 0),
                'date': validated_data.get('date'),
                'cover_url': validated_data.get('cover_url'),
                'video_link': validated_data.get('video_link'),
                'views': validated_data.get('views'),
                'comments': validated_data.get('comments'),
                'shares': validated_data.get('shares'),
                'duration': validated_data.get('duration'),
                'hashtags': validated_data.get('hashtags', []),
                'is_private': validated_data.get('is_private', False),
                'is_pinned': validated_data.get('is_pinned', False),
            }
        )
        
        return post


class TikTokJSONImportSerializer(serializers.Serializer):
    """
    Serializer for the entire TikTok export JSON structure.
    Validates the metadata and posts array according to schema.json.
    """
    metadata = serializers.DictField(required=True)
    posts = PostImportSerializer(many=True, required=True)
    
    def validate_metadata(self, value):
        """Validate metadata structure"""
        required_fields = ['export_date', 'version', 'total_posts']
        for field in required_fields:
            if field not in value:
                raise serializers.ValidationError(
                    f"Metadata is missing required field: {field}"
                )
        
        # Validate total_posts matches actual count
        if 'posts' in self.initial_data:
            actual_count = len(self.initial_data['posts'])
            declared_count = value['total_posts']
            if actual_count != declared_count:
                raise serializers.ValidationError(
                    f"Metadata total_posts ({declared_count}) doesn't match "
                    f"actual posts count ({actual_count})"
                )
        
        return value
    
    def create(self, validated_data):
        """
        Import all posts from validated JSON data.
        Returns statistics about the import.
        """
        posts_data = validated_data['posts']
        metadata = validated_data['metadata']
        
        created_count = 0
        updated_count = 0
        errors = []
        
        for post_data in posts_data:
            try:
                serializer = PostImportSerializer(data=post_data)
                if serializer.is_valid():
                    post = serializer.save()
                    if post:
                        # Check if it was created or updated (simplified check)
                        if Post.objects.filter(post_id=post.post_id).count() == 1:
                            created_count += 1
                        else:
                            updated_count += 1
                else:
                    errors.append({
                        'post_id': post_data.get('id', 'unknown'),
                        'errors': serializer.errors
                    })
            except Exception as e:
                errors.append({
                    'post_id': post_data.get('id', 'unknown'),
                    'errors': str(e)
                })
        
        return {
            'metadata': metadata,
            'imported': created_count + updated_count,
            'created': created_count,
            'updated': updated_count,
            'failed': len(errors),
            'errors': errors if errors else None,
        }
