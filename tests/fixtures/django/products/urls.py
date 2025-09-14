from django.urls import path, re_path
from . import views

app_name = 'products'

urlpatterns = [
    # Function-based views
    path('', views.product_list, name='product_list'),
    path('search/', views.search_products, name='search_products'),
    path('<int:product_id>/', views.product_detail, name='product_detail'),
    path('<int:product_id>/reviews/', views.product_reviews, name='product_reviews'),
    path('category/<slug:category>/', views.products_by_category, name='products_by_category'),
    
    # Regex patterns
    re_path(r'^(?P<product_id>\d+)/images/$', views.product_images, name='product_images'),
    re_path(r'^batch/(?P<action>update|delete)/$', views.batch_operations, name='batch_operations'),
    
    # Class-based views
    path('manage/', views.ProductManageView.as_view(), name='product_manage'),
    path('manage/<int:pk>/', views.ProductDetailManageView.as_view(), name='product_detail_manage'),
    path('analytics/', views.ProductAnalyticsView.as_view(), name='product_analytics'),
]