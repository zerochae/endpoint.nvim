from django.urls import path, re_path, include
from django.conf.urls import url
from rest_framework.routers import DefaultRouter
from . import views, viewsets

# DRF Router for ViewSets
router = DefaultRouter()
router.register(r'users', viewsets.UserViewSet, basename='user')
router.register(r'products', viewsets.ProductViewSet, basename='product')
router.register(r'readonly-products', viewsets.ReadOnlyProductViewSet, basename='readonly-product')

urlpatterns = [
    # DRF Router URLs for ViewSets
    path('v1/', include(router.urls)),
    
    # Function-based views
    path('status/', views.api_status, name='api_status'),
    path('version/', views.get_version, name='api_version'),
    
    # Path with parameters
    path('users/<int:user_id>/', views.user_detail, name='user_detail'),
    path('users/<int:user_id>/posts/', views.user_posts, name='user_posts'),
    path('users/<str:username>/profile/', views.user_profile, name='user_profile'),
    
    # Regex patterns
    re_path(r'^posts/(?P<post_id>\d+)/$', views.post_detail, name='post_detail'),
    re_path(r'^posts/(?P<post_id>\d+)/comments/$', views.post_comments, name='post_comments'),
    
    # Legacy url() patterns
    url(r'^legacy/status/$', views.legacy_status, name='legacy_status'),
    url(r'^legacy/users/(?P<user_id>\d+)/$', views.legacy_user_detail),
]