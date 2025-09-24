"""
Product controller demonstrating edge cases and complex multiline patterns.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path, File, UploadFile, Form
from fastapi.responses import JSONResponse, StreamingResponse
from typing import Optional, List, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from datetime import datetime
from enum import Enum

router = APIRouter(prefix="/api/multiline/products", tags=["products"])

class ProductStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    DISCONTINUED = "discontinued"

class ProductCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    price: float = Field(..., gt=0)
    category_id: int = Field(..., gt=0)
    tags: List[str] = Field(default_factory=list)

# ========================================
# EDGE CASE MULTILINE PATTERNS
# ========================================

@router.get(
    ""
)
async def list_products():
    """Minimal multiline - just path on separate line."""
    return {"products": [], "total": 0}

@router.get(
    "/{product_id}",
    response_model=dict,
    responses={404: {"description": "Product not found"}}
)
async def get_product(product_id: int = Path(..., gt=0)):
    """Standard multiline with response model."""
    return {
        "product_id": product_id,
        "name": "Sample Product",
        "price": 29.99,
        "status": "active"
    }

@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=dict,
    responses={
        400: {"description": "Invalid product data"},
        409: {"description": "Product already exists"}
    },
    summary="Create new product",
    description="Create a new product with validation"
)
async def create_product(product: ProductCreateRequest):
    """Complex creation endpoint."""
    return {
        "product_id": 123,
        "name": product.name,
        "price": product.price,
        "created_at": datetime.now().isoformat()
    }

# ========================================
# MULTILINE WITH FILE UPLOADS
# ========================================

@router.post(
    "/{product_id}/images",
    status_code=status.HTTP_201_CREATED,
    responses={
        413: {"description": "File too large"},
        415: {"description": "Unsupported media type"}
    }
)
async def upload_product_image(
    product_id: int = Path(..., gt=0),
    file: UploadFile = File(...),
    alt_text: Optional[str] = Form(None)
):
    """File upload with multiline decorator."""
    return {
        "product_id": product_id,
        "filename": file.filename,
        "content_type": file.content_type,
        "alt_text": alt_text
    }

@router.put(
    "/{product_id}/images/{image_id}",
    response_model=dict,
    responses={
        404: {"description": "Product or image not found"},
        413: {"description": "File too large"}
    }
)
async def update_product_image(
    product_id: int = Path(..., gt=0),
    image_id: int = Path(..., gt=0),
    file: Optional[UploadFile] = File(None),
    alt_text: Optional[str] = Form(None),
    is_primary: Optional[bool] = Form(None)
):
    """Update image with optional file replacement."""
    return {
        "product_id": product_id,
        "image_id": image_id,
        "updated_fields": {
            "file_updated": file is not None,
            "alt_text": alt_text,
            "is_primary": is_primary
        }
    }

# ========================================
# COMPLEX QUERY PATTERNS
# ========================================

@router.get(
    "/search",
    response_model=List[dict],
    responses={
        422: {"description": "Invalid search parameters"}
    }
)
async def search_products(
    q: Optional[str] = Query(None, min_length=2, description="Search query"),
    category_id: Optional[int] = Query(None, gt=0, description="Category filter"),
    min_price: Optional[float] = Query(None, ge=0, description="Minimum price"),
    max_price: Optional[float] = Query(None, gt=0, description="Maximum price"),
    status: Optional[ProductStatus] = Query(None, description="Product status"),
    tags: Optional[List[str]] = Query(None, description="Product tags"),
    sort_by: Optional[str] = Query("name", regex="^(name|price|created_at)$"),
    sort_order: Optional[str] = Query("asc", regex="^(asc|desc)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100)
):
    """Complex search with many optional parameters."""
    return [
        {
            "product_id": 1,
            "name": "Search Result",
            "price": 19.99,
            "category_id": category_id,
            "status": status or "active"
        }
    ]

# ========================================
# STREAMING AND SPECIAL RESPONSES
# ========================================

@router.get(
    "/export",
    response_class=StreamingResponse,
    responses={
        403: {"description": "Export not allowed"},
        422: {"description": "Invalid export parameters"}
    }
)
async def export_products(
    format: str = Query("csv", regex="^(csv|json|xlsx)$"),
    category_id: Optional[int] = Query(None, gt=0),
    status: Optional[ProductStatus] = Query(None),
    include_images: bool = Query(False)
):
    """Export products in various formats."""
    # Implementation would return StreamingResponse
    return StreamingResponse(
        iter(["product_id,name,price\n", "1,Sample,29.99\n"]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=products.csv"}
    )

# ========================================
# NESTED RESOURCE PATTERNS
# ========================================

@router.get(
    "/{product_id}/reviews",
    response_model=List[dict]
)
async def get_product_reviews(
    product_id: int = Path(..., gt=0),
    rating: Optional[int] = Query(None, ge=1, le=5),
    limit: int = Query(10, ge=1, le=50)
):
    """Get product reviews with filtering."""
    return [
        {
            "review_id": 1,
            "product_id": product_id,
            "rating": rating or 5,
            "comment": "Great product!",
            "created_at": "2023-01-01T10:00:00Z"
        }
    ]

@router.post(
    "/{product_id}/reviews",
    status_code=status.HTTP_201_CREATED,
    response_model=dict,
    responses={
        400: {"description": "Invalid review data"},
        409: {"description": "Review already exists"}
    }
)
async def create_product_review(
    product_id: int = Path(..., gt=0),
    rating: int = Form(..., ge=1, le=5),
    comment: str = Form(..., min_length=10, max_length=1000),
    title: Optional[str] = Form(None, max_length=100)
):
    """Create product review with form data."""
    return {
        "review_id": 456,
        "product_id": product_id,
        "rating": rating,
        "comment": comment,
        "title": title,
        "created_at": datetime.now().isoformat()
    }

# Single line mixed in
@router.get("/{product_id}/stock")
async def get_stock_level(product_id: int):
    return {"product_id": product_id, "stock": 100, "reserved": 5}

@router.patch(
    "/{product_id}/stock",
    status_code=status.HTTP_200_OK
)
async def update_stock(
    product_id: int = Path(..., gt=0),
    quantity: int = Form(...),
    operation: str = Form(..., regex="^(add|subtract|set)$")
):
    """Update stock levels."""
    return {
        "product_id": product_id,
        "operation": operation,
        "quantity": quantity,
        "new_stock": 95
    }

# Triple quoted multiline string patterns (edge case)
@router.get(
    "/{product_id}/description",
    response_model=dict
)
async def get_product_description(product_id: int = Path(..., gt=0)):
    """
    Get detailed product description.

    This is a multiline docstring that should not interfere
    with the decorator parsing above.
    """
    description = """
    This is a sample product with multiple features:
    - Feature 1
    - Feature 2
    - Feature 3
    """
    return {"product_id": product_id, "description": description.strip()}

# Commented out multiline - should be ignored
# @router.delete(
#     "/{product_id}",
#     status_code=status.HTTP_204_NO_CONTENT,
#     responses={
#         404: {"description": "Product not found"},
#         409: {"description": "Cannot delete product with orders"}
#     }
# )
# async def delete_product(product_id: int):
#     """This should be ignored by the parser."""
#     pass