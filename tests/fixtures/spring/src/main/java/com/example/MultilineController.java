package com.example;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/multiline")
public class MultilineController {

    // Test case 1: Simple multiline @GetMapping
    @GetMapping(
        "/users/{id}"
    )
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = new User(id, "John Doe", "john@example.com");
        return ResponseEntity.ok(user);
    }

    // Test case 2: Complex multiline @PostMapping with multiple parameters
    @PostMapping(
        value = "/users",
        consumes = "application/json",
        produces = "application/json"
    )
    public ResponseEntity<User> createUser(
        @RequestBody UserCreateRequest request,
        @RequestHeader("Authorization") String auth
    ) {
        User user = new User(1L, request.getName(), request.getEmail());
        return ResponseEntity.status(HttpStatus.CREATED).body(user);
    }

    // Test case 3: Multiline @PutMapping with path variables and request body
    @PutMapping(
        value = "/users/{id}",
        consumes = "application/json",
        produces = "application/json"
    )
    public ResponseEntity<User> updateUser(
        @PathVariable Long id,
        @RequestBody UserUpdateRequest request
    ) {
        User user = new User(id, request.getName(), request.getEmail());
        return ResponseEntity.ok(user);
    }

    // Test case 4: Complex multiline @DeleteMapping with multiple headers
    @DeleteMapping(
        value = "/users/{id}",
        headers = {
            "X-API-Version=v1",
            "Accept=application/json"
        }
    )
    public ResponseEntity<Void> deleteUser(
        @PathVariable Long id,
        @RequestHeader("Authorization") String auth
    ) {
        return ResponseEntity.noContent().build();
    }

    // Test case 5: Multiline @PatchMapping with query parameters
    @PatchMapping(
        value = "/users/{id}/status",
        produces = "application/json"
    )
    public ResponseEntity<Map<String, Object>> updateUserStatus(
        @PathVariable Long id,
        @RequestParam String status,
        @RequestParam(required = false) String reason
    ) {
        Map<String, Object> response = Map.of(
            "id", id,
            "status", status,
            "reason", reason != null ? reason : "No reason provided"
        );
        return ResponseEntity.ok(response);
    }

    // Test case 6: Complex multiline @RequestMapping with method specification
    @RequestMapping(
        value = "/users/{id}/posts",
        method = RequestMethod.GET,
        produces = "application/json",
        params = {"limit", "offset"}
    )
    public ResponseEntity<List<Post>> getUserPosts(
        @PathVariable Long id,
        @RequestParam int limit,
        @RequestParam int offset
    ) {
        List<Post> posts = List.of(
            new Post(1L, "Sample Post", "Content")
        );
        return ResponseEntity.ok(posts);
    }

    // Test case 7: Multiline with multiple HTTP methods
    @RequestMapping(
        value = "/users/{id}/profile",
        method = {RequestMethod.GET, RequestMethod.POST},
        produces = "application/json"
    )
    public ResponseEntity<UserProfile> handleUserProfile(
        @PathVariable Long id,
        @RequestBody(required = false) UserProfileRequest request
    ) {
        UserProfile profile = new UserProfile(id, "Default Profile");
        return ResponseEntity.ok(profile);
    }

    // Test case 8: Very complex multiline annotation
    @PostMapping(
        value = "/users/{userId}/posts/{postId}/comments",
        consumes = "application/json",
        produces = "application/json",
        headers = "X-API-Version=v1"
    )
    public ResponseEntity<Comment> createComment(
        @PathVariable Long userId,
        @PathVariable Long postId,
        @RequestBody CommentCreateRequest request,
        @RequestHeader("Authorization") String auth,
        @RequestParam(required = false) String notifyAuthor
    ) {
        Comment comment = new Comment(1L, request.getContent(), userId, postId);
        return ResponseEntity.status(HttpStatus.CREATED).body(comment);
    }

    // Supporting classes
    public static class User {
        private Long id;
        private String name;
        private String email;

        public User(Long id, String name, String email) {
            this.id = id;
            this.name = name;
            this.email = email;
        }

        // getters and setters omitted for brevity
    }

    public static class UserCreateRequest {
        private String name;
        private String email;

        public String getName() { return name; }
        public String getEmail() { return email; }
    }

    public static class UserUpdateRequest {
        private String name;
        private String email;

        public String getName() { return name; }
        public String getEmail() { return email; }
    }

    public static class UserProfile {
        private Long userId;
        private String description;

        public UserProfile(Long userId, String description) {
            this.userId = userId;
            this.description = description;
        }
    }

    public static class UserProfileRequest {
        private String description;

        public String getDescription() { return description; }
    }

    public static class Post {
        private Long id;
        private String title;
        private String content;

        public Post(Long id, String title, String content) {
            this.id = id;
            this.title = title;
            this.content = content;
        }
    }

    public static class Comment {
        private Long id;
        private String content;
        private Long userId;
        private Long postId;

        public Comment(Long id, String content, Long userId, Long postId) {
            this.id = id;
            this.content = content;
            this.userId = userId;
            this.postId = postId;
        }
    }

    public static class CommentCreateRequest {
        private String content;

        public String getContent() { return content; }
    }
}
