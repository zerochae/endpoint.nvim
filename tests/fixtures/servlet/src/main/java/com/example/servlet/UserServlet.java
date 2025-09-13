package com.example.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Modern servlet using annotations (Servlet 3.0+)
 * Handles user-related operations
 */
@WebServlet(urlPatterns = {"/users", "/users/*"}, name = "UserServlet")
public class UserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private List<User> users = new ArrayList<>();
    
    @Override
    public void init() throws ServletException {
        // Initialize with sample data
        users.add(new User(1, "John Doe", "john@example.com"));
        users.add(new User(2, "Jane Smith", "jane@example.com"));
        users.add(new User(3, "Bob Johnson", "bob@example.com"));
    }
    
    /**
     * Handle GET requests - retrieve users
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        PrintWriter out = response.getWriter();
        String pathInfo = request.getPathInfo();
        
        if (pathInfo == null || pathInfo.equals("/")) {
            // Get all users
            out.println(convertUsersToJson(users));
        } else {
            // Get specific user by ID
            try {
                int userId = Integer.parseInt(pathInfo.substring(1));
                User user = findUserById(userId);
                if (user != null) {
                    out.println(convertUserToJson(user));
                } else {
                    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    out.println("{\"error\": \"User not found\"}");
                }
            } catch (NumberFormatException e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.println("{\"error\": \"Invalid user ID\"}");
            }
        }
    }
    
    /**
     * Handle POST requests - create new user
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        
        if (name == null || email == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().println("{\"error\": \"Name and email are required\"}");
            return;
        }
        
        int newId = users.size() + 1;
        User newUser = new User(newId, name, email);
        users.add(newUser);
        
        response.setStatus(HttpServletResponse.SC_CREATED);
        response.getWriter().println(convertUserToJson(newUser));
    }
    
    /**
     * Handle PUT requests - update user
     */
    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String pathInfo = request.getPathInfo();
        if (pathInfo == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().println("{\"error\": \"User ID is required\"}");
            return;
        }
        
        try {
            int userId = Integer.parseInt(pathInfo.substring(1));
            User user = findUserById(userId);
            
            if (user == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().println("{\"error\": \"User not found\"}");
                return;
            }
            
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            
            if (name != null) user.setName(name);
            if (email != null) user.setEmail(email);
            
            response.getWriter().println(convertUserToJson(user));
            
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().println("{\"error\": \"Invalid user ID\"}");
        }
    }
    
    /**
     * Handle DELETE requests - delete user
     */
    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String pathInfo = request.getPathInfo();
        if (pathInfo == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().println("{\"error\": \"User ID is required\"}");
            return;
        }
        
        try {
            int userId = Integer.parseInt(pathInfo.substring(1));
            User user = findUserById(userId);
            
            if (user == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().println("{\"error\": \"User not found\"}");
                return;
            }
            
            users.remove(user);
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);
            
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().println("{\"error\": \"Invalid user ID\"}");
        }
    }
    
    // Helper methods
    private User findUserById(int id) {
        return users.stream()
                .filter(user -> user.getId() == id)
                .findFirst()
                .orElse(null);
    }
    
    private String convertUsersToJson(List<User> users) {
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < users.size(); i++) {
            json.append(convertUserToJson(users.get(i)));
            if (i < users.size() - 1) {
                json.append(",");
            }
        }
        json.append("]");
        return json.toString();
    }
    
    private String convertUserToJson(User user) {
        return String.format("{\"id\":%d,\"name\":\"%s\",\"email\":\"%s\"}", 
                user.getId(), user.getName(), user.getEmail());
    }
    
    // Simple User class
    private static class User {
        private int id;
        private String name;
        private String email;
        
        public User(int id, String name, String email) {
            this.id = id;
            this.name = name;
            this.email = email;
        }
        
        // Getters and setters
        public int getId() { return id; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }
}