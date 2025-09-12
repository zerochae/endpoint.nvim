from fastapi import APIRouter, Query


def create_products_router() -> APIRouter:
    router = APIRouter()

    @router.get(
        "/",
        status_code=200,
    )
    async def list_products(limit: int = Query(10), offset: int = Query(0)):
        return {"products": [], "limit": limit, "offset": offset}

    @router.get(
        "/search",
        status_code=200,
    )
    async def search_products(q: str = Query(...)):
        return {"results": [], "query": q}

    @router.get(
        "/categories",
        status_code=200,
    )
    async def list_categories():
        return {"categories": []}

    @router.get(
        "/categories/{category_id}",
        status_code=200,
    )
    async def get_category_products(category_id: int):
        return {"products": [], "category_id": category_id}

    @router.get(
        "/{product_id}",
        status_code=200,
    )
    async def get_product(product_id: int):
        return {"product": {"id": product_id}}

    @router.get(
        "/{product_id}/reviews",
        status_code=200,
    )
    async def get_product_reviews(product_id: int):
        return {"reviews": [], "product_id": product_id}

    @router.get(
        "/{product_id}/related",
        status_code=200,
    )
    async def get_related_products(product_id: int):
        return {"related_products": [], "product_id": product_id}

    @router.get(
        "/{product_id}/inventory",
        status_code=200,
    )
    async def get_product_inventory(product_id: int):
        return {"inventory": {"product_id": product_id, "stock": 0}}

    @router.post(
        "/",
        status_code=201,
    )
    async def create_product():
        return {"message": "Product created"}

    @router.post(
        "/{product_id}/reviews",
        status_code=201,
    )
    async def create_product_review(product_id: int):
        return {"message": f"Review created for product {product_id}"}

    @router.post(
        "/batch",
        status_code=201,
    )
    async def create_products_batch():
        return {"message": "Products created in batch"}

    @router.put(
        "/{product_id}",
        status_code=200,
    )
    async def update_product(product_id: int):
        return {"message": f"Product {product_id} updated"}

    @router.put(
        "/{product_id}/price",
        status_code=200,
    )
    async def update_product_price(product_id: int):
        return {"message": f"Price updated for product {product_id}"}

    @router.patch(
        "/{product_id}/inventory",
        status_code=200,
    )
    async def update_product_inventory(product_id: int):
        return {"message": f"Inventory updated for product {product_id}"}

    @router.patch(
        "/{product_id}/status",
        status_code=200,
    )
    async def update_product_status(product_id: int):
        return {"message": f"Status updated for product {product_id}"}

    @router.delete(
        "/{product_id}",
        status_code=204,
    )
    async def delete_product(product_id: int):
        return {"message": f"Product {product_id} deleted"}

    @router.delete(
        "/{product_id}/reviews/{review_id}",
        status_code=204,
    )
    async def delete_product_review(product_id: int, review_id: int):
        return {"message": f"Review {review_id} deleted for product {product_id}"}

    return router