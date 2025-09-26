package com.example.user;

import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        users.add(new User(1L, "john@example.com", "John Doe"));
        users.add(new User(2L, "jane@example.com", "Jane Smith"));
        return users;
    }

    @GetMapping("/{id}")
    public User getUserById(@PathVariable Long id) {
        return new User(id, "user" + id + "@example.com", "User " + id);
    }

    @PostMapping
    public User createUser(@RequestBody User user) {
        user.setId(System.currentTimeMillis());
        return user;
    }

    @PutMapping("/{id}")
    public User updateUser(@PathVariable Long id, @RequestBody User user) {
        user.setId(id);
        return user;
    }

    @DeleteMapping("/{id}")
    public void deleteUser(@PathVariable Long id) {
        // Delete logic
    }

    @GetMapping("/search")
    public List<User> searchUsers(@RequestParam String query) {
        List<User> users = new ArrayList<>();
        users.add(new User(1L, query + "@example.com", "Found User"));
        return users;
    }
}