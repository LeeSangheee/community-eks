// PostCreateServlet.java
package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;
import java.io.IOException;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

@WebServlet(name="PostCreateServlet", urlPatterns={"/post/create"})
public class PostCreateServlet extends HttpServlet {
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
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        
        req.setCharacterEncoding("UTF-8");
        
        // 세션 체크
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            resp.sendRedirect("/index.jsp");
            return;
        }
        
        // 폼 데이터 받기
        String boardName = req.getParameter("boardName");
        String title = req.getParameter("title");
        String body = req.getParameter("body");
        String anonymous = req.getParameter("anonymous");
        
        // 유효성 검사
        if (boardName == null || boardName.isEmpty() || 
            title == null || title.trim().isEmpty() || 
            body == null || body.trim().isEmpty()) {
            
            req.setAttribute("error", "제목과 내용을 입력해주세요.");
            req.getRequestDispatcher("/post_new.jsp?board=" + boardName).forward(req, resp);
            return;
        }
        
        // 세션에서 사용자 정보
        Long userId = (Long) session.getAttribute("userId");
        String userName = (String) session.getAttribute("name");
        
        // 익명 처리
        Long authorId = userId;
        String authorName = userName;
        if ("true".equals(anonymous)) {
            authorId = null;
            authorName = null;
        }
        
        try {
            // DB에 글 저장
            long postId = dao.create(boardName, title, body, authorId, authorName);
            
            if (postId > 0) {
                // 성공 - 작성한 글로 이동
                resp.sendRedirect("/post?id=" + postId);
            } else {
                // 실패
                req.setAttribute("error", "글 작성에 실패했습니다.");
                req.getRequestDispatcher("/post_new.jsp?board=" + boardName).forward(req, resp);
            }
            
        } catch (Exception e) {
            throw new ServletException("글 작성 중 오류 발생", e);
        }
    }
}