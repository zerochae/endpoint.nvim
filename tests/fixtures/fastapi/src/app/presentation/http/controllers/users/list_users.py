from fastapi import APIRouter


def create_list_users_router() -> APIRouter:
    router = APIRouter()

    @router.get(
        "/",
        status_code=200,
    )
    async def list_users():
        return {"users": []}

    @router.get(
        "/{user_id}",
        status_code=200,
    )
    async def get_user(user_id: int):
        return {"user": {"id": user_id}}

    @router.get(
        "/{user_id}/profile",
        status_code=200,
    )
    async def get_user_profile(user_id: int):
        return {"profile": {"user_id": user_id}}

    @router.get(
        "/{user_id}/posts",
        status_code=200,
    )
    async def get_user_posts(user_id: int):
        return {"posts": [], "user_id": user_id}

    @router.get(
        "/search",
        status_code=200,
    )
    async def search_users(q: str):
        return {"results": [], "query": q}

    return router