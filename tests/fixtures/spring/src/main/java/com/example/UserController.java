package com.example;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/users")
public class UserController {
    
    @GetMapping("/list")
    public String listUsers() {
        return "List of users";
    }
    
    @GetMapping("/{id}")
    public String getUser(@PathVariable String id) {
        return "User: " + id;
    }
    
    @PostMapping
    public String createUser() {
        return "User created";
    }
}