package com.example;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import com.fasterxml.jackson.databind.ObjectMapper;

// Test case 1: Simple multiline @WebServlet annotation
@WebServlet(
    urlPatterns = "/users/*"
)
public class MultilineServlet extends HttpServlet {
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Test case 2: Multiline doGet method
    @Override
    protected void doGet(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();
        PrintWriter out = response.getWriter();

        if (pathInfo == null || pathInfo.equals("/")) {
            // List all users
            String usersJson = objectMapper.writeValueAsString(
                new User[]{
                    new User(1, "John Doe", "john@example.com"),
                    new User(2, "Jane Smith", "jane@example.com")
                }
            );
            out.print(usersJson);
        } else {
            // Get specific user
            String userId = pathInfo.substring(1);
            User user = new User(
                Integer.parseInt(userId),
                "User " + userId,
                "user" + userId + "@example.com"
            );
            out.print(objectMapper.writeValueAsString(user));
        }
    }

    // Test case 3: Complex multiline doPost method
    @Override
    protected void doPost(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try {
            UserCreateRequest userRequest = objectMapper.readValue(
                request.getReader(),
                UserCreateRequest.class
            );

            User newUser = new User(
                generateUserId(),
                userRequest.getName(),
                userRequest.getEmail()
            );

            response.setStatus(HttpServletResponse.SC_CREATED);
            PrintWriter out = response.getWriter();
            out.print(objectMapper.writeValueAsString(newUser));

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            PrintWriter out = response.getWriter();
            out.print("{\"error\": \"Invalid request: " + e.getMessage() + "\"}");
        }
    }

    // Test case 4: Multiline doPut method with complex logic
    @Override
    protected void doPut(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            String userId = pathInfo.substring(1);
            UserUpdateRequest updateRequest = objectMapper.readValue(
                request.getReader(),
                UserUpdateRequest.class
            );

            User updatedUser = new User(
                Integer.parseInt(userId),
                updateRequest.getName(),
                updateRequest.getEmail()
            );

            PrintWriter out = response.getWriter();
            out.print(objectMapper.writeValueAsString(updatedUser));

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            PrintWriter out = response.getWriter();
            out.print("{\"error\": \"Update failed: " + e.getMessage() + "\"}");
        }
    }

    // Test case 5: Multiline doDelete method
    @Override
    protected void doDelete(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        String pathInfo = request.getPathInfo();
        String authHeader = request.getHeader("Authorization");

        if (pathInfo == null || pathInfo.equals("/")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        try {
            String userId = pathInfo.substring(1);
            // Simulate deletion logic
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("application/json");
            PrintWriter out = response.getWriter();
            out.print("{\"error\": \"Deletion failed: " + e.getMessage() + "\"}");
        }
    }

    // Test case 6: Custom multiline doPatch method (not standard but some containers support it)
    protected void doPatch(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();
        if (pathInfo == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            String[] pathParts = pathInfo.split("/");
            if (pathParts.length >= 3 && "status".equals(pathParts[2])) {
                String userId = pathParts[1];
                String status = request.getParameter("status");
                String reason = request.getParameter("reason");

                StatusResponse statusResponse = new StatusResponse(
                    Integer.parseInt(userId),
                    status,
                    reason != null ? reason : "No reason provided"
                );

                PrintWriter out = response.getWriter();
                out.print(objectMapper.writeValueAsString(statusResponse));
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            }

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            PrintWriter out = response.getWriter();
            out.print("{\"error\": \"Status update failed: " + e.getMessage() + "\"}");
        }
    }

    private int generateUserId() {
        return (int) (Math.random() * 10000);
    }

    // Supporting classes
    public static class User {
        private int id;
        private String name;
        private String email;

        public User() {}

        public User(int id, String name, String email) {
            this.id = id;
            this.name = name;
            this.email = email;
        }

        // Getters and setters
        public int getId() { return id; }
        public void setId(int id) { this.id = id; }

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class UserCreateRequest {
        private String name;
        private String email;

        public UserCreateRequest() {}

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class UserUpdateRequest {
        private String name;
        private String email;

        public UserUpdateRequest() {}

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class StatusResponse {
        private int id;
        private String status;
        private String reason;

        public StatusResponse() {}

        public StatusResponse(int id, String status, String reason) {
            this.id = id;
            this.status = status;
            this.reason = reason;
        }

        public int getId() { return id; }
        public void setId(int id) { this.id = id; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }
}

// Test case 7: Additional servlet with complex multiline annotations
@WebServlet(
    name = "ComplexServlet",
    urlPatterns = {
        "/api/v1/posts/*",
        "/api/v1/comments/*"
    },
    initParams = {
        @javax.servlet.annotation.WebInitParam(
            name = "encoding",
            value = "UTF-8"
        )
    }
)
class ComplexMultilineServlet extends HttpServlet {

    @Override
    protected void doGet(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();
        PrintWriter out = response.getWriter();

        if (pathInfo.startsWith("/posts")) {
            out.print("{\"type\": \"posts\", \"data\": []}");
        } else if (pathInfo.startsWith("/comments")) {
            out.print("{\"type\": \"comments\", \"data\": []}");
        } else {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            out.print("{\"error\": \"Resource not found\"}");
        }
    }

    @Override
    protected void doPost(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();
        String contentType = request.getContentType();

        if (contentType == null || !contentType.startsWith("application/json")) {
            response.setStatus(HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE);
            return;
        }

        response.setStatus(HttpServletResponse.SC_CREATED);
        PrintWriter out = response.getWriter();
        out.print("{\"message\": \"Resource created successfully\"}");
    }
}