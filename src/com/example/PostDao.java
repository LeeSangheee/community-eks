// PostDao.java
package com.example;

import java.sql.*;
import java.util.*;
import javax.sql.DataSource;

public class PostDao {
    private final DataSource ds;
    public PostDao(DataSource ds) { this.ds = ds; }

    // 최근 n개 글
    public List<Post> listByBoard(String board, int limit) throws SQLException {
        List<Post> list = new ArrayList<>();
        String sql = "SELECT id, board_name, title, author_id, author_name, created_at FROM posts WHERE board_name = ? ORDER BY created_at DESC LIMIT ?";
        try (Connection c = ds.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, board);
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Post p = new Post();
                    p.id = rs.getLong("id");
                    p.boardName = rs.getString("board_name");
                    p.title = rs.getString("title");
                    p.authorId = rs.getObject("author_id") == null ? null : rs.getLong("author_id");
                    p.authorName = rs.getString("author_name");
                    p.createdAt = rs.getTimestamp("created_at");
                    list.add(p);
                }
            }
        }
        return list;
    }

    // 글 단건 조회
    public Post getById(long id) throws SQLException {
        String sql = "SELECT id, board_name, title, body, author_id, author_name, created_at FROM posts WHERE id = ?";
        try (Connection c = ds.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Post p = new Post();
                    p.id = rs.getLong("id");
                    p.boardName = rs.getString("board_name");
                    p.title = rs.getString("title");
                    p.body = rs.getString("body");
                    p.authorId = rs.getObject("author_id") == null ? null : rs.getLong("author_id");
                    p.authorName = rs.getString("author_name");
                    p.createdAt = rs.getTimestamp("created_at");
                    return p;
                } else return null;
            }
        }
    }

    // 글쓰기
    public long create(String board, String title, String body, Long authorId, String authorName) throws SQLException {
        String sql = "INSERT INTO posts(board_name, title, body, author_id, author_name) VALUES(?,?,?,?,?)";
        try (Connection c = ds.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, board);
            ps.setString(2, title);
            ps.setString(3, body);
            if (authorId==null) ps.setNull(4, java.sql.Types.BIGINT); else ps.setLong(4, authorId);
            if (authorName==null) ps.setNull(5, java.sql.Types.VARCHAR); else ps.setString(5, authorName);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
                return -1;
            }
        }
    }
}
