package com.cinebooking.servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;


@WebServlet("/BookingServlet")
public class BookingServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Theater database mapped by location
    private static final Map<String, List<Map<String, Object>>> THEATERS_DB = new HashMap<>();

    static {
        // Warangal
        THEATERS_DB.put("Warangal", Arrays.asList(
            createTheater("101", "Amrutha Cinema: Hanumakonda", "11:00 AM", "02:30 PM", "06:00 PM", "09:15 PM"),
            createTheater("102", "PVR: Warangal, Maddox Mall", "10:30 AM", "01:45 PM", "04:50 PM", "07:25 PM", "11:00 PM"),
            createTheater("103", "Asian Sridevi Multiplex", "11:15 AM", "02:45 PM", "04:35 PM", "07:40 PM"),
            createTheater("104", "Asian Vijaya Cinema Hall", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("105", "Ashoka A Plex Cinema Hall", "11:15 AM", "02:30 PM", "06:30 PM", "09:45 PM"),
            createTheater("106", "Vijaya Theater", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("107", "Venkatrama Cinema Hall", "11:15 AM", "02:30 PM", "06:30 PM", "09:45 PM")
        ));

        // Hyderabad
        THEATERS_DB.put("Hyderabad", Arrays.asList(
            createTheater("201", "Prasads Multiplex", "10:00 AM", "01:30 PM", "04:45 PM", "08:00 PM", "11:15 PM"),
            createTheater("202", "Indra Padmavati Cinema (Kachiguda)", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM"),
            createTheater("203", "INOX GVK One (Banjara Hills)", "10:45 AM", "02:00 PM", "05:15 PM", "08:30 PM", "11:30 PM"),
            createTheater("204", "Sudarshan 35MM 4k Laser", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM"),
            createTheater("205", "PVR Central Mall (Panjagutta)", "11:00 AM", "02:15 PM", "05:30 PM", "08:45 PM"),
            createTheater("206", "Santosh Theatre (Ibrahimpatnam)", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM"),
            createTheater("207", "Miraj Shalini Shivani", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("208", "Miraj Raghavendra (Malkajgiri)", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM"),
            createTheater("209", "Cinepolis CCPL Mall", "10:00 AM", "01:15 PM", "04:30 PM", "07:45 PM", "11:00 PM")
        ));

        // Jangaon
        THEATERS_DB.put("Jangaon", Arrays.asList(
            createTheater("301", "Svc Devi Theatre", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("302", "Svc Krishna Kala Mandir", "11:15 AM", "02:30 PM", "06:30 PM", "09:45 PM"),
            createTheater("303", "Swarna Kala Mandir", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM")
        ));

        // Karimnagar
        THEATERS_DB.put("Karimnagar", Arrays.asList(
            createTheater("401", "Saikrishna theater", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM"),
            createTheater("402", "Sri Tirumala Theatre", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("403", "Prathima Multiplex", "10:30 AM", "01:45 PM", "05:00 PM", "08:15 PM", "11:15 PM")
        ));

        // Siddipet
        THEATERS_DB.put("Siddipet", Arrays.asList(
            createTheater("501", "Asian Srinivasa Cinema Hall", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM"),
            createTheater("502", "Asian Balaji Cinema Hall", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("503", "Balaji Theater", "11:15 AM", "02:30 PM", "06:15 PM", "09:30 PM")
        ));

        // Khammam
        THEATERS_DB.put("Khammam", Arrays.asList(
            createTheater("601", "The Spotlight Theatre", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM"),
            createTheater("602", "Asian Srinivasa Cinema Hall", "11:15 AM", "02:30 PM", "06:30 PM", "09:45 PM"),
            createTheater("603", "Sri Tirumala Cinema Hall", "11:00 AM", "02:15 PM", "06:15 PM", "09:30 PM")
        ));
    }

    private static Map<String, Object> createTheater(String id, String name, String... times) {
        Map<String, Object> t = new HashMap<>();
        t.put("id", id);
        t.put("name", name);
        t.put("times", Arrays.asList(times));
        return t;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        
        if ("getTheaters".equals(action)) {
            String location = request.getParameter("location");
            List<Map<String, Object>> theaters = THEATERS_DB.getOrDefault(location, new ArrayList<>());
            
            response.setContentType("application/json");
            PrintWriter out = response.getWriter();
            out.print(serializeToJson(theaters));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String seatCountStr = request.getParameter("seatCount");
        String includeFeeStr = request.getParameter("includeFee");
        
        int seatCount = (seatCountStr != null) ? Integer.parseInt(seatCountStr) : 0;
        boolean includeFee = "true".equals(includeFeeStr);
        
        double baseFarePerSeat = 250.0;
        double subTotal = seatCount * baseFarePerSeat;
        double gstAmount = subTotal * 0.18; // 18% GST
        
        // NEW: 2% dynamic convenience fee logic
        double convenienceFee = includeFee ? (subTotal * 0.02) : 0.0;
        
        double grandTotal = subTotal + gstAmount + convenienceFee;

        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        out.print("{\"total\": " + grandTotal + ", \"gst\": " + gstAmount + ", \"fee\": " + convenienceFee + "}");
    }


    private String serializeToJson(List<Map<String, Object>> list) {
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            Map<String, Object> t = list.get(i);
            json.append("{");
            json.append("\"id\":\"").append(t.get("id")).append("\",");
            json.append("\"name\":\"").append(t.get("name")).append("\",");
            json.append("\"times\":[");
            List<String> times = (List<String>) t.get("times");
            for (int j = 0; j < times.size(); j++) {
                json.append("\"").append(times.get(j)).append("\"").append(j < times.size() - 1 ? "," : "");
            }
            json.append("]}").append(i < list.size() - 1 ? "," : "");
        }
        json.append("]");
        return json.toString();
    }
}