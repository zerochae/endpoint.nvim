from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

class UserViewSet(viewsets.ModelViewSet):
    """
    A ViewSet for managing users
    Provides: GET, POST, PUT, PATCH, DELETE
    """
    def list(self, request):
        """GET /api/v1/users/"""
        return Response({'users': [], 'action': 'list'})
    
    def create(self, request):
        """POST /api/v1/users/"""
        return Response({'message': 'User created'}, status=status.HTTP_201_CREATED)
    
    def retrieve(self, request, pk=None):
        """GET /api/v1/users/{id}/"""
        return Response({'user_id': pk, 'action': 'retrieve'})
    
    def update(self, request, pk=None):
        """PUT /api/v1/users/{id}/"""
        return Response({'user_id': pk, 'action': 'update'})
    
    def partial_update(self, request, pk=None):
        """PATCH /api/v1/users/{id}/"""
        return Response({'user_id': pk, 'action': 'partial_update'})
    
    def destroy(self, request, pk=None):
        """DELETE /api/v1/users/{id}/"""
        return Response({'user_id': pk, 'action': 'destroy'}, status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """POST /api/v1/users/{id}/activate/"""
        return Response({'user_id': pk, 'action': 'activate'})
    
    @action(detail=False, methods=['get'])
    def active_users(self, request):
        """GET /api/v1/users/active_users/"""
        return Response({'users': [], 'filter': 'active'})

class ProductViewSet(viewsets.ViewSet):
    """
    A simple ViewSet for products
    """
    def list(self, request):
        """GET /api/v1/products/"""
        return Response({'products': []})
    
    def create(self, request):
        """POST /api/v1/products/"""
        return Response({'message': 'Product created'})
    
    def retrieve(self, request, pk=None):
        """GET /api/v1/products/{id}/"""
        return Response({'product_id': pk})
    
    def update(self, request, pk=None):
        """PUT /api/v1/products/{id}/"""
        return Response({'product_id': pk, 'updated': True})
    
    def destroy(self, request, pk=None):
        """DELETE /api/v1/products/{id}/"""
        return Response(status=status.HTTP_204_NO_CONTENT)

class ReadOnlyProductViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Read-only ViewSet - only GET operations
    """
    def list(self, request):
        """GET /api/v1/readonly-products/"""
        return Response({'products': [], 'readonly': True})
    
    def retrieve(self, request, pk=None):
        """GET /api/v1/readonly-products/{id}/"""
        return Response({'product_id': pk, 'readonly': True})