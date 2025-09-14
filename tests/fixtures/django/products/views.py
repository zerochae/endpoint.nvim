from django.http import JsonResponse
from django.views import View
from rest_framework.views import APIView
from rest_framework.response import Response

# Function-based views
def product_list(request):
    """List products - GET and POST"""
    if request.method == 'GET':
        return JsonResponse({'products': [], 'method': 'GET'})
    elif request.method == 'POST':
        return JsonResponse({'message': 'Product created', 'method': 'POST'})

def search_products(request):
    """Search products - GET only"""
    return JsonResponse({'results': [], 'query': request.GET.get('q', '')})

def product_detail(request, product_id):
    """Product detail - multiple methods"""
    methods = {
        'GET': 'retrieve',
        'PUT': 'update', 
        'PATCH': 'partial_update',
        'DELETE': 'delete'
    }
    action = methods.get(request.method, 'unknown')
    return JsonResponse({'product_id': product_id, 'action': action})

def product_reviews(request, product_id):
    """Product reviews - GET and POST"""
    if request.method == 'GET':
        return JsonResponse({'product_id': product_id, 'reviews': []})
    elif request.method == 'POST':
        return JsonResponse({'product_id': product_id, 'message': 'Review added'})

def products_by_category(request, category):
    """Products by category - GET"""
    return JsonResponse({'category': category, 'products': []})

def product_images(request, product_id):
    """Product images - GET and POST"""
    if request.method == 'GET':
        return JsonResponse({'product_id': product_id, 'images': []})
    elif request.method == 'POST':
        return JsonResponse({'product_id': product_id, 'message': 'Image uploaded'})

def batch_operations(request, action):
    """Batch operations - POST and DELETE"""
    if request.method == 'POST' and action == 'update':
        return JsonResponse({'action': 'batch_update', 'status': 'completed'})
    elif request.method == 'DELETE' and action == 'delete':
        return JsonResponse({'action': 'batch_delete', 'status': 'completed'})
    return JsonResponse({'error': 'Invalid action'}, status=400)

# Class-based views
class ProductManageView(View):
    """Product management view - GET and POST"""
    def get(self, request):
        return JsonResponse({'products': [], 'management': True})
    
    def post(self, request):
        return JsonResponse({'message': 'Product management action completed'})

class ProductDetailManageView(View):
    """Product detail management - all methods"""
    def get(self, request, pk):
        return JsonResponse({'product_id': pk, 'method': 'GET', 'management': True})
    
    def post(self, request, pk):
        return JsonResponse({'product_id': pk, 'method': 'POST', 'management': True})
    
    def put(self, request, pk):
        return JsonResponse({'product_id': pk, 'method': 'PUT', 'management': True})
    
    def patch(self, request, pk):
        return JsonResponse({'product_id': pk, 'method': 'PATCH', 'management': True})
    
    def delete(self, request, pk):
        return JsonResponse({'product_id': pk, 'method': 'DELETE', 'management': True})

class ProductAnalyticsView(APIView):
    """Product analytics API - GET only"""
    def get(self, request):
        return Response({
            'analytics': {
                'total_products': 0,
                'categories': [],
                'sales': {}
            }
        })