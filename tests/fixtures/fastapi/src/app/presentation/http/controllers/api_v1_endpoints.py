from fastapi import APIRouter
from typing import Dict, Any

def create_api_v1_endpoints_router() -> APIRouter:
    router = APIRouter(
        prefix="/api/v1",
        tags=["API v1"],
    )

    @router.get("/health")
    async def health_check() -> Dict[str, str]:
        return {"status": "healthy", "version": "1.0"}

    @router.get("/info")
    async def get_info() -> Dict[str, Any]:
        return {
            "api": "FastAPI Test",
            "version": "1.0.0",
            "endpoints": ["health", "info", "metrics"]
        }

    @router.post(
        "/data",
        status_code=201,
    )
    async def create_data(data: Dict[str, Any]) -> Dict[str, str]:
        return {"message": "Data created", "id": "123"}

    @router.put(
        "/data/{data_id}",
        status_code=200,
    )
    async def update_data(data_id: str, data: Dict[str, Any]) -> Dict[str, str]:
        return {"message": f"Data {data_id} updated"}

    @router.delete(
        "/data/{data_id}",
        status_code=204,
    )
    async def delete_data(data_id: str) -> None:
        pass

    @router.patch("/settings")
    async def update_settings(settings: Dict[str, Any]) -> Dict[str, str]:
        return {"message": "Settings updated"}

    @router.get("/users/{user_id}/profile")
    async def get_user_profile(user_id: int) -> Dict[str, Any]:
        return {
            "user_id": user_id,
            "name": "Test User",
            "email": "test@example.com"
        }

    @router.post(
        "/users/{user_id}/notifications",
        status_code=201,
    )
    async def send_notification(
        user_id: int,
        notification: Dict[str, Any]
    ) -> Dict[str, str]:
        return {
            "message": f"Notification sent to user {user_id}",
            "notification_id": "notif-123"
        }

    return router