<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.DataSource" %>
<%@ page import="javax.naming.Context" %>
<%@ page import="javax.naming.InitialContext" %>
<%
    String username = (String) session.getAttribute("username");
    Long userId = (Long) session.getAttribute("userId");
    if (username == null || userId == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    // 프로필에 표시할 이름
    String displayName = (String) session.getAttribute("name");
    if (displayName == null || displayName.isEmpty()) {
        displayName = username;
    }

    int postCount = 0;
    int commentCount = 0;
    int scrapCount = 0;

    try {
        Context initContext = new InitialContext();
        DataSource ds = (DataSource) initContext.lookup("java:comp/env/jdbc/community");

        try (Connection conn = ds.getConnection()) {
            // 내가 쓴 글 수
            String sql = "SELECT COUNT(*) FROM posts WHERE author_name = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) postCount = rs.getInt(1);
                }
            }

            // 댓글 단 글 수
            sql = "SELECT COUNT(*) FROM comments WHERE author_name = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) commentCount = rs.getInt(1);
                }
            }

            // 스크랩 수
            sql = "SELECT COUNT(*) FROM post_scraps WHERE user_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setLong(1, userId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) scrapCount = rs.getInt(1);
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>내 스크랩 | 커뮤니티</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/css/style.css">
  <style>
    .scrap-list-item {
      padding: 1.25rem;
      margin-bottom: 0.75rem;
      background: rgba(255, 255, 255, 0.03);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 8px;
      transition: all 0.2s;
    }
    .scrap-list-item:hover {
      background: rgba(255, 255, 255, 0.05);
      border-color: rgba(59, 130, 246, 0.3);
      transform: translateX(4px);
    }
    .scrap-list-item a {
      text-decoration: none;
      color: inherit;
      display: block;
    }
    .scrap-list-title {
      font-size: 1.125rem;
      font-weight: 600;
      color: rgba(255, 255, 255, 0.95);
      margin-bottom: 0.5rem;
    }
    .scrap-list-meta {
      display: flex;
      gap: 1rem;
      font-size: 0.875rem;
      color: rgba(255, 255, 255, 0.5);
    }
  </style>
</head>
<body class="theme-dark aws">
  
  <%@ include file="/WEB-INF/jsp/common/header.jspf" %>

  <main class="wrap grid">
    <aside class="col left">
      <!-- 프로필 카드 -->
      <section class="profile-card">
        <div class="profile-header">
          <div class="avatar-large">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
            </svg>
          </div>
          <div class="profile-info">
            <div class="profile-name"><%= displayName %></div>
            <div class="profile-id">@<%= username %></div>
          </div>
        </div>

        <div class="profile-actions">
          <a class="profile-btn" href="/home.jsp">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
            </svg>
            홈으로
          </a>
          <a class="profile-btn" href="/profile.jsp">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
            내 정보
          </a>
        </div>
      </section>

      <!-- 내 활동 박스 (home.jsp 스타일) -->
      <nav class="my-activity">
        <h3 class="activity-title">내 활동</h3>
        <a class="activity-item" href="/my-posts.jsp">
          <div class="activity-icon posts">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/>
              <path d="M14 2v6h6M16 13H8m8 4H8m8 4H8"/>
            </svg>
          </div>
          <span class="activity-label">내가 쓴 글</span>
          <span class="activity-count"><%= postCount %></span>
        </a>
        <a class="activity-item" href="/my-comments.jsp">
          <div class="activity-icon comments">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/>
            </svg>
          </div>
          <span class="activity-label">댓글 단 글</span>
          <span class="activity-count"><%= commentCount %></span>
        </a>
        <a class="activity-item" href="/my-scraps.jsp">
          <div class="activity-icon scraps">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
            </svg>
          </div>
          <span class="activity-label">내 스크랩</span>
          <span class="activity-count"><%= scrapCount %></span>
        </a>
      </nav>
    </aside>


    <section class="col center">
      <div class="card">
        <h2 class="title">내 스크랩</h2>
        <div class="scrap-list">
          <%
            try {
              Context initContext = new InitialContext();
              DataSource ds = (DataSource) initContext.lookup("java:comp/env/jdbc/community");
              
              try (Connection conn = ds.getConnection()) {
                String sql =
                        "SELECT s.post_id, s.created_at AS scrap_date, " +
                        "       p.title, p.board_name, p.author_name, p.created_at, " +
                        "       (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS comment_count " +
                        "FROM post_scraps s " +
                        "JOIN posts p ON s.post_id = p.id " +
                        "WHERE s.user_id = ? " +
                        "ORDER BY s.created_at DESC " +
                        "LIMIT 50";

                try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                  pstmt.setLong(1, userId);
                  
                  try (ResultSet rs = pstmt.executeQuery()) {
                    if (!rs.next()) {
          %>
          <p class="empty">스크랩한 글이 없습니다.</p>
          <%
                    } else {
                      do {
                        int postId = rs.getInt("post_id");
                        String title = rs.getString("title");
                        String boardName = rs.getString("board_name");
                        String authorName = rs.getString("author_name");
                        String scrapDate = rs.getString("scrap_date");
                        int postcommentCount = rs.getInt("comment_count");
          %>
          <div class="scrap-list-item">
            <a href="/post?id=<%= postId %>">
              <div class="scrap-list-title">⭐ <%= title %></div>
              <div class="scrap-list-meta">
                <span>📁 <%= boardName %></span>
                <span>✍️ <%= authorName %></span>
                <span>💬 <%= commentCount %></span>
                <span>📌 <%= scrapDate %></span>
              </div>
            </a>
          </div>
          <%
                      } while (rs.next());
                    }
                  }
                }
              }
            } catch (Exception e) {
              e.printStackTrace();
          %>
          <p class="empty" style="color: #ef4444;">오류가 발생했습니다.</p>
          <%
            }
          %>
        </div>
      </div>
    </section>

  </main>

  <footer class="site-footer">
    <div class="wrap foot">© 2025 커뮤니티</div>
  </footer>
</body>
</html>