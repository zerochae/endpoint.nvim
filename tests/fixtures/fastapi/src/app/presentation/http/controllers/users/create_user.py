from fastapi import APIRouter


def create_create_user_router() -> APIRouter:
    router = APIRouter()

    @router.post(
        "/",
        status_code=201,
    )
    async def create_user():
        return {"message": "User created"}

    @router.put(
        "/{user_id}",
        status_code=200,
    )
    async def update_user(user_id: int):
        return {"message": f"User {user_id} updated"}

    @router.put(
        "/{user_id}/profile",
        status_code=200,
    )
    async def update_user_profile(user_id: int):
        return {"message": f"Profile updated for user {user_id}"}

    @router.patch(
        "/{user_id}/status",
        status_code=200,
    )
    async def update_user_status(user_id: int):
        return {"message": f"Status updated for user {user_id}"}

    @router.delete(
        "/{user_id}",
        status_code=204,
    )
    async def delete_user(user_id: int):
        return {"message": f"User {user_id} deleted"}

    @router.post(
        "/{user_id}/avatar",
        status_code=201,
    )
    async def upload_avatar(user_id: int):
        return {"message": f"Avatar uploaded for user {user_id}"}

    @router.delete(
        "/{user_id}/avatar",
        status_code=204,
    )
    async def delete_avatar(user_id: int):
        return {"message": f"Avatar deleted for user {user_id}"}

    return router