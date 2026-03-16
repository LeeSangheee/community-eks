<!-- index.jsp -->

<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>로그인 | 커뮤니티</title>
  <link rel="stylesheet" href="/css/style.css?<%= System.currentTimeMillis() %>">
</head>
<body class="theme-dark aws">
  <main class="center-wrap auth-hero">
    <section class="card form-card hero-card" aria-labelledby="loginTitle">
      <header class="hero-header">
        <img class="logo-aws" src="/img/aws.avif" alt="AWS" />
        <div class="hero-sub">AWS Cloud School</div>
        <h1 class="hero-title" id="loginTitle">커뮤니티</h1>
      </header>

      <form action="/login" method="post" autocomplete="on" novalidate class="form hero-form">
        <div class="form-item">
          <input id="uid" name="username" type="text" placeholder="아이디" required autocomplete="username" class="pill" />
        </div>

        <div class="form-item">
          <input id="upw" name="password" type="password" placeholder="비밀번호" required autocomplete="current-password" class="pill" />
        </div>

        <button type="submit" class="btn btn-aws">로그인</button>

        <div class="row-between helper-row">
          <label class="checkbox">
            <input type="checkbox" name="remember" value="true" />
            <span>로그인 유지</span>
          </label>
          <a class="helper-link" href="/account/find">아이디/비밀번호 찾기</a>
        </div>

        <% Object err = request.getAttribute("loginError");
           if (err != null) { %><p class="error-msg"><%= err %></p><% } %>

        <p class="helper-center join-link"><a class="helper-link strong" href="/join.jsp">회원가입</a></p>
      </form>
    </section>
  </main>

  <script>
    (function(){ const $id = document.getElementById('uid'); if ($id) $id.focus(); })();
  </script>
</body>
</html>
