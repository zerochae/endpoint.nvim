from fastapi import APIRouter


def create_change_password_router() -> APIRouter:
    router = APIRouter()

    @router.patch(
        "/{username}/password",
        status_code=200,
    )
    async def change_password():
        return {"message": "Password changed"}

    return router