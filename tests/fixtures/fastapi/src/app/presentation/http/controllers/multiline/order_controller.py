"""
Order controller with various multiline patterns.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path, Body
from fastapi.responses import JSONResponse
from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field

from app.domain.entities.order import Order
from app.application.services.order_service import OrderService
from app.presentation.http.dependencies import get_current_user, verify_permissions

router = APIRouter(prefix="/api/multiline/orders", tags=["orders"])

class OrderCreateRequest(BaseModel):
    items: List[Dict[str, Any]]
    shipping_address: str
    notes: Optional[str] = None

class OrderUpdateRequest(BaseModel):
    status: Optional[str] = None
    shipping_address: Optional[str] = None
    notes: Optional[str] = None

# ========================================
# BASIC MULTILINE PATTERNS
# ========================================

@router.get(
    "/{order_id}"
)
async def get_order(
    order_id: int = Path(..., gt=0)
):
    """Get order by ID - simple multiline."""
    return {
        "order_id": order_id,
        "status": "pending",
        "items": [],
        "total": 99.99
    }

@router.post(
    "",
    status_code=status.HTTP_201_CREATED
)
async def create_order(
    order_request: OrderCreateRequest,
    user: dict = Depends(get_current_user)
):
    """Create new order - multiline with dependencies."""
    return {
        "order_id": 123,
        "user_id": user["id"],
        "items": order_request.items,
        "status": "created"
    }

# ========================================
# COMPLEX MULTILINE PATTERNS
# ========================================

@router.put(
    "/{order_id}",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    responses={
        404: {"description": "Order not found"},
        403: {"description": "Cannot modify this order"},
        422: {"description": "Invalid order data"}
    },
    summary="Update order",
    description="Update order details and status"
)
async def update_order(
    order_id: int = Path(..., gt=0, description="Order ID to update"),
    order_request: OrderUpdateRequest,
    current_user: dict = Depends(get_current_user),
    notify_customer: bool = Query(True, description="Send notification to customer")
):
    """Complex multiline with multiple responses and parameters."""
    return {
        "order_id": order_id,
        "updated_by": current_user["id"],
        "changes": order_request.dict(exclude_unset=True),
        "notification_sent": notify_customer
    }

@router.patch(
    "/{order_id}/status",
    status_code=status.HTTP_200_OK,
    responses={
        404: {"description": "Order not found"},
        400: {"description": "Invalid status transition"}
    }
)
async def update_order_status(
    order_id: int = Path(..., gt=0),
    status_update: dict = Body(..., example={"status": "shipped", "tracking_number": "ABC123"}),
    current_user: dict = Depends(get_current_user)
):
    """Update order status with tracking info."""
    return {
        "order_id": order_id,
        "old_status": "processing",
        "new_status": status_update["status"],
        "updated_by": current_user["id"]
    }

@router.delete(
    "/{order_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(verify_permissions("order:delete"))]
)
async def cancel_order(
    order_id: int = Path(..., gt=0),
    reason: str = Query(..., min_length=5, description="Cancellation reason"),
    refund_amount: Optional[float] = Query(None, ge=0, description="Refund amount")
):
    """Cancel order with reason and optional refund."""
    # Implementation would handle cancellation logic
    return

# ========================================
# QUERY AND FILTERING ENDPOINTS
# ========================================

@router.get(
    "",
    response_model=List[dict],
    responses={
        422: {"description": "Invalid query parameters"}
    }
)
async def list_orders(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    status: Optional[str] = Query(None, description="Filter by status"),
    user_id: Optional[int] = Query(None, gt=0, description="Filter by user"),
    date_from: Optional[datetime] = Query(None, description="Start date filter"),
    date_to: Optional[datetime] = Query(None, description="End date filter"),
    current_user: dict = Depends(get_current_user)
):
    """List orders with filtering - multiline with many query params."""
    return [
        {
            "order_id": 1,
            "user_id": user_id or current_user["id"],
            "status": status or "pending",
            "created_at": "2023-01-01T10:00:00Z"
        }
    ]

@router.get(
    "/{order_id}/items",
    response_model=List[dict]
)
async def get_order_items(
    order_id: int = Path(..., gt=0),
    include_details: bool = Query(False, description="Include item details")
):
    """Get order items - simple multiline."""
    return [
        {
            "item_id": 1,
            "product_name": "Widget",
            "quantity": 2,
            "price": 29.99,
            "details": {} if not include_details else {"weight": "1kg", "color": "blue"}
        }
    ]

# ========================================
# ADMIN AND REPORTING ENDPOINTS
# ========================================

@router.get(
    "/reports/summary",
    response_model=dict,
    dependencies=[Depends(verify_permissions("order:report"))],
    responses={
        403: {"description": "Insufficient permissions"},
        422: {"description": "Invalid date range"}
    },
    summary="Order summary report",
    description="Generate summary statistics for orders within date range"
)
async def get_order_summary(
    date_from: datetime = Query(..., description="Report start date"),
    date_to: datetime = Query(..., description="Report end date"),
    group_by: str = Query("day", regex="^(day|week|month)$", description="Grouping interval"),
    include_cancelled: bool = Query(False, description="Include cancelled orders"),
    current_user: dict = Depends(get_current_user)
):
    """Complex reporting endpoint with validation."""
    return {
        "date_range": {"from": date_from, "to": date_to},
        "total_orders": 150,
        "total_revenue": 4532.50,
        "avg_order_value": 30.22,
        "generated_by": current_user["id"]
    }

# Mixed single line
@router.get("/{order_id}/tracking")
async def get_tracking_info(order_id: int):
    return {"order_id": order_id, "tracking": "ABC123", "status": "shipped"}

# Commented complex multiline - should be ignored
# @router.post(
#     "/{order_id}/refund",
#     status_code=status.HTTP_200_OK,
#     responses={
#         404: {"description": "Order not found"},
#         400: {"description": "Refund not allowed"}
#     }
# )
# async def process_refund(
#     order_id: int,
#     refund_data: dict
# ):
#     """This commented endpoint should be ignored."""
#     return {"refunded": True}