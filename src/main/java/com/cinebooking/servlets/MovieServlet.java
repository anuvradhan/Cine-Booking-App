package com.cinebooking.servlets;

import com.cinebooking.util.DBConnection;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/api/movies")
public class MovieServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // 1. Set response headers for JSON
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // 2. Get the search parameter from the URL (e.g., ?search=biker)
        String searchQuery = request.getParameter("search");
        
        // 3. JDBC Logic
        try (Connection conn = DBConnection.getConnection()) {
            String sql = "SELECT * FROM movies";
            
            // Add filtering if a search query exists
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                sql += " WHERE title LIKE ? OR genre LIKE ? OR director LIKE ?";
            }

            PreparedStatement pstmt = conn.prepareStatement(sql);
            
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                String pattern = "%" + searchQuery + "%";
                pstmt.setString(1, pattern);
                pstmt.setString(2, pattern);
                pstmt.setString(3, pattern);
            }

            ResultSet rs = pstmt.executeQuery();

            // 4. Build JSON manually (Pragmatic for student projects)
            StringBuilder json = new StringBuilder("[");
            while (rs.next()) {
                json.append("{");
                json.append("\"id\":").append(rs.getInt("id")).append(",");
                json.append("\"title\":\"").append(escapeJson(rs.getString("title"))).append("\",");
                json.append("\"genre\":\"").append(escapeJson(rs.getString("genre"))).append("\",");
                json.append("\"director\":\"").append(escapeJson(rs.getString("director"))).append("\",");
                json.append("\"rating\":").append(rs.getDouble("rating")).append(",");
                json.append("\"votes\":\"").append(escapeJson(rs.getString("votes"))).append("\",");
                json.append("\"image\":\"").append(escapeJson(rs.getString("image_url"))).append("\"");
                json.append("},");
            }
            
            // Remove last comma if data exists
            if (json.length() > 1) {
                json.setLength(json.length() - 1);
            }
            json.append("]");

            out.print(json.toString());
            out.flush();

        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Database connection failed\"}");
        }
    }

    // Helper to prevent broken JSON from special characters
    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\"", "\\\"").replace("\n", "\\n");
    }
}