package com.example;

import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/{userId}/orders")
public class TestController {

    @GetMapping
    public String main(@PathVariable("userId") Long userId, Model model) {
        return "test/main";
    }

    @GetMapping("/{orderId}")
    public String getOrder(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Order details for user: " + userId + ", order: " + orderId;
    }

    @GetMapping("/{orderId}/items")
    public String getOrderItems(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Order items for order: " + orderId;
    }

    @GetMapping("/{orderId}/tracking")
    public String getOrderTracking(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Tracking info for order: " + orderId;
    }

    @PostMapping("/create")
    public String createOrder() {
        return "test/create";
    }

    @PostMapping("/{orderId}/cancel")
    public String cancelOrder(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Order cancelled: " + orderId;
    }

    @PostMapping("/{orderId}/items")
    public String addOrderItem(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Item added to order: " + orderId;
    }

    @PutMapping("/{orderId}")
    public String updateOrder(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Order updated: " + orderId;
    }

    @PutMapping("/{orderId}/shipping")
    public String updateShipping(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Shipping updated for order: " + orderId;
    }

    @PatchMapping("/{orderId}/status")
    public String updateOrderStatus(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Status updated for order: " + orderId;
    }

    @DeleteMapping("/{orderId}")
    public String deleteOrder(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId) {
        return "Order deleted: " + orderId;
    }

    @DeleteMapping("/{orderId}/items/{itemId}")
    public String removeOrderItem(@PathVariable("userId") Long userId, @PathVariable("orderId") Long orderId, @PathVariable("itemId") Long itemId) {
        return "Item removed from order: " + orderId;
    }

    @GetMapping("/status")
    public String getOrderStatus() {
        return "test/status";
    }
}
