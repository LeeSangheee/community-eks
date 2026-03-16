<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%
  String boardParam = request.getParameter("board");
  if (boardParam == null) boardParam = "free";
  
  // 게시판 이름 매핑
  String boardName = "";
  switch(boardParam) {
    case "notice": boardName = "공지사항"; break;
    case "free": boardName = "자유게시판"; break;
    case "info": boardName = "정보게시판"; break;
    case "event": boardName = "이벤트"; break;
    case "qa": boardName = "Q&A"; break;
    case "market": boardName = "중고거래"; break;
    default: boardName = "게시판";
  }
%>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>글쓰기 - <%= boardName %> | 커뮤니티</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/css/style.css">
</head>
<body class="theme-dark aws">
  
  <%@ include file="/WEB-INF/jsp/common/header.jspf" %>

  <div class="write-container">
    <!-- 헤더 -->
    <div class="write-header">
      <a href="/board?name=<%= boardParam %>" class="back-link">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M15 18l-6-6 6-6"/>
        </svg>
      </a>
      <h1 class="write-title"><%= boardName %> 글쓰기</h1>
    </div>

    <!-- 작성 폼 -->
    <form action="/post/create" method="post" class="write-form">
      <input type="hidden" name="boardName" value="<%= boardParam %>">
      
      <!-- 제목 -->
      <div class="write-field">
        <label class="write-label" for="title">제목</label>
        <input 
          type="text" 
          id="title" 
          name="title" 
          class="write-input" 
          placeholder="제목을 입력하세요"
          maxlength="100"
          required
        >
        <div class="field-hint">
          <span class="char-count">0/100</span>
        </div>
      </div>

      <!-- 내용 -->
      <div class="write-field">
        <label class="write-label" for="body">내용</label>
        <textarea 
          id="body" 
          name="body" 
          class="write-textarea" 
          placeholder="내용을 입력하세요&#10;&#10;• 타인을 비방하거나 욕설, 혐오 표현은 삼가주세요&#10;• 개인정보를 함부로 공개하지 마세요"
          rows="15"
          required
        ></textarea>
        <div class="field-hint">
          <span class="char-count-body">0자</span>
        </div>
      </div>

      <!-- 옵션 -->
      <div class="write-options">
        <label class="option-item">
          <input type="checkbox" name="anonymous" value="true">
          <span class="option-label">익명으로 작성</span>
        <!-- </label>
        <label class="option-item">
          <input type="checkbox" name="notify" value="true" checked>
          <span class="option-label">댓글 알림 받기</span>
        </label> -->
      </div>

      <!-- 버튼 -->
      <div class="write-actions">
        <a href="/board?name=<%= boardParam %>" class="btn-cancel">취소</a>
        <button type="submit" class="btn-submit">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M5 13l4 4L19 7"/>
          </svg>
          작성
        </button>
      </div>
    </form>
  </div>

  <footer class="site-footer">
    <div class="wrap foot">© 2025 커뮤니티</div>
  </footer>

  <script>
    // 제목 글자 수 카운터
    const titleInput = document.getElementById('title');
    const charCount = document.querySelector('.char-count');
    
    titleInput.addEventListener('input', function() {
      const length = this.value.length;
      charCount.textContent = length + '/100';
      
      if (length > 90) {
        charCount.style.color = '#ff6b64';
      } else {
        charCount.style.color = 'var(--muted)';
      }
    });

    // 내용 글자 수 카운터
    const bodyTextarea = document.getElementById('body');
    const charCountBody = document.querySelector('.char-count-body');
    
    bodyTextarea.addEventListener('input', function() {
      const length = this.value.length;
      charCountBody.textContent = length + '자';
    });

    // 폼 제출 전 확인
    document.querySelector('.write-form').addEventListener('submit', function(e) {
      const title = titleInput.value.trim();
      const body = bodyTextarea.value.trim();
      
      if (!title) {
        alert('제목을 입력해주세요.');
        e.preventDefault();
        return;
      }
      
      if (!body) {
        alert('내용을 입력해주세요.');
        e.preventDefault();
        return;
      }
      
      if (body.length < 10) {
        if (!confirm('내용이 너무 짧습니다. 그래도 작성하시겠습니까?')) {
          e.preventDefault();
          return;
        }
      }
    });
  </script>
</body>
</html>