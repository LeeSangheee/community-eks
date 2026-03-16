<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="com.example.Post" %>
<%@ page import="com.example.Comment" %>
<%@ page import="java.util.List" %>
<%
  Post p = (Post) request.getAttribute("post");
  if (p == null) { response.sendRedirect("/board"); return; }
  
  Integer likeCount = (Integer) request.getAttribute("likeCount");
  Boolean isLiked = (Boolean) request.getAttribute("isLiked");
  Boolean isScraped = (Boolean) request.getAttribute("isScraped");
  
  List<Comment> comments = (List<Comment>) request.getAttribute("comments");
  Integer commentCount = (Integer) request.getAttribute("commentCount");
  if (comments == null) comments = new java.util.ArrayList<>();
  if (commentCount == null) commentCount = 0;

  if (likeCount == null) likeCount = 0;
  if (isLiked == null) isLiked = false;
  if (isScraped == null) isScraped = false;
%>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title><%= p.title %> | 커뮤니티</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="theme-dark aws">
  
  <%@ include file="/WEB-INF/jsp/common/header.jspf" %>

  <div class="post-detail">
    <!-- 뒤로가기 버튼 -->
    <div class="breadcrumb">
      <a href="/board?name=<%= p.boardName %>" class="back-btn">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M10 12L6 8l4-4"/>
        </svg>
        <%= p.boardName %> 목록
      </a>
    </div>

    <!-- 게시물 상세 -->
    <article class="post-card">
      <header class="post-head">
        <h1 class="post-title-large"><%= p.title %></h1>
        <div class="post-info">
          <div class="author-info">
            <div class="avatar-sm">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
              </svg>
            </div>
            <span class="author-name"><%= p.authorName == null ? "익명" : p.authorName %></span>
          </div>
          <span class="date-time"><%= p.createdAt %></span>
        </div>
      </header>

      <div class="post-body">
        <%= p.body == null ? "" : p.body.replace("\n", "<br>") %>
      </div>

      <footer class="post-actions">
        <div class="action-group">
          <button class="action-btn btn-like <%= isLiked ? "active" : "" %>" data-post-id="<%= p.id %>">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="<%= isLiked ? "currentColor" : "none" %>" stroke="currentColor" stroke-width="2">
              <path d="M14 9V5a3 3 0 00-3-3l-4 9v11h11.28a2 2 0 002-1.7l1.38-9a2 2 0 00-2-2.3zM7 22H4a2 2 0 01-2-2v-7a2 2 0 012-2h3"/>
            </svg>
            좋아요 <span class="like-count"><%= likeCount %></span>
          </button>
          <button class="action-btn btn-scrap <%= isScraped ? "active" : "" %>" data-post-id="<%= p.id %>">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="<%= isScraped ? "currentColor" : "none" %>" stroke="currentColor" stroke-width="2">
              <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/>
            </svg>
            스크랩
          </button>
        </div>
      </footer>
    </article>

    <!-- 댓글 영역 -->
    <section class="comments-section">
      <h2 class="comments-title">댓글 <span class="count"><%= commentCount %></span></h2>
      
      <!-- 댓글 작성 폼 -->
      <form class="comment-write" action="/comment" method="post">
        <input type="hidden" name="postId" value="<%= p.id %>">
        <textarea name="content" placeholder="댓글을 입력하세요..." rows="3" required></textarea>
        <div class="comment-write-footer">
          <label class="comment-anonymous">
            <input type="checkbox" name="anonymous" value="true">
            <span>익명</span>
          </label>
          <button type="submit" class="btn-comment-submit">댓글 작성</button>
        </div>
      </form>

      <!-- 댓글 목록 -->
      <div class="comment-list">
        <%
          if (comments.isEmpty()) {
        %>
          <div class="empty-comment">
            <p>아직 댓글이 없어요. 첫 댓글을 남겨보세요!</p>
          </div>
        <%
          } else {
            Long currentUserId = (Long) session.getAttribute("userId");
            for (Comment c : comments) {
              boolean isMyComment = (currentUserId != null && c.authorId != null && 
                                    currentUserId.equals(c.authorId));
        %>
          <div class="comment-item">
            <div class="comment-header">
              <div class="comment-author">
                <div class="comment-avatar">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                  </svg>
                </div>
                <span class="comment-author-name"><%= c.authorName == null ? "익명" : c.authorName %></span>
              </div>
              <div class="comment-meta">
                <span class="comment-date"><%= c.createdAt %></span>
                <% if (isMyComment) { %>
                  <form action="/comment/delete" method="post" style="display:inline;" 
                        onsubmit="return confirm('댓글을 삭제하시겠습니까?');">
                    <input type="hidden" name="commentId" value="<%= c.id %>">
                    <input type="hidden" name="postId" value="<%= p.id %>">
                    <button type="submit" class="comment-delete">삭제</button>
                  </form>
                <% } %>
              </div>
            </div>
            <div class="comment-content"><%= c.content.replace("\n", "<br>") %></div>
          </div>
        <%
            }
          }
        %>
      </div>
    </section>
  </div>

  <footer class="site-footer">
    <div class="wrap foot">© 2025 커뮤니티</div>
  </footer>

  <script>
    // 좋아요 버튼
    document.querySelector('.btn-like').addEventListener('click', function() {
      const postId = this.getAttribute('data-post-id');
      
      fetch('/post/like', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'postId=' + postId
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.classList.toggle('active', data.isLiked);
          this.querySelector('.like-count').textContent = data.likeCount;
          
          const svg = this.querySelector('svg');
          svg.setAttribute('fill', data.isLiked ? 'currentColor' : 'none');
        } else {
          alert(data.message || '오류가 발생했습니다.');
        }
      })
      .catch(error => {
        console.error('Error:', error);
        alert('오류가 발생했습니다.');
      });
    });

    // 스크랩 버튼
    document.querySelector('.btn-scrap').addEventListener('click', function() {
      const postId = this.getAttribute('data-post-id');
      
      fetch('/post/scrap', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'postId=' + postId
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.classList.toggle('active', data.isScraped);
          
          const svg = this.querySelector('svg');
          svg.setAttribute('fill', data.isScraped ? 'currentColor' : 'none');
          
          if (data.isScraped) {
            alert('스크랩했습니다!');
          }
        } else {
          alert(data.message || '오류가 발생했습니다.');
        }
      })
      .catch(error => {
        console.error('Error:', error);
        alert('오류가 발생했습니다.');
      });
    });
  </script>
</body>
</html>