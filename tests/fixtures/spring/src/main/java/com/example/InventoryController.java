package com.example;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/inventory")
public class InventoryController {
    
    // Various @GetMapping patterns
    @GetMapping
    public ResponseEntity<String> getAllInventory(@RequestParam(required = false) String category,
                                                @RequestParam(required = false) String status) {
        return ResponseEntity.ok("All inventory (category: " + category + ", status: " + status + ")");
    }
    
    @GetMapping("/items")
    public ResponseEntity<String> getItems() {
        return ResponseEntity.ok("All items");
    }
    
    @GetMapping(value = "/categories")
    public ResponseEntity<String> getCategories() {
        return ResponseEntity.ok("All categories");
    }
    
    @GetMapping(path = "/suppliers")
    public ResponseEntity<String> getSuppliers() {
        return ResponseEntity.ok("All suppliers");
    }
    
    @GetMapping("/items/{id}")
    public ResponseEntity<String> getItem(@PathVariable Long id) {
        return ResponseEntity.ok("Item #" + id);
    }
    
    @GetMapping(value = "/items/{id}/details")
    public ResponseEntity<String> getItemDetails(@PathVariable Long id) {
        return ResponseEntity.ok("Details for item #" + id);
    }
    
    @GetMapping(path = "/items/{id}/stock")
    public ResponseEntity<String> getItemStock(@PathVariable Long id) {
        return ResponseEntity.ok("Stock for item #" + id);
    }
    
    // RequestMapping with GET method
    @RequestMapping(value = "/items/{id}/history", method = RequestMethod.GET)
    public ResponseEntity<String> getItemHistory(@PathVariable Long id) {
        return ResponseEntity.ok("History for item #" + id);
    }
    
    @RequestMapping(path = "/low-stock", method = RequestMethod.GET)
    public ResponseEntity<String> getLowStockItems() {
        return ResponseEntity.ok("Low stock items");
    }
    
    @RequestMapping(value = "/reports/monthly", method = RequestMethod.GET)
    public ResponseEntity<String> getMonthlyReport(@RequestParam int month, @RequestParam int year) {
        return ResponseEntity.ok("Monthly report for " + month + "/" + year);
    }
    
    // Various @PostMapping patterns
    @PostMapping("/items")
    public ResponseEntity<String> createItem(@RequestBody Object itemDto) {
        return ResponseEntity.status(HttpStatus.CREATED).body("Item created");
    }
    
    @PostMapping(value = "/categories")
    public ResponseEntity<String> createCategory(@RequestBody Object categoryDto) {
        return ResponseEntity.status(HttpStatus.CREATED).body("Category created");
    }
    
    @PostMapping(path = "/suppliers")
    public ResponseEntity<String> createSupplier(@RequestBody Object supplierDto) {
        return ResponseEntity.status(HttpStatus.CREATED).body("Supplier created");
    }
    
    @PostMapping("/items/{id}/restock")
    public ResponseEntity<String> restockItem(@PathVariable Long id, @RequestBody Object restockDto) {
        return ResponseEntity.ok("Item #" + id + " restocked");
    }
    
    // RequestMapping with POST method
    @RequestMapping(value = "/items/bulk-import", method = RequestMethod.POST)
    public ResponseEntity<String> bulkImportItems(@RequestBody Object bulkItemsDto) {
        return ResponseEntity.status(HttpStatus.CREATED).body("Bulk items imported");
    }
    
    @RequestMapping(path = "/items/{id}/reserve", method = RequestMethod.POST)
    public ResponseEntity<String> reserveItem(@PathVariable Long id, @RequestBody Object reserveDto) {
        return ResponseEntity.ok("Item #" + id + " reserved");
    }
    
    // Various @PutMapping patterns
    @PutMapping("/items/{id}")
    public ResponseEntity<String> updateItem(@PathVariable Long id, @RequestBody Object updateDto) {
        return ResponseEntity.ok("Item #" + id + " updated");
    }
    
    @PutMapping(value = "/categories/{id}")
    public ResponseEntity<String> updateCategory(@PathVariable Long id, @RequestBody Object categoryDto) {
        return ResponseEntity.ok("Category #" + id + " updated");
    }
    
    @PutMapping(path = "/suppliers/{id}")
    public ResponseEntity<String> updateSupplier(@PathVariable Long id, @RequestBody Object supplierDto) {
        return ResponseEntity.ok("Supplier #" + id + " updated");
    }
    
    // RequestMapping with PUT method
    @RequestMapping(value = "/items/{id}/location", method = RequestMethod.PUT)
    public ResponseEntity<String> updateItemLocation(@PathVariable Long id, @RequestBody Object locationDto) {
        return ResponseEntity.ok("Location updated for item #" + id);
    }
    
    // Various @PatchMapping patterns
    @PatchMapping("/items/{id}/status")
    public ResponseEntity<String> updateItemStatus(@PathVariable Long id, @RequestBody Object statusDto) {
        return ResponseEntity.ok("Status updated for item #" + id);
    }
    
    @PatchMapping(value = "/items/{id}/price")
    public ResponseEntity<String> updateItemPrice(@PathVariable Long id, @RequestBody Object priceDto) {
        return ResponseEntity.ok("Price updated for item #" + id);
    }
    
    @PatchMapping(path = "/items/{id}/quantity")
    public ResponseEntity<String> adjustItemQuantity(@PathVariable Long id, @RequestBody Object quantityDto) {
        return ResponseEntity.ok("Quantity adjusted for item #" + id);
    }
    
    // RequestMapping with PATCH method
    @RequestMapping(value = "/items/{id}/discount", method = RequestMethod.PATCH)
    public ResponseEntity<String> applyDiscount(@PathVariable Long id, @RequestBody Object discountDto) {
        return ResponseEntity.ok("Discount applied to item #" + id);
    }
    
    // Various @DeleteMapping patterns
    @DeleteMapping("/items/{id}")
    public ResponseEntity<Void> deleteItem(@PathVariable Long id) {
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping(value = "/categories/{id}")
    public ResponseEntity<String> deleteCategory(@PathVariable Long id) {
        return ResponseEntity.ok("Category #" + id + " deleted");
    }
    
    @DeleteMapping(path = "/suppliers/{id}")
    public ResponseEntity<String> deleteSupplier(@PathVariable Long id) {
        return ResponseEntity.ok("Supplier #" + id + " deleted");
    }
    
    @DeleteMapping("/items/{id}/reservations")
    public ResponseEntity<String> clearReservations(@PathVariable Long id) {
        return ResponseEntity.ok("Reservations cleared for item #" + id);
    }
    
    // RequestMapping with DELETE method
    @RequestMapping(value = "/expired-items", method = RequestMethod.DELETE)
    public ResponseEntity<String> removeExpiredItems() {
        return ResponseEntity.ok("Expired items removed");
    }
    
    @RequestMapping(path = "/cache", method = RequestMethod.DELETE)
    public ResponseEntity<String> clearInventoryCache() {
        return ResponseEntity.ok("Inventory cache cleared");
    }
}