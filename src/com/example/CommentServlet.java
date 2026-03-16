// CommentServlet.java
package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

public class CommentServlet extends HttpServlet {
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
        
        // 세션 체크
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("/index.jsp");
            return;
        }
        
        Long userId = (Long) session.getAttribute("userId");
        String userName = (String) session.getAttribute("name");
        
        String postIdStr = req.getParameter("postId");
        String content = req.getParameter("content");
        String anonymous = req.getParameter("anonymous");
        
        if (postIdStr == null || content == null || content.trim().isEmpty()) {
            resp.sendRedirect("/board");
            return;
        }
        
        try {
            long postId = Long.parseLong(postIdStr);
            
            // 익명 처리
            Long authorId = userId;
            String authorName = userName;
            if ("true".equals(anonymous)) {
                authorId = null;
                authorName = null;
            }
            
            dao.create(postId, content.trim(), authorId, authorName);
            
            // 댓글 작성 후 게시글로 리다이렉트
            resp.sendRedirect("/post?id=" + postId);
            
        } catch (Exception e) {
            throw new ServletException("댓글 작성 중 오류 발생", e);
        }
    }
}