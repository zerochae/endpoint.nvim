from fastapi import APIRouter


def create_list_users_router() -> APIRouter:
    router = APIRouter()

    @router.get(
        "/",
        status_code=200,
    )
    async def list_users():
        return {"users": []}

    return router