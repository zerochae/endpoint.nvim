from fastapi import APIRouter

router = APIRouter()

# Single line commented endpoints - should be filtered
# @router.get("/single-line-comment")
# def get_single_line_comment():
#     return {"message": "filtered"}

# @router.post("/another-comment")
# async def post_another_comment():
#     return {"status": "filtered"}

"""
Multi-line string commented endpoints - should NOT be filtered (not comments)
@router.put("/docstring-not-comment")
def put_docstring():
    return {"message": "should be detected"}
"""

# Active endpoints - should NOT be filtered
@router.get("/active")
def get_active():
    """This is active"""
    return {"message": "active"}

@router.post("/users")
async def create_user():
    return {"message": "created"}

# Mixed scenarios
# @router.delete("/mixed-comment") # This should be filtered

@router.patch("/active-after-comment")
def patch_active_after_comment():
    return {"message": "active"}  # This should NOT be filtered

# Hash comment with different content
# This is just a regular comment, not an endpoint

@app.get("/with-app-prefix")
def get_with_app_prefix():
    return {"message": "active"}

# @app.post("/commented-app-prefix")  # Should be filtered