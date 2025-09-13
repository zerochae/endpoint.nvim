package com.example.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Legacy servlet configured via web.xml (pre-annotation era)
 * This servlet is mapped to /legacy/users in web.xml
 */
public class LegacyUserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    public void init() throws ServletException {
        String configFile = getInitParameter("configFile");
        System.out.println("LegacyUserServlet initialized with config: " + configFile);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        out.println("<html><body>");
        out.println("<h2>Legacy User Management</h2>");
        out.println("<p>This is a legacy servlet configured via web.xml</p>");
        out.println("<p>Path: " + request.getRequestURI() + "</p>");
        out.println("<p>Servlet Name: " + getServletName() + "</p>");
        out.println("</body></html>");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        response.setContentType("text/plain");
        
        PrintWriter out = response.getWriter();
        out.println("Legacy POST action: " + (action != null ? action : "none"));
    }
}