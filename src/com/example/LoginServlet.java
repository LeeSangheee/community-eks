// LoginServlet.java
package com.example;

import javax.naming.Context;           // <-- javax
import javax.naming.InitialContext;    // <-- javax
import javax.sql.DataSource;           // <-- javax

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.security.MessageDigest;
import java.sql.*;

public class LoginServlet extends HttpServlet {
    private DataSource ds;

    @Override
    public void init() throws ServletException {
        try {
            Context init = new InitialContext();
            Context env  = (Context) init.lookup("java:/comp/env");
            ds = (DataSource) env.lookup("jdbc/community");
        } catch (Exception e) {
            throw new ServletException("DataSource lookup 실패", e);
        }
    }

    private String sha256(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] d = md.digest(s.getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (byte b : d) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) { return s; }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String username = req.getParameter("username");
        String password = req.getParameter("password");
        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            req.setAttribute("loginError", "아이디/비밀번호 입력");
            req.getRequestDispatcher("/index.jsp").forward(req, resp);
            return;
        }

        String hashed = sha256(password);

        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT id, name, status FROM users WHERE username=? AND password_hash=?")) {
            ps.setString(1, username);
            ps.setString(2, hashed);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    if ("BLOCKED".equals(rs.getString("status"))) {
                        req.setAttribute("loginError", "차단된 계정임");
                        req.getRequestDispatcher("/index.jsp").forward(req, resp);
                        return;
                    }
                    long userId = rs.getLong("id");
                    String name = rs.getString("name");

                    HttpSession session = req.getSession(true);
                    session.setAttribute("userId", userId);
                    session.setAttribute("username", username);
                    session.setAttribute("name", (name != null && !name.isEmpty()) ? name : username);

                    resp.sendRedirect("/home.jsp");
                } else {
                    req.setAttribute("loginError", "아이디 또는 비밀번호 불일치");
                    req.getRequestDispatcher("/index.jsp").forward(req, resp);
                }
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }
}
