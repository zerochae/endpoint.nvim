package com.example.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Admin servlet configured via web.xml with wildcard mapping
 * Mapped to /admin/* in web.xml
 */
public class AdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        String pathInfo = request.getPathInfo();
        
        out.println("<html><body>");
        out.println("<h1>Admin Panel</h1>");
        out.println("<p>Path Info: " + (pathInfo != null ? pathInfo : "none") + "</p>");
        out.println("<p>Full URI: " + request.getRequestURI() + "</p>");
        
        if (pathInfo != null) {
            if (pathInfo.startsWith("/users")) {
                out.println("<h2>User Management</h2>");
                out.println("<p>Managing users...</p>");
            } else if (pathInfo.startsWith("/settings")) {
                out.println("<h2>System Settings</h2>");
                out.println("<p>System configuration...</p>");
            } else {
                out.println("<h2>Admin Dashboard</h2>");
                out.println("<p>Welcome to admin panel</p>");
            }
        }
        
        out.println("</body></html>");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String pathInfo = request.getPathInfo();
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        out.println("{\"action\": \"admin_post\", \"path\": \"" + 
                   (pathInfo != null ? pathInfo : "root") + "\"}");
    }
    
    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        out.println("{\"action\": \"admin_update\", \"status\": \"success\"}");
    }
    
    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        out.println("{\"action\": \"admin_delete\", \"status\": \"success\"}");
    }
}