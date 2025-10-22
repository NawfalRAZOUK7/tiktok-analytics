from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import JSONParser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.conf import settings
import json
import jsonschema
from pathlib import Path

from .models import Post
from .serializers import PostSerializer, TikTokJSONImportSerializer


class PostViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for TikTok posts.
    
    Provides:
    - list: GET /api/posts/ - List all posts with pagination, filtering, search
    - retrieve: GET /api/posts/{id}/ - Get a single post by ID
    - import_json: POST /api/posts/import/ - Import posts from TikTok JSON
    """
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    # Filtering
    filterset_fields = {
        'likes': ['gte', 'lte', 'exact'],
        'views': ['gte', 'lte'],
        'date': ['gte', 'lte', 'exact'],
        'is_pinned': ['exact'],
        'is_private': ['exact'],
    }
    
    # Search
    search_fields = ['title', 'post_id', 'hashtags']
    
    # Ordering
    ordering_fields = ['date', 'likes', 'views', 'comments', 'shares']
    ordering = ['-date']  # Default ordering
    
    @action(detail=False, methods=['post'], parser_classes=[JSONParser])
    def import_json(self, request):
        """
        Import TikTok posts from JSON file.
        
        POST /api/posts/import/
        
        Request body should match the TikTok JSON schema:
        {
            "metadata": {
                "export_date": "2025-10-22T10:30:00Z",
                "version": "1.0.0",
                "total_posts": 3
            },
            "posts": [
                {
                    "id": "7298765432109876543",
                    "title": "Post title",
                    "likes": 1234,
                    "date": "2025-09-15T14:23:00Z",
                    "cover_url": "https://...",
                    "video_link": "https://...",
                    ...
                }
            ]
        }
        
        Returns import statistics and any errors.
        """
        
        # Validate against JSON schema first
        schema_path = Path(settings.BASE_DIR).parent / 'data' / 'schema.json'
        
        if schema_path.exists():
            try:
                with open(schema_path, 'r') as f:
                    schema = json.load(f)
                
                # Validate request data against schema
                jsonschema.validate(request.data, schema)
            except jsonschema.ValidationError as e:
                return Response(
                    {
                        'error': 'JSON schema validation failed',
                        'detail': str(e.message),
                        'path': list(e.path) if e.path else None,
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
            except Exception as e:
                return Response(
                    {
                        'error': 'Schema validation error',
                        'detail': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        # Validate and import using DRF serializer
        serializer = TikTokJSONImportSerializer(data=request.data)
        
        if serializer.is_valid():
            result = serializer.save()
            
            response_status = status.HTTP_200_OK if result['failed'] == 0 else status.HTTP_207_MULTI_STATUS
            
            return Response(
                {
                    'status': 'success' if result['failed'] == 0 else 'partial_success',
                    'message': f"Imported {result['imported']} posts successfully",
                    'statistics': {
                        'total_in_file': result['metadata']['total_posts'],
                        'imported': result['imported'],
                        'created': result['created'],
                        'updated': result['updated'],
                        'failed': result['failed'],
                    },
                    'errors': result.get('errors'),
                },
                status=response_status
            )
        
        return Response(
            {
                'error': 'Validation failed',
                'details': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Get aggregate statistics for all posts.
        
        GET /api/posts/stats/
        
        Returns:
        - Total posts count
        - Total likes, views, comments, shares
        - Average engagement metrics
        - Date range of posts
        """
        from django.db.models import Count, Sum, Avg, Min, Max
        
        stats = Post.objects.aggregate(
            total_posts=Count('id'),
            total_likes=Sum('likes'),
            total_views=Sum('views'),
            total_comments=Sum('comments'),
            total_shares=Sum('shares'),
            avg_likes=Avg('likes'),
            avg_views=Avg('views'),
            min_date=Min('date'),
            max_date=Max('date'),
        )
        
        return Response({
            'statistics': stats,
            'message': 'Aggregate statistics for all TikTok posts'
        })
