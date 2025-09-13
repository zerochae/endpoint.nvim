package com.example.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * API servlet with multiple URL patterns and comprehensive HTTP method support
 */
@WebServlet(urlPatterns = {"/api/v1/*", "/api/health"})
public class ApiServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        String uri = request.getRequestURI();
        
        if (uri.endsWith("/health")) {
            out.println("{\"status\": \"healthy\", \"timestamp\": " + System.currentTimeMillis() + "}");
        } else {
            String pathInfo = request.getPathInfo();
            out.println("{\"method\": \"GET\", \"path\": \"" + 
                       (pathInfo != null ? pathInfo : "/") + "\", \"version\": \"v1\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        String pathInfo = request.getPathInfo();
        out.println("{\"method\": \"POST\", \"path\": \"" + 
                   (pathInfo != null ? pathInfo : "/") + "\", \"created\": true}");
    }

    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        String pathInfo = request.getPathInfo();
        out.println("{\"method\": \"PUT\", \"path\": \"" + 
                   (pathInfo != null ? pathInfo : "/") + "\", \"updated\": true}");
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        String pathInfo = request.getPathInfo();
        out.println("{\"method\": \"DELETE\", \"path\": \"" + 
                   (pathInfo != null ? pathInfo : "/") + "\", \"deleted\": true}");
    }
    
    @Override
    protected void doPatch(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        String pathInfo = request.getPathInfo();
        out.println("{\"method\": \"PATCH\", \"path\": \"" + 
                   (pathInfo != null ? pathInfo : "/") + "\", \"patched\": true}");
    }
}