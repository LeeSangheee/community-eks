// PostServlet.java 수정
package com.example;

import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;
import java.io.IOException;
import java.sql.*;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

@WebServlet(name="PostServlet", urlPatterns={"/post"})
public class PostServlet extends HttpServlet {
    private DataSource ds;
    private PostDao dao;
    private CommentDao commentDao;

    @Override
    public void init() throws ServletException {
        try {
            Context init = new InitialContext();
            Context env = (Context) init.lookup("java:/comp/env");
            ds = (DataSource) env.lookup("jdbc/community");
            dao = new PostDao(ds);
            commentDao = new CommentDao(ds);
        } catch (Exception e) {
            throw new ServletException("DataSource lookup 실패", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String idS = req.getParameter("id");
        if (idS == null) { resp.sendRedirect("/board"); return; }
        
        HttpSession session = req.getSession(false);
        Long userId = (session != null) ? (Long) session.getAttribute("userId") : null;
        
        try {
            long postId = Long.parseLong(idS);
            Post p = dao.getById(postId);
            if (p == null) { resp.sendRedirect("/board"); return; }
            
            // 좋아요 개수 조회
            int likeCount = getLikeCount(postId);
            
            // 현재 사용자의 좋아요/스크랩 상태
            boolean isLiked = false;
            boolean isScraped = false;
            if (userId != null) {
                isLiked = checkLiked(postId, userId);
                isScraped = checkScraped(postId, userId);
            }
            
            req.setAttribute("post", p);
            req.setAttribute("likeCount", likeCount);
            req.setAttribute("isLiked", isLiked);
            req.setAttribute("isScraped", isScraped);
            
            List<Comment> comments = commentDao.getCommentsByPostId(postId);
            int commentCount = commentDao.getCommentCount(postId);

            req.setAttribute("comments", comments);
            req.setAttribute("commentCount", commentCount);

            req.getRequestDispatcher("/post.jsp").forward(req, resp);
        } catch (NumberFormatException e) {
            resp.sendRedirect("/board");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
    
    private int getLikeCount(long postId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM post_likes WHERE post_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, postId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
                return 0;
            }
        }
    }
    
    private boolean checkLiked(long postId, long userId) throws SQLException {
        String sql = "SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, postId);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
    
    private boolean checkScraped(long postId, long userId) throws SQLException {
        String sql = "SELECT id FROM post_scraps WHERE post_id = ? AND user_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, postId);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
}