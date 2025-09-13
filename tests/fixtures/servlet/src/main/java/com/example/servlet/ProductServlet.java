package com.example.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Product servlet with different URL patterns
 */
@WebServlet(value = "/products")
public class ProductServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        out.println("<html><body>");
        out.println("<h1>Product List</h1>");
        out.println("<ul>");
        out.println("<li>Laptop - $999</li>");
        out.println("<li>Mouse - $25</li>");
        out.println("<li>Keyboard - $75</li>");
        out.println("</ul>");
        out.println("</body></html>");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String name = request.getParameter("name");
        String price = request.getParameter("price");
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        if (name == null || price == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.println("{\"error\": \"Name and price are required\"}");
        } else {
            out.println("{\"message\": \"Product created\", \"name\": \"" + name + "\", \"price\": \"" + price + "\"}");
        }
    }
}