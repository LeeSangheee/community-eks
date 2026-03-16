<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*,com.example.Post" %>
<%
  String boardName = (String) request.getAttribute("boardName");
  String boardParam = request.getParameter("name");
  List<Post> posts = (List<Post>) request.getAttribute("posts");
  
  // 게시판 이름 매핑
  String displayName = boardName;
  if (boardParam != null) {
    switch(boardParam) {
      case "notice": displayName = "공지사항"; break;
      case "free": displayName = "자유게시판"; break;
      case "info": displayName = "정보게시판"; break;
      case "event": displayName = "이벤트"; break;
      case "qa": displayName = "Q&A"; break;
      case "market": displayName = "중고거래"; break;
      default: displayName = boardName != null ? boardName : "게시판";
    }
  } else if (boardName == null) {
    displayName = "게시판";
  }
%>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title><%= displayName %> | 커뮤니티</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="theme-dark aws">
  
  <%@ include file="/WEB-INF/jsp/common/header.jspf" %>

  <div class="board-container">
    <!-- 게시판 헤더 -->
    <div class="board-header">
      <h1 class="board-title"><%= displayName %></h1>
      <a class="btn-write" href="/post_new.jsp?board=<%= boardParam != null ? boardParam : "" %>">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 2l2 2-8 8H4v-2l8-8z"/>
        </svg>
        글쓰기
      </a>
    </div>

    <!-- 게시물 리스트 -->
    <div class="post-list">
      <%
        if (posts != null && !posts.isEmpty()) {
          for (Post p : posts) {
      %>
        <article class="post-item">
          <a href="/post?id=<%=p.id%>" class="post-link">
            <h3 class="post-title"><%= p.title %></h3>
            <div class="post-meta">
              <span class="author"><%= p.authorName == null ? "익명" : p.authorName %></span>
              <span class="sep">•</span>
              <span class="date"><%= p.createdAt %></span>
            </div>
          </a>
        </article>
      <%
          }
        } else {
      %>
        <div class="empty-state">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
          </svg>
          <p>아직 작성된 게시물이 없어요</p>
          <a href="/post_new.jsp?board=<%= boardParam != null ? boardParam : "" %>" class="btn-empty">첫 글 작성하기</a>
        </div>
      <%
        }
      %>
    </div>
  </div>

  <footer class="site-footer">
    <div class="wrap foot">© 2025 커뮤니티</div>
  </footer>
</body>
</html>