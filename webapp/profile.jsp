<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.DataSource" %>
<%@ page import="javax.naming.Context" %>
<%@ page import="javax.naming.InitialContext" %>
<%
    String username = (String) session.getAttribute("username");
    Long userId = (Long) session.getAttribute("userId");   // ← 추가
    if (username == null || userId == null) {              // ← 체크도 같이
        response.sendRedirect("index.jsp");
        return;
    }

    String name = "";
    String email = "";
    String createdAt = "";
    int postCount = 0;
    int commentCount = 0;
    int likeCount = 0;
    int scrapCount = 0;

    try {
        Context initContext = new InitialContext();
        DataSource ds = (DataSource) initContext.lookup("java:comp/env/jdbc/community");
        
        try (Connection conn = ds.getConnection()) {
            // 사용자 정보
            String sql = "SELECT name, email, created_at FROM users WHERE username = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        name = rs.getString("name");
                        email = rs.getString("email");
                        createdAt = rs.getString("created_at");
                    }
                }
            }

            // 게시글 수 (author_name = username) → OK
            sql = "SELECT COUNT(*) FROM posts WHERE author_name = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) postCount = rs.getInt(1);
                }
            }

            // 댓글 수 (author_name = username) → OK
            sql = "SELECT COUNT(*) FROM comments WHERE author_name = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) commentCount = rs.getInt(1);
                }
            }

            // 좋아요 수: post_likes는 user_id 사용
            sql = "SELECT COUNT(*) FROM post_likes WHERE user_id = ?";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setLong(1, userId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) likeCount = rs.getInt(1);
                }
            }

            // 스크랩 수: post_scraps도 user_id 사용
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
  <title>내 정보 | 커뮤니티</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/css/style.css">
  <style>
    .profile-detail-row {
      display: flex;
      padding: 1rem;
      margin-bottom: 0.5rem;
      background: rgba(255, 255, 255, 0.03);
      border-radius: 8px;
      border: 1px solid rgba(255, 255, 255, 0.08);
    }
    .profile-detail-row .label {
      min-width: 100px;
      font-weight: 600;
      color: rgba(255, 255, 255, 0.7);
    }
    .profile-detail-row .value {
      color: rgba(255, 255, 255, 0.95);
    }
    
    @media (max-width: 768px) {
      .profile-detail-row {
        flex-direction: column;
        gap: 0.5rem;
      }
    }
  </style>
</head>
<body class="theme-dark aws">
  
  <%@ include file="/WEB-INF/jsp/common/header.jspf" %>

  <main class="wrap grid">
    <!-- 좌: 프로필 요약 -->
    <aside class="col left">
      <section class="profile-card">
        <div class="profile-header">
          <div class="avatar-large">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
            </svg>
          </div>
          <div class="profile-info">
            <div class="profile-name"><%= name %></div>
            <div class="profile-id">@<%= username %></div>
          </div>
        </div>
        
        <div class="profile-actions">
          <a class="profile-btn" href="/home.jsp" style="background: rgba(255, 255, 255, 0.05);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
            </svg>
            홈으로
          </a>
        </div>
      </section>

      <!-- 내 활동 메뉴 -->
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

    <!-- 중: 기본 정보만 표시 -->
    <section class="col center">
      <div class="card">
        <h2 class="title">기본 정보</h2>
        <div class="profile-detail-row">
          <span class="label">아이디</span>
          <span class="value"><%= username %></span>
        </div>
        <div class="profile-detail-row">
          <span class="label">이름</span>
          <span class="value"><%= name %></span>
        </div>
        <div class="profile-detail-row">
          <span class="label">이메일</span>
          <span class="value"><%= email != null && !email.isEmpty() ? email : "미등록" %></span>
        </div>
        <div class="profile-detail-row">
          <span class="label">가입일</span>
          <span class="value"><%= createdAt %></span>
        </div>
      </div>
    </section>

    <!-- 우: 위젯 -->
    <aside class="col right">
      <div class="card widget">
        <h3 class="title">최근 활동</h3>
        <p class="empty">최근 활동이 없습니다.</p>
      </div>
    </aside>
  </main>

  <footer class="site-footer">
    <div class="wrap foot">© 2025 커뮤니티</div>
  </footer>
</body>
</html>