from django.contrib import admin
from .models import Post


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['post_id', 'title_short', 'likes', 'views', 'date', 'is_pinned']
    list_filter = ['is_pinned', 'is_private', 'date']
    search_fields = ['post_id', 'title', 'hashtags']
    readonly_fields = ['created_at', 'updated_at', 'engagement_ratio', 'total_engagement']
    ordering = ['-date']
    
    def title_short(self, obj):
        return obj.title[:50] + '...' if len(obj.title) > 50 else obj.title
    title_short.short_description = 'Title'
