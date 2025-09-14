from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    # Function-based views
    path('', views.user_list, name='user_list'),
    path('create/', views.create_user, name='create_user'),
    path('<int:pk>/', views.user_detail_function, name='user_detail_function'),
    
    # Class-based views
    path('cbv/', views.UserListView.as_view(), name='user_list_cbv'),
    path('cbv/<int:pk>/', views.UserDetailView.as_view(), name='user_detail_cbv'),
    path('cbv/create/', views.UserCreateView.as_view(), name='user_create_cbv'),
    path('cbv/<int:pk>/update/', views.UserUpdateView.as_view(), name='user_update_cbv'),
    path('cbv/<int:pk>/delete/', views.UserDeleteView.as_view(), name='user_delete_cbv'),
    
    # API views
    path('api/', views.UserAPIView.as_view(), name='user_api'),
    path('api/<int:pk>/', views.UserDetailAPIView.as_view(), name='user_detail_api'),
]