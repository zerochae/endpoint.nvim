package com.example.order;

import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @GetMapping
    public List<Order> getAllOrders() {
        List<Order> orders = new ArrayList<>();
        orders.add(new Order(1L, 1L, "Electronics", 299.99));
        orders.add(new Order(2L, 2L, "Books", 49.99));
        return orders;
    }

    @GetMapping("/{id}")
    public Order getOrderById(@PathVariable Long id) {
        return new Order(id, 1L, "Product " + id, 99.99);
    }

    @PostMapping
    public Order createOrder(@RequestBody Order order) {
        order.setId(System.currentTimeMillis());
        return order;
    }

    @PutMapping("/{id}")
    public Order updateOrder(@PathVariable Long id, @RequestBody Order order) {
        order.setId(id);
        return order;
    }

    @DeleteMapping("/{id}")
    public void deleteOrder(@PathVariable Long id) {
        // Delete logic
    }

    @GetMapping("/user/{userId}")
    public List<Order> getOrdersByUserId(@PathVariable Long userId) {
        List<Order> orders = new ArrayList<>();
        orders.add(new Order(1L, userId, "User Order", 199.99));
        return orders;
    }

    @PostMapping("/{id}/cancel")
    public Order cancelOrder(@PathVariable Long id) {
        return new Order(id, 1L, "Cancelled Order", 0.0);
    }
}