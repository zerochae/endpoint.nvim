from fastapi import APIRouter


def create_log_in_router() -> APIRouter:
    router = APIRouter()

    @router.post(
        "/login",
        status_code=200,
    )
    async def log_in():
        return {"message": "Logged in"}

    return router