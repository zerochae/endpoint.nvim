"""
Main FastAPI application with router includes.
"""

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.presentation.http.controllers.multiline.user_controller import router as users_router
from app.presentation.http.controllers.multiline.order_controller import router as orders_router
from app.presentation.http.controllers.multiline.product_controller import router as products_router

app = FastAPI(
    title="Multiline Test API",
    description="API for testing multiline FastAPI decorators",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ========================================
# MAIN APP ENDPOINTS (Direct)
# ========================================

@app.get(
    "/api/multiline/health"
)
async def health_check():
    """Health check endpoint - simple multiline."""
    return {"status": "healthy", "timestamp": "2023-01-01T10:00:00Z"}

@app.get("/api/multiline/version")
async def get_version():
    """Version endpoint - single line for comparison."""
    return {"version": "1.0.0", "build": "abc123"}

@app.get(
    "/api/multiline/info",
    response_model=dict,
    summary="Get API information",
    description="Returns detailed information about the API"
)
async def get_api_info():
    """API info with documentation."""
    return {
        "name": "Multiline Test API",
        "version": "1.0.0",
        "description": "API for testing multiline FastAPI decorators",
        "endpoints": {
            "users": "/api/multiline/users",
            "orders": "/api/multiline/orders",
            "products": "/api/multiline/products"
        }
    }

# ========================================
# ROUTER INCLUDES
# ========================================

# Include all controller routers
app.include_router(users_router)
app.include_router(orders_router)
app.include_router(products_router)

# ========================================
# EXCEPTION HANDLERS WITH MULTILINE
# ========================================

@app.exception_handler(404)
async def not_found_handler(request, exc):
    """Custom 404 handler."""
    return JSONResponse(
        status_code=404,
        content={"error": "Resource not found", "path": str(request.url.path)}
    )

@app.exception_handler(500)
async def internal_error_handler(request, exc):
    """Custom 500 handler."""
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "message": "Something went wrong"}
    )