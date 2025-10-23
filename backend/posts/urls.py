from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PostViewSet, FollowerViewSet, FollowingViewSet

# Create a router and register our viewsets
router = DefaultRouter()
router.register(r'posts', PostViewSet, basename='post')
router.register(r'followers', FollowerViewSet, basename='follower')
router.register(r'following', FollowingViewSet, basename='following')

urlpatterns = [
    path('', include(router.urls)),
]
