package com.cinebooking.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import com.cinebooking.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/api/register")
public class RegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // 1. Get parameters from frontend
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String phone = request.getParameter("phone");

        // 2. Validation
        if (name == null || email == null || password == null) {
            response.setStatus(400);
            out.print("{\"status\":\"error\", \"message\":\"All fields are required\"}");
            return;
        }

        // 3. JDBC Logic to Save (INSERT)
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "INSERT INTO users (full_name, email, password, phone) VALUES (?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, name);
            pstmt.setString(2, email);
            pstmt.setString(3, password); // Note: Plain text for project demo
            pstmt.setString(4, phone);

            int rows = pstmt.executeUpdate();

            if (rows > 0) {
                out.print("{\"status\":\"success\", \"message\":\"User registered successfully\"}");
            } else {
                out.print("{\"status\":\"error\", \"message\":\"Registration failed\"}");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(500);
            // Handle duplicate email error
            if (e.getMessage().contains("Duplicate entry")) {
                out.print("{\"status\":\"error\", \"message\":\"Email already exists\"}");
            } else {
                out.print("{\"status\":\"error\", \"message\":\"Database error\"}");
            }
        }
    }
}