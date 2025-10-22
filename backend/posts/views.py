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

    @action(detail=False, methods=['get'])
    def trends(self, request):
        """
        Get views and likes trends over time
        
        GET /api/posts/trends/
        Query params: 
        - grouping: day, week, month (default: day)
        - days: number of days to look back (default: 30)
        """
        from django.db.models.functions import TruncDate, TruncWeek, TruncMonth
        from datetime import datetime, timedelta
        
        grouping = request.query_params.get('grouping', 'day')
        days = int(request.query_params.get('days', 30))
        
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        posts = Post.objects.filter(date__gte=start_date, date__lte=end_date)
        
        if grouping == 'week':
            posts = posts.annotate(period=TruncWeek('date'))
        elif grouping == 'month':
            posts = posts.annotate(period=TruncMonth('date'))
        else:
            posts = posts.annotate(period=TruncDate('date'))
        
        from django.db.models import Sum, Avg, Count as CountAgg
        trends = posts.values('period').annotate(
            total_likes=Sum('likes'),
            total_views=Sum('views'),
            avg_likes=Avg('likes'),
            avg_views=Avg('views'),
            post_count=CountAgg('id')
        ).order_by('period')
        
        result = {
            'grouping': grouping,
            'days': days,
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat(),
            'data': [
                {
                    'date': item['period'].isoformat() if item['period'] else None,
                    'total_likes': item['total_likes'] or 0,
                    'total_views': item['total_views'] or 0,
                    'avg_likes': round(item['avg_likes'], 2) if item['avg_likes'] else 0,
                    'avg_views': round(item['avg_views'], 2) if item['avg_views'] else 0,
                    'post_count': item['post_count']
                }
                for item in trends
            ]
        }
        
        return Response(result)

    def _get_period_annotation(self, window):
        """Helper to get period annotation based on window type"""
        from django.db.models.functions import TruncDate, TruncWeek, TruncMonth
        
        annotations = {
            'daily': TruncDate('date'),
            'monthly': TruncMonth('date'),
            'weekly': TruncWeek('date')
        }
        return annotations.get(window, TruncWeek('date'))
    
    def _get_days_delta(self, window):
        """Helper to get number of days for a window"""
        days_map = {'daily': 1, 'weekly': 7, 'monthly': 30}
        return days_map.get(window, 7)
    
    def _get_period_label(self, period, window):
        """Helper to format period label"""
        if window == 'daily':
            return period.strftime('%b %d, %Y')
        elif window == 'weekly':
            return f"Week of {period.strftime('%b %d, %Y')}"
        else:
            return period.strftime('%B %Y')
    
    def _sort_posts_by_metric(self, posts, metric, limit):
        """Helper to sort posts by metric"""
        if metric == 'views':
            return posts.order_by('-views')[:limit]
        elif metric == 'engagement':
            posts_list = list(posts)
            posts_list.sort(
                key=lambda p: (p.likes + (p.comments or 0) + (p.shares or 0)),
                reverse=True
            )
            return posts_list[:limit]
        else:
            return posts.order_by('-likes')[:limit]

    @action(detail=False, methods=['get'])
    def top_posts_by_time(self, request):
        """
        Get top posts grouped by time window
        
        GET /api/posts/top_posts_by_time/
        Query params:
        - window: daily, weekly, monthly (default: weekly)
        - limit: number of top posts per window (default: 5)
        - metric: likes, views, engagement (default: likes)
        """
        from datetime import timedelta
        
        window = request.query_params.get('window', 'weekly')
        limit = int(request.query_params.get('limit', 5))
        metric = request.query_params.get('metric', 'likes')
        
        # Annotate posts with period
        posts = Post.objects.annotate(period=self._get_period_annotation(window))
        periods = posts.values_list('period', flat=True).distinct().order_by('-period')
        
        result = []
        days_delta = self._get_days_delta(window)
        
        for period in periods[:10]:
            period_posts = Post.objects.filter(
                date__gte=period,
                date__lt=period + timedelta(days=days_delta)
            )
            
            sorted_posts = self._sort_posts_by_metric(period_posts, metric, limit)
            serialized_posts = PostSerializer(sorted_posts, many=True).data
            
            result.append({
                'period': period.isoformat() if period else None,
                'period_label': self._get_period_label(period, window),
                'top_posts': serialized_posts
            })
        
        return Response({
            'window': window,
            'metric': metric,
            'limit': limit,
            'data': result
        })

    @action(detail=False, methods=['get'])
    def keyword_frequency(self, request):
        """
        Analyze keyword frequency in titles
        
        GET /api/posts/keyword_frequency/
        Query params:
        - limit: number of top keywords (default: 20)
        - min_length: minimum word length (default: 3)
        """
        import re
        from collections import Counter
        
        limit = int(request.query_params.get('limit', 20))
        min_length = int(request.query_params.get('min_length', 3))
        
        titles = Post.objects.values_list('title', flat=True)
        
        words = []
        stopwords = {'the', 'and', 'for', 'with', 'this', 'that', 'from', 'was', 
                    'are', 'been', 'have', 'has', 'had', 'but', 'not', 'just', 'your'}
        
        for title in titles:
            cleaned = re.sub(r'[^\w\s#]', ' ', title.lower())
            title_words = cleaned.split()
            
            for word in title_words:
                word = word.lstrip('#')
                if len(word) >= min_length and word not in stopwords:
                    words.append(word)
        
        word_counts = Counter(words)
        top_words = word_counts.most_common(limit)
        
        total_words = sum(word_counts.values())
        
        result = {
            'total_words': total_words,
            'unique_words': len(word_counts),
            'keywords': [
                {
                    'word': word,
                    'count': count,
                    'percentage': round((count / total_words) * 100, 2) if total_words > 0 else 0
                }
                for word, count in top_words
            ]
        }
        
        return Response(result)

    @action(detail=False, methods=['get'])
    def engagement_ratio_analysis(self, request):
        """
        Analyze engagement ratio (likes per day since post date)
        
        GET /api/posts/engagement_ratio_analysis/
        Query params:
        - limit: number of posts to return (default: 20)
        """
        from datetime import datetime
        
        limit = int(request.query_params.get('limit', 20))
        
        posts = Post.objects.all()
        posts_with_ratio = []
        
        now = datetime.now().replace(tzinfo=None)
        
        for post in posts:
            post_date = post.date.replace(tzinfo=None) if post.date.tzinfo else post.date
            days_since_post = max((now - post_date).days, 1)
            
            total_engagement = post.likes + (post.comments or 0) + (post.shares or 0)
            engagement_per_day = total_engagement / days_since_post
            
            posts_with_ratio.append({
                'post': post,
                'days_since_post': days_since_post,
                'total_engagement': total_engagement,
                'engagement_per_day': engagement_per_day,
                'likes_per_day': post.likes / days_since_post
            })
        
        posts_with_ratio.sort(key=lambda x: x['engagement_per_day'], reverse=True)
        top_posts = posts_with_ratio[:limit]
        
        result = {
            'limit': limit,
            'posts': [
                {
                    **PostSerializer(item['post']).data,
                    'days_since_post': item['days_since_post'],
                    'engagement_per_day': round(item['engagement_per_day'], 2),
                    'likes_per_day': round(item['likes_per_day'], 2)
                }
                for item in top_posts
            ]
        }
        
        return Response(result)
