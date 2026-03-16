// CommentDeleteServlet.java
package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

public class CommentDeleteServlet extends HttpServlet {
    private DataSource ds;
    private CommentDao dao;

    @Override
    public void init() throws ServletException {
        try {
            Context init = new InitialContext();
            Context env = (Context) init.lookup("java:/comp/env");
            ds = (DataSource) env.lookup("jdbc/community");
            dao = new CommentDao(ds);
        } catch (Exception e) {
            throw new ServletException("DataSource lookup 실패", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        
        req.setCharacterEncoding("UTF-8");
        
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        
        Long userId = (Long) session.getAttribute("userId");
        String commentIdStr = req.getParameter("commentId");
        String postIdStr = req.getParameter("postId");
        
        if (commentIdStr == null || postIdStr == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        
        try {
            long commentId = Long.parseLong(commentIdStr);
            long postId = Long.parseLong(postIdStr);
            
            boolean deleted = dao.delete(commentId, userId);
            
            if (deleted) {
                resp.sendRedirect("/post?id=" + postId);
            } else {
                resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            }
            
        } catch (Exception e) {
            throw new ServletException("댓글 삭제 중 오류 발생", e);
        }
    }
}