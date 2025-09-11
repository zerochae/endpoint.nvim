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
    
    @GetMapping("/{id}/profile")
    public String getUserProfile(@PathVariable String id) {
        return "User profile: " + id;
    }
    
    @GetMapping("/{id}/settings")
    public String getUserSettings(@PathVariable String id) {
        return "User settings: " + id;
    }
    
    @GetMapping("/search")
    public String searchUsers(@RequestParam String query) {
        return "Search results for: " + query;
    }
    
    @PostMapping
    public String createUser() {
        return "User created";
    }
    
    @PostMapping("/register")
    public String registerUser() {
        return "User registered";
    }
    
    @PostMapping("/{id}/avatar")
    public String uploadAvatar(@PathVariable String id) {
        return "Avatar uploaded for user: " + id;
    }
    
    @PutMapping("/{id}")
    public String updateUser(@PathVariable String id) {
        return "User updated: " + id;
    }
    
    @PutMapping("/{id}/profile")
    public String updateUserProfile(@PathVariable String id) {
        return "Profile updated: " + id;
    }
    
    @PatchMapping("/{id}/status")
    public String updateUserStatus(@PathVariable String id) {
        return "Status updated: " + id;
    }
    
    @DeleteMapping("/{id}")
    public String deleteUser(@PathVariable String id) {
        return "User deleted: " + id;
    }
    
    @DeleteMapping("/{id}/avatar")
    public String deleteAvatar(@PathVariable String id) {
        return "Avatar deleted for user: " + id;
    }
}