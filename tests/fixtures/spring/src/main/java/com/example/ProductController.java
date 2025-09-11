package com.example;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    
    @GetMapping
    public String listProducts() {
        return "List of products";
    }
    
    @GetMapping("/{id}")
    public String getProduct(@PathVariable String id) {
        return "Product: " + id;
    }
    
    @GetMapping("/{id}/reviews")
    public String getProductReviews(@PathVariable String id) {
        return "Reviews for product: " + id;
    }
    
    @GetMapping("/{id}/specifications")
    public String getProductSpecs(@PathVariable String id) {
        return "Specifications for product: " + id;
    }
    
    @GetMapping("/categories/{category}")
    public String getProductsByCategory(@PathVariable String category) {
        return "Products in category: " + category;
    }
    
    @GetMapping("/search")
    public String searchProducts(@RequestParam String query) {
        return "Search results for: " + query;
    }
    
    @PostMapping
    public String createProduct() {
        return "Product created";
    }
    
    @PostMapping("/{id}/reviews")
    public String addProductReview(@PathVariable String id) {
        return "Review added for product: " + id;
    }
    
    @PostMapping("/batch")
    public String createProducts() {
        return "Multiple products created";
    }
    
    @PutMapping("/{id}")
    public String updateProduct(@PathVariable String id) {
        return "Product updated: " + id;
    }
    
    @PutMapping("/{id}/price")
    public String updateProductPrice(@PathVariable String id) {
        return "Price updated for product: " + id;
    }
    
    @PatchMapping("/{id}/inventory")
    public String updateInventory(@PathVariable String id) {
        return "Inventory updated for product: " + id;
    }
    
    @DeleteMapping("/{id}")
    public String deleteProduct(@PathVariable String id) {
        return "Product deleted: " + id;
    }
    
    @DeleteMapping("/{id}/reviews/{reviewId}")
    public String deleteProductReview(@PathVariable String id, @PathVariable String reviewId) {
        return "Review deleted for product: " + id;
    }
}