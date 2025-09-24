"""
User controller with multiline FastAPI decorators.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Path
from fastapi.responses import JSONResponse
from typing import Optional, List
from pydantic import BaseModel

from app.domain.entities.user import User
from app.application.services.user_service import UserService
from app.presentation.http.dependencies import get_current_user, verify_admin

router = APIRouter(prefix="/api/multiline/users", tags=["users"])

class UserCreateRequest(BaseModel):
    name: str
    email: str
    age: Optional[int] = None

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    age: Optional[int] = None

# ========================================
# MULTILINE PATTERNS - USER ENDPOINTS
# ========================================

@router.get(
    "/{user_id}"
)
async def get_user(
    user_id: int = Path(..., gt=0)
):
    """Simple multiline decorator - should work perfectly."""
    return {"user_id": user_id, "name": "John Doe"}

@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=dict
)
async def create_user(
    user_request: UserCreateRequest,
    current_user: dict = Depends(get_current_user)
):
    """Complex multiline with response model and status code."""
    return {
        "id": 1,
        "name": user_request.name,
        "email": user_request.email,
        "created_by": current_user["id"]
    }

@router.put(
    "/{user_id}",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    responses={
        404: {"description": "User not found"},
        403: {"description": "Forbidden"}
    }
)
async def update_user(
    user_id: int = Path(..., gt=0),
    user_request: UserUpdateRequest,
    current_user: dict = Depends(get_current_user)
):
    """Multiline with multiple response codes."""
    return {
        "id": user_id,
        "updated_fields": user_request.dict(exclude_unset=True),
        "updated_by": current_user["id"]
    }

@router.delete(
    "/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={
        404: {"description": "User not found"},
        403: {"description": "Forbidden"}
    },
    summary="Delete user",
    description="Soft delete a user by marking as inactive"
)
async def delete_user(
    user_id: int = Path(..., gt=0, description="User ID to delete"),
    current_user: dict = Depends(get_current_user),
    hard_delete: bool = Query(False, description="Permanently delete user")
):
    """Very complex multiline spanning many lines."""
    # Implementation would go here
    return

@router.get(
    "/{user_id}/profile",
    response_model=dict,
    dependencies=[Depends(verify_admin)]
)
async def get_user_profile(
    user_id: int = Path(..., gt=0),
    include_private: bool = Query(False)
):
    """Multiline with dependencies."""
    return {
        "user_id": user_id,
        "profile": {"public_data": True, "private_data": include_private}
    }

# Single line mixed with multiline
@router.get("/{user_id}/posts")
async def get_user_posts(user_id: int):
    """Single line for comparison."""
    return {"user_id": user_id, "posts": []}

@router.patch(
    "/{user_id}/status",
    status_code=status.HTTP_200_OK
)
async def update_user_status(
    user_id: int,
    status_data: dict
):
    """Simple multiline PATCH."""
    return {"user_id": user_id, "status": status_data}

# ========================================
# ADMIN ENDPOINTS WITH COMPLEX PATTERNS
# ========================================

@router.get(
    "/{user_id}/audit-log",
    response_model=List[dict],
    dependencies=[Depends(verify_admin)],
    responses={
        403: {"description": "Admin access required"},
        404: {"description": "User not found"}
    },
    summary="Get user audit log",
    description="Retrieves complete audit trail for user actions"
)
async def get_user_audit_log(
    user_id: int = Path(..., gt=0, description="Target user ID"),
    limit: int = Query(50, le=1000, ge=1, description="Number of entries"),
    offset: int = Query(0, ge=0, description="Pagination offset"),
    action_type: Optional[str] = Query(None, description="Filter by action type"),
    date_from: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    date_to: Optional[str] = Query(None, description="End date (YYYY-MM-DD)")
):
    """Most complex multiline pattern with many parameters."""
    return [
        {
            "id": 1,
            "user_id": user_id,
            "action": "login",
            "timestamp": "2023-01-01T10:00:00Z",
            "ip_address": "127.0.0.1"
        }
    ]

# Commented multiline - should be ignored
# @router.post(
#     "/{user_id}/reset-password",
#     status_code=status.HTTP_200_OK
# )
# async def reset_user_password(user_id: int):
#     """This should not be detected."""
#     return {"reset": True}