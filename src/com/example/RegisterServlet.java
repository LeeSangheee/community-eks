// RegisterServlet.java
package com.example;

import javax.naming.Context;           // <-- javax
import javax.naming.InitialContext;    // <-- javax
import javax.sql.DataSource;           // <-- javax

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.security.MessageDigest;
import java.sql.*;

public class RegisterServlet extends HttpServlet {
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
        String name     = req.getParameter("name");
        String email    = req.getParameter("email");
        String password = req.getParameter("password");
        String password2= req.getParameter("password2");

        if (username == null || password == null || password2 == null ||
            username.isEmpty() || password.isEmpty() || !password.equals(password2)) {
            req.setAttribute("error", "입력값 오류(비밀번호 불일치 포함)");
            req.getRequestDispatcher("/join.jsp").forward(req, resp);
       		 return;
        }

        String hashed = sha256(password);

        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO users(username, password_hash, name, email) VALUES(?,?,?,?)")) {
            ps.setString(1, username);
            ps.setString(2, hashed);
            ps.setString(3, (name  == null || name.isEmpty())  ? null : name);
            ps.setString(4, (email == null || email.isEmpty()) ? null : email);
            ps.executeUpdate();
        } catch (SQLIntegrityConstraintViolationException dup) {
            req.setAttribute("error", "이미 존재하는 아이디/이메일임");
            req.getRequestDispatcher("/join.jsp").forward(req, resp);
            return;
        } catch (SQLException e) {
            throw new ServletException(e);
        }

        resp.sendRedirect("/index.jsp");
    }
}
