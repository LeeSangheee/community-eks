// CommentDao.java
package com.example;

import java.sql.*;
import java.util.*;
import javax.sql.DataSource;

public class CommentDao {
    private final DataSource ds;
    
    public CommentDao(DataSource ds) {
        this.ds = ds;
    }

    // 특정 게시글의 댓글 목록 조회
    public List<Comment> getCommentsByPostId(long postId) throws SQLException {
        List<Comment> list = new ArrayList<>();
        String sql = "SELECT id, post_id, author_id, author_name, content, created_at " +
                     "FROM comments WHERE post_id = ? ORDER BY created_at ASC";
        
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, postId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Comment c = new Comment();
                    c.id = rs.getLong("id");
                    c.postId = rs.getLong("post_id");
                    c.authorId = rs.getObject("author_id") == null ? null : rs.getLong("author_id");
                    c.authorName = rs.getString("author_name");
                    c.content = rs.getString("content");
                    c.createdAt = rs.getTimestamp("created_at");
                    list.add(c);
                }
            }
        }
        return list;
    }

    // 댓글 개수 조회
    public int getCommentCount(long postId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM comments WHERE post_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, postId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
                return 0;
            }
        }
    }

    // 댓글 작성
    public long create(long postId, String content, Long authorId, String authorName) throws SQLException {
        String sql = "INSERT INTO comments(post_id, author_id, author_name, content) VALUES(?,?,?,?)";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, postId);
            if (authorId == null) ps.setNull(2, Types.BIGINT);
            else ps.setLong(2, authorId);
            if (authorName == null) ps.setNull(3, Types.VARCHAR);
            else ps.setString(3, authorName);
            ps.setString(4, content);
            ps.executeUpdate();
            
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
                return -1;
            }
        }
    }

    // 댓글 삭제
    public boolean delete(long commentId, long userId) throws SQLException {
        String sql = "DELETE FROM comments WHERE id = ? AND author_id = ?";
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, commentId);
            ps.setLong(2, userId);
            return ps.executeUpdate() > 0;
        }
    }
}