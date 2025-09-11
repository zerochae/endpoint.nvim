from fastapi import APIRouter

from app.presentation.http.controllers.account.log_in import create_log_in_router


def create_account_router() -> APIRouter:
    router = APIRouter(
        prefix="/account",
        tags=["Account"],
    )

    sub_routers = (
        create_log_in_router(),
    )

    for sub_router in sub_routers:
        router.include_router(sub_router)

    return router