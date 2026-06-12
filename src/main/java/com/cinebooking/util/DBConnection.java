package com.cinebooking.util;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {
    public static Connection getConnection() {
        Connection conn = null;
        try {
            // Use "com.mysql.jdbc.Driver" for older versions
            Class.forName("com.mysql.cj.jdbc.Driver"); 
            conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/cine_booking", "root", "12345678");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return conn;
    }
}