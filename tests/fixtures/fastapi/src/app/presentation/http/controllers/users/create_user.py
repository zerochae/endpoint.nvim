from fastapi import APIRouter


def create_create_user_router() -> APIRouter:
    router = APIRouter()

    @router.post(
        "/",
        status_code=201,
    )
    async def create_user():
        return {"message": "User created"}

    return router