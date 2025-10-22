from django.db.models import Count, Q, Avg
from django.db.models.functions import TruncDate, TruncWeek, TruncMonth
from rest_framework.decorators import action
from rest_framework.response import Response
from collections import Counter
import re
from datetime import datetime, timedelta
from .models import Post
from .serializers import PostSerializer


class AnalyticsViewSet:
    """Analytics endpoints for insights and trends"""

    @action(detail=False, methods=['get'])
    def trends(self, request):
        """
        Get views and likes trends over time
        Query params: 
        - grouping: day, week, month (default: day)
        - days: number of days to look back (default: 30)
        """
        grouping = request.query_params.get('grouping', 'day')
        days = int(request.query_params.get('days', 30))
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # Filter posts within date range
        posts = Post.objects.filter(date__gte=start_date, date__lte=end_date)
        
        # Group by date based on grouping parameter
        if grouping == 'week':
            posts = posts.annotate(period=TruncWeek('date'))
        elif grouping == 'month':
            posts = posts.annotate(period=TruncMonth('date'))
        else:  # day
            posts = posts.annotate(period=TruncDate('date'))
        
        # Aggregate views and likes
        trends = posts.values('period').annotate(
            total_likes=Count('likes'),
            total_views=Count('views'),
            avg_likes=Avg('likes'),
            avg_views=Avg('views'),
            post_count=Count('id')
        ).order_by('period')
        
        # Format response
        result = {
            'grouping': grouping,
            'days': days,
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat(),
            'data': [
                {
                    'date': item['period'].isoformat() if item['period'] else None,
                    'total_likes': item['total_likes'],
                    'total_views': item['total_views'],
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
        annotations = {
            'daily': TruncDate('date'),
            'monthly': TruncMonth('date'),
            'weekly': TruncWeek('date')
        }
        return annotations.get(window, TruncWeek('date'))
    
    def _get_days_for_window(self, window):
        """Helper to get number of days for a window"""
        days_map = {'daily': 1, 'weekly': 7, 'monthly': 30}
        return days_map.get(window, 7)
    
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
        Query params:
        - window: daily, weekly, monthly (default: weekly)
        - limit: number of top posts per window (default: 5)
        - metric: likes, views, engagement (default: likes)
        """
        window = request.query_params.get('window', 'weekly')
        limit = int(request.query_params.get('limit', 5))
        metric = request.query_params.get('metric', 'likes')
        
        # Annotate posts with period
        posts = Post.objects.annotate(period=self._get_period_annotation(window))
        periods = posts.values_list('period', flat=True).distinct().order_by('-period')
        
        result = []
        days_delta = self._get_days_for_window(window)
        
        for period in periods[:10]:
            period_posts = Post.objects.filter(
                date__gte=period,
                date__lt=period + timedelta(days=days_delta)
            )
            
            sorted_posts = self._sort_posts_by_metric(period_posts, metric, limit)
            serialized_posts = PostSerializer(sorted_posts, many=True).data
            
            result.append({
                'period': period.isoformat() if period else None,
                'period_label': self._format_period_label(period, window),
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
        Query params:
        - limit: number of top keywords (default: 20)
        - min_length: minimum word length (default: 3)
        """
        limit = int(request.query_params.get('limit', 20))
        min_length = int(request.query_params.get('min_length', 3))
        
        # Get all titles
        titles = Post.objects.values_list('title', flat=True)
        
        # Extract words
        words = []
        stopwords = {'the', 'and', 'for', 'with', 'this', 'that', 'from', 'was', 'are', 'been', 'have', 'has', 'had', 'but', 'not'}
        
        for title in titles:
            # Remove emojis and special characters, keep hashtags
            cleaned = re.sub(r'[^\w\s#]', ' ', title.lower())
            title_words = cleaned.split()
            
            for word in title_words:
                # Remove hashtag symbol but keep the word
                word = word.lstrip('#')
                if len(word) >= min_length and word not in stopwords:
                    words.append(word)
        
        # Count frequencies
        word_counts = Counter(words)
        top_words = word_counts.most_common(limit)
        
        # Calculate total for percentages
        total_words = sum(word_counts.values())
        
        result = {
            'total_words': total_words,
            'unique_words': len(word_counts),
            'keywords': [
                {
                    'word': word,
                    'count': count,
                    'percentage': round((count / total_words) * 100, 2)
                }
                for word, count in top_words
            ]
        }
        
        return Response(result)

    @action(detail=False, methods=['get'])
    def engagement_ratio_analysis(self, request):
        """
        Analyze engagement ratio (likes per day since post date)
        Returns posts sorted by daily engagement rate
        Query params:
        - limit: number of posts to return (default: 20)
        """
        limit = int(request.query_params.get('limit', 20))
        
        posts = Post.objects.all()
        posts_with_ratio = []
        
        now = datetime.now().replace(tzinfo=None)
        
        for post in posts:
            # Calculate days since post
            post_date = post.date.replace(tzinfo=None) if post.date.tzinfo else post.date
            days_since_post = max((now - post_date).days, 1)
            
            # Calculate engagement per day
            total_engagement = post.likes + (post.comments or 0) + (post.shares or 0)
            engagement_per_day = total_engagement / days_since_post
            
            posts_with_ratio.append({
                'post': post,
                'days_since_post': days_since_post,
                'total_engagement': total_engagement,
                'engagement_per_day': engagement_per_day,
                'likes_per_day': post.likes / days_since_post
            })
        
        # Sort by engagement per day
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

    def _format_period_label(self, period, window):
        """Format period date as readable label"""
        if window == 'daily':
            return period.strftime('%b %d, %Y')
        elif window == 'weekly':
            return f"Week of {period.strftime('%b %d, %Y')}"
        else:  # monthly
            return period.strftime('%B %Y')
