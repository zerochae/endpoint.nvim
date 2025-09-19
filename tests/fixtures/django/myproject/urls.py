"""myproject URL Configuration

The `urlpatterns` list routes URLs to views.
"""
from django.contrib import admin
from django.urls import path, include, re_path
from django.conf.urls import url
from rest_framework.routers import DefaultRouter
from api.views import health_check
from api.viewsets import UserViewSet, ProductViewSet

# DRF Router
router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'products', ProductViewSet)

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),
    
    # Health check
    path('health/', health_check, name='health_check'),
    
    # API routes
    path('api/', include('api.urls')),
    path('api/users/', include('users.urls')),
    path('api/products/', include('products.urls')),
    
    # DRF ViewSet routes
    path('api/v1/', include(router.urls)),
    
    # Legacy URL patterns
    url(r'^legacy/users/$', 'users.views.user_list', name='legacy_users'),
    re_path(r'^regex/users/(?P<user_id>\d+)/$', 'users.views.user_detail'),
    
    # Class-based views
    path('cbv/users/', include('users.urls')),
]