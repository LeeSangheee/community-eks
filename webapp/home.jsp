<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.DataSource" %>
<%@ page import="javax.naming.Context" %>
<%@ page import="javax.naming.InitialContext" %>
<%
  Long uid = (Long) session.getAttribute("userId");
  String name = (String) session.getAttribute("name");
  String username = (String) session.getAttribute("username");
  if (name == null || name.isEmpty()) name = (username != null ? username : "회원");
  
  // 활동 카운트 조회
  int postCount = 0;
  int commentCount = 0;
  int scrapCount = 0;
  
  if (username != null) {
    try {
      Context initContext = new InitialContext();
      DataSource ds = (DataSource) initContext.lookup("java:comp/env/jdbc/community");
      
      try (Connection conn = ds.getConnection()) {
        // 게시글 수
        String sql = "SELECT COUNT(*) FROM posts WHERE author_name = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
          pstmt.setString(1, username);
          try (ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) postCount = rs.getInt(1);
          }
        }
        
        // 댓글 수
        sql = "SELECT COUNT(*) FROM comments WHERE author_name = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
          pstmt.setString(1, username);
          try (ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) commentCount = rs.getInt(1);
          }
        }
        
        // 스크랩 수
        Long userId = (Long) session.getAttribute("userId");

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
  }
%>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>홈 | 커뮤니티</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="theme-dark aws">
  
  <!-- 공통 헤더 include -->
  <%@ include file="/WEB-INF/jsp/common/header.jspf" %>

  <!-- 본문 그리드 -->
  <main class="wrap grid">
    <!-- 좌: 프로필 -->
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
            <div class="profile-name"><%= name %></div>
            <div class="profile-id">@<%= (username!=null?username:"user") %></div>
          </div>
        </div>
        
        <div class="profile-actions">
          <a class="profile-btn" href="/profile.jsp">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
            내 정보
          </a>
          <a class="profile-btn" href="/my/settings">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="3"/>
              <path d="M12 1v6m0 6v6m0-18a9 9 0 100 18 9 9 0 000-18z"/>
              <path d="M19.07 4.93l-4.24 4.24m0 5.66l4.24 4.24M4.93 4.93l4.24 4.24m5.66 0l4.24-4.24"/>
            </svg>
            설정
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

    <!-- 중: 메인 — 6개 게시판 타일 -->
    <section class="col center">
      <div class="card boards-intro">
        <h2 class="title" style="margin-bottom:12px;">게시판 바로가기</h2>
        <div class="board-tiles">
          <a class="tile" href="/board?name=notice">
            <strong class="t">공지사항</strong>
            <span class="d">운영/학원 공지 확인</span>
          </a>
          <a class="tile" href="/board?name=free">
            <strong class="t">자유게시판</strong>
            <span class="d">일상 대화와 잡담</span>
          </a>
          <a class="tile" href="/board?name=info">
            <strong class="t">정보게시판</strong>
            <span class="d">유용한 팁과 자료</span>
          </a>
          <a class="tile" href="/board?name=event">
            <strong class="t">이벤트 게시판</strong>
            <span class="d">행사/이벤트 소식</span>
          </a>
          <a class="tile" href="/board?name=qa">
            <strong class="t">Q&amp;A</strong>
            <span class="d">질문하고 답을 받아보자</span>
          </a>
          <a class="tile" href="/board?name=market">
            <strong class="t">중고거래</strong>
            <span class="d">교재/물품 거래</span>
          </a>
        </div>
      </div>
    </section>

    <!-- 우: 검색/위젯 -->
    <aside class="col right">
      <div class="card search">
        <form action="/search" method="get" class="search-form">
          <input type="search" name="q" placeholder="전체 게시판 검색…" />
          <button type="submit" class="btn">검색</button>
        </form>
      </div>
      <div class="card widget">
        <h3 class="title">실시간 인기 글</h3>
        <p class="empty">표시할 항목이 없습니다.</p>
      </div>
    </aside>
  </main>

  <footer class="site-footer">
    <div class="wrap foot">© 2025 커뮤니티</div>
  </footer>
</body>
</html>