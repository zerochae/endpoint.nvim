package com.example;

import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/{userId}/orders")
public class TestController {

    @GetMapping
    public String main(@PathVariable("userId") Long userId, Model model) {
        return "test/main";
    }

    @PostMapping("/create")
    public String createOrder() {
        return "test/create";
    }

    @GetMapping("/status")
    public String getOrderStatus() {
        return "test/status";
    }
}
