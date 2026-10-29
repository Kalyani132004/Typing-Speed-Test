<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<html>
<head>
    <title>Typing Speed Test Records</title>
    <style>
        body {
            font-family: Arial;
            background: #eeefed;
            color: #333;
            margin: 30px;
        }
        .box {
            background: white;
            padding: 20px;
            border: 1px solid #ccc;
        }
        h2 {
            color: #405965;
            text-align: center;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ccc;
            padding: 9px;
            text-align: center;
        }
        th {
            background: #dce3e5;
        }
        button {
            background: #526e7a;
            color: white;
            padding: 6px 10px;
            border: none;
            cursor: pointer;
        }
        input {
            padding: 7px;
        }
    </style>
</head>

<body>
    <div class="box">
        <h2>Typing Speed Test Records</h2>

        <%
            String url = "jdbc:mysql://localhost:3306/typing_db";
            String user = "root";
            String pass = "Kalyani@1310";

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");

                try (Connection con =
                        DriverManager.getConnection(url, user, pass)) {

                    String action = request.getParameter("action");

                    if ("delete".equals(action)) {
                        int id = Integer.parseInt(request.getParameter("id"));

                        try (PreparedStatement ps = con.prepareStatement(
                                "DELETE FROM typing_test WHERE id = ?")) {
                            ps.setInt(1, id);
                            ps.executeUpdate();
                        }

                        response.sendRedirect("result.jsp");
                        return;
                    }


                    if ("POST".equalsIgnoreCase(request.getMethod())) {
                        String student = request.getParameter("student");
                        int words = Integer.parseInt(
                            request.getParameter("words")
                        );
                        int minutes = Integer.parseInt(
                            request.getParameter("minutes")
                        );

                        if (student == null || student.trim().isEmpty() || student.trim().length() > 40 || words < 0 || minutes <= 0) {
                            throw new Exception(
                                "Minutes must be more than 0."
                            );
                        }

                        PreparedStatement ps = con.prepareStatement("INSERT INTO typing_test(student, words, minutes) " + "VALUES (?, ?, ?)");

                        ps.setString(1, student.trim());
                        ps.setInt(2, words);
                        ps.setInt(3, minutes);
                        ps.executeUpdate();

                        response.sendRedirect("result.jsp");
                        return;
                    }

                    int total = 0;
                    double avg = 0;

                    String statsSql = "SELECT COUNT(*) AS total, " + "AVG(words * 1.0 / minutes) AS avg " + "FROM typing_test";

                    try (PreparedStatement ps = con.prepareStatement(statsSql); 
                    ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            total = rs.getInt("total");
                            avg = rs.getDouble("avg");
                        }
                    }

                    String fastest = "None";
                    double maxSpeed = 0;

                    String fastSql = "SELECT student, words, minutes " + "FROM typing_test " + "WHERE minutes > 0 " + "ORDER BY words * 1.0 / minutes DESC " + "LIMIT 1";

                    try (PreparedStatement ps = con.prepareStatement(fastSql);
                        ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) { 
                            fastest = rs.getString("student");
                            maxSpeed = (double) rs.getInt("words") / rs.getInt("minutes");
                        }
                    }
        %>
        <form method="get" action="result.jsp">
            <input type="text" name="search" placeholder="Search student name">
            <button type="submit">Search</button>
        </form>

        <table>
            <tr>
                <th>ID</th>
                <th>Student</th>
                <th>Words Typed</th>
                <th>Minutes</th>
                <th>Speed (WPM)</th>
                <th>Action</th>
            </tr>

            <%
                String search = request.getParameter("search");
                String sql = "SELECT * FROM typing_test";
                if (search != null && !search.trim().isEmpty()) { 
                    sql += " WHERE student LIKE ?";
                }

                sql += " ORDER BY id DESC";

                try (PreparedStatement ps = con.prepareStatement(sql)) {

                    if (search != null && !search.trim().isEmpty()) {
                        ps.setString(1, "%" + search.trim() + "%");
                    }

                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int id = rs.getInt("id");
                            String name = rs.getString("student");
                            int words = rs.getInt("words");
                            int minutes = rs.getInt("minutes");
            %>
            <tr>
                <td><%= id %></td>
                <td><%= name %></td>
                <td><%= words %></td>
                <td><%= minutes %></td>
                <td>
                    <%= String.format("%.2f",
                        (double) words / minutes) %>
                </td>
                <td>
                    <form action="result.jsp" method="post">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<%= id %>">
                        <button type="submit">Delete</button>
                    </form>
                </td>
            </tr>

            <%
                        }
                    }
                }
            %>
        </table>
        <br>
        <a href="index.html">Add New Record</a>
        <%
                }
            } catch (Exception e) {
        %>
        <p style="color:red;">
            Error: <%= e.getMessage() %>
        </p>
        <%
            }
        %>
    </div>
</body>
</html>
