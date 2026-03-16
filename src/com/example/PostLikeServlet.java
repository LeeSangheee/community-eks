// PostLikeServlet.java
package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;

public class PostLikeServlet extends HttpServlet {
    private DataSource ds;

    @Override
    public void init() throws ServletException {
        try {
            Context init = new InitialContext();
            Context env = (Context) init.lookup("java:/comp/env");
            ds = (DataSource) env.lookup("jdbc/community");
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
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.getWriter().write("{\"success\":false,\"message\":\"로그인이 필요합니다\"}");
            return;
        }
        
        Long userId = (Long) session.getAttribute("userId");
        String postIdStr = req.getParameter("postId");
        
        if (postIdStr == null) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            resp.getWriter().write("{\"success\":false,\"message\":\"잘못된 요청입니다\"}");
            return;
        }
        
        try {
            long postId = Long.parseLong(postIdStr);
            
            // 좋아요 토글
            boolean isLiked = toggleLike(postId, userId);
            int likeCount = getLikeCount(postId);
            
            resp.setContentType("application/json; charset=UTF-8");
            resp.getWriter().write(String.format(
                "{\"success\":true,\"isLiked\":%b,\"likeCount\":%d}",
                isLiked, likeCount
            ));
            
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"success\":false,\"message\":\"서버 오류\"}");
            e.printStackTrace();
        }
    }
    
    private boolean toggleLike(long postId, long userId) throws SQLException {
        // 이미 좋아요 했는지 확인
        String checkSql = "SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(checkSql)) {
            ps.setLong(1, postId);
            ps.setLong(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    // 이미 좋아요 → 취소
                    String deleteSql = "DELETE FROM post_likes WHERE post_id = ? AND user_id = ?";
                    try (PreparedStatement delPs = conn.prepareStatement(deleteSql)) {
                        delPs.setLong(1, postId);
                        delPs.setLong(2, userId);
                        delPs.executeUpdate();
                    }
                    return false;
                } else {
                    // 좋아요 추가
                    String insertSql = "INSERT INTO post_likes(post_id, user_id) VALUES(?, ?)";
                    try (PreparedStatement insPs = conn.prepareStatement(insertSql)) {
                        insPs.setLong(1, postId);
                        insPs.setLong(2, userId);
                        insPs.executeUpdate();
                    }
                    return true;
                }
            }
        }
    }
    
    private int getLikeCount(long postId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM post_likes WHERE post_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, postId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
                return 0;
            }
        }
    }
}