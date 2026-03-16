// BoardServlet.java
package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;
import java.io.IOException;
import java.util.List;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

@WebServlet(name="BoardServlet", urlPatterns={"/board"})
public class BoardServlet extends HttpServlet {
    private DataSource ds;
    private PostDao dao;

    @Override
    public void init() throws ServletException {
        try {
            Context init = new InitialContext();
            Context env = (Context) init.lookup("java:/comp/env");
            ds = (DataSource) env.lookup("jdbc/community");
            dao = new PostDao(ds);
        } catch (Exception e) {
            throw new ServletException("DataSource lookup 실패", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // ?name=free 또는 ?name=notice 또는 ?name=info...
        String name = req.getParameter("name");
        if (name == null || name.isEmpty()) name = "free";

        try {
            List<Post> posts = dao.listByBoard(name, 20);
            req.setAttribute("boardName", name);
            req.setAttribute("posts", posts);
            req.getRequestDispatcher("/board.jsp").forward(req, resp);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
