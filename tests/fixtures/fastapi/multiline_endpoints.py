from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

app = FastAPI()

# Multiline decorator examples that should be detected by the parser
class UserCreate(BaseModel):
    name: str
    email: str
    age: Optional[int] = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    age: Optional[int] = None

# Test case 1: Simple multiline decorator
@app.get(
    "/users/{user_id}"
)
async def get_user(user_id: int) -> UserResponse:
    """Get a user by ID"""
    return UserResponse(id=user_id, name="John", email="john@example.com")

# Test case 2: Multiline with response model
@app.post(
    "/users",
    response_model=UserResponse,
    status_code=201
)
async def create_user(user: UserCreate) -> UserResponse:
    """Create a new user"""
    return UserResponse(id=1, name=user.name, email=user.email, age=user.age)

# Test case 3: Complex multiline decorator with dependencies
@app.put(
    "/users/{user_id}",
    response_model=UserResponse,
    dependencies=[],
    tags=["users"],
    summary="Update user"
)
async def update_user(
    user_id: int,
    user_update: UserCreate
) -> UserResponse:
    """Update an existing user"""
    return UserResponse(id=user_id, name=user_update.name, email=user_update.email)

# Test case 4: Multiline with very complex parameters
@app.delete(
    "/users/{user_id}",
    status_code=204,
    responses={
        404: {"description": "User not found"},
        403: {"description": "Not authorized"}
    },
    tags=["users", "admin"]
)
async def delete_user(user_id: int):
    """Delete a user by ID"""
    pass

# Test case 5: Router multiline decorator
from fastapi import APIRouter
router = APIRouter(prefix="/api/v1", tags=["api"])

@router.patch(
    "/users/{user_id}/status",
    response_model=Dict[str, Any]
)
async def update_user_status(
    user_id: int,
    status: str
) -> Dict[str, Any]:
    """Update user status"""
    return {"user_id": user_id, "status": status, "updated": True}

# Test case 6: Multiline with complex path and query parameters
@app.get(
    "/users/{user_id}/posts/{post_id}",
    response_model=List[Dict[str, Any]],
    description="Get user posts with pagination"
)
async def get_user_posts(
    user_id: int,
    post_id: int,
    limit: int = 10,
    offset: int = 0
) -> List[Dict[str, Any]]:
    """Get posts for a specific user"""
    return [{"id": post_id, "user_id": user_id, "title": "Sample Post"}]

app.include_router(router)