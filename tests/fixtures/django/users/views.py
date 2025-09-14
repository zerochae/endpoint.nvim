from django.http import JsonResponse
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.views import View
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

# Function-based views
def user_list(request):
    """List all users - supports GET and POST"""
    if request.method == 'GET':
        return JsonResponse({'users': [], 'method': 'GET'})
    elif request.method == 'POST':
        return JsonResponse({'message': 'User created', 'method': 'POST'})

def create_user(request):
    """Create a new user - POST only"""
    return JsonResponse({'message': 'User creation endpoint'})

def user_detail_function(request, pk):
    """User detail function-based view"""
    return JsonResponse({'user_id': pk, 'type': 'function'})

# Django generic class-based views
class UserListView(ListView):
    """List view for users - GET"""
    def get(self, request):
        return JsonResponse({'users': [], 'type': 'ListView'})

class UserDetailView(DetailView):
    """Detail view for users - GET"""
    def get(self, request, pk):
        return JsonResponse({'user_id': pk, 'type': 'DetailView'})

class UserCreateView(CreateView):
    """Create view for users - GET, POST"""
    def get(self, request):
        return JsonResponse({'form': 'create_form', 'method': 'GET'})
    
    def post(self, request):
        return JsonResponse({'message': 'User created', 'method': 'POST'})

class UserUpdateView(UpdateView):
    """Update view for users - GET, POST, PUT, PATCH"""
    def get(self, request, pk):
        return JsonResponse({'user_id': pk, 'form': 'update_form'})
    
    def post(self, request, pk):
        return JsonResponse({'user_id': pk, 'method': 'POST'})
    
    def put(self, request, pk):
        return JsonResponse({'user_id': pk, 'method': 'PUT'})
    
    def patch(self, request, pk):
        return JsonResponse({'user_id': pk, 'method': 'PATCH'})

class UserDeleteView(DeleteView):
    """Delete view for users - GET, POST, DELETE"""
    def get(self, request, pk):
        return JsonResponse({'user_id': pk, 'confirm': 'delete'})
    
    def post(self, request, pk):
        return JsonResponse({'user_id': pk, 'method': 'POST', 'deleted': True})
    
    def delete(self, request, pk):
        return JsonResponse({'user_id': pk, 'method': 'DELETE', 'deleted': True})

# Django REST Framework views
class UserAPIView(APIView):
    """DRF API view for users - GET, POST"""
    def get(self, request):
        return Response({'users': [], 'api': 'DRF'})
    
    def post(self, request):
        return Response({'message': 'User created via API'}, status=status.HTTP_201_CREATED)

class UserDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """DRF generic view - GET, PUT, PATCH, DELETE"""
    def get(self, request, pk):
        return Response({'user_id': pk, 'method': 'GET', 'api': 'DRF'})
    
    def put(self, request, pk):
        return Response({'user_id': pk, 'method': 'PUT', 'api': 'DRF'})
    
    def patch(self, request, pk):
        return Response({'user_id': pk, 'method': 'PATCH', 'api': 'DRF'})
    
    def delete(self, request, pk):
        return Response({'user_id': pk, 'method': 'DELETE', 'api': 'DRF'})

# Custom View class
class CustomUserView(View):
    """Custom view with multiple HTTP methods"""
    def get(self, request):
        return JsonResponse({'method': 'GET', 'type': 'custom'})
    
    def post(self, request):
        return JsonResponse({'method': 'POST', 'type': 'custom'})
    
    def put(self, request):
        return JsonResponse({'method': 'PUT', 'type': 'custom'})
    
    def delete(self, request):
        return JsonResponse({'method': 'DELETE', 'type': 'custom'})