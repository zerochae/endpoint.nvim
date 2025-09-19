from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view
from rest_framework.response import Response

# Simple function-based views
def health_check(request):
    """Health check endpoint"""
    return JsonResponse({'status': 'ok'})

def api_status(request):
    """API status endpoint"""
    return JsonResponse({'api': 'running', 'version': '1.0'})

@api_view(['GET'])
def get_version(request):
    """Get API version"""
    return Response({'version': '1.0.0'})

# Views with HTTP method restrictions
@require_http_methods(["GET", "POST"])
def user_detail(request, user_id):
    """User detail view - supports GET and POST"""
    if request.method == 'GET':
        return JsonResponse({'user_id': user_id, 'action': 'get'})
    elif request.method == 'POST':
        return JsonResponse({'user_id': user_id, 'action': 'post'})

@require_http_methods(["GET"])
def user_posts(request, user_id):
    """Get user posts"""
    return JsonResponse({'user_id': user_id, 'posts': []})

@api_view(['GET', 'PUT', 'PATCH'])
def user_profile(request, username):
    """User profile - supports multiple methods"""
    return Response({
        'username': username, 
        'method': request.method.lower()
    })

# DRF API views
@api_view(['GET', 'POST'])
def post_detail(request, post_id):
    """Post detail with DRF decorator"""
    return Response({'post_id': post_id, 'method': request.method})

@api_view(['GET'])
def post_comments(request, post_id):
    """Get post comments"""
    return Response({'post_id': post_id, 'comments': []})

# Legacy views
@csrf_exempt
def legacy_status(request):
    """Legacy API status"""
    return JsonResponse({'legacy': True, 'status': 'ok'})

def legacy_user_detail(request, user_id):
    """Legacy user detail"""
    return JsonResponse({'legacy': True, 'user_id': user_id})