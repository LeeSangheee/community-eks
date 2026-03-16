<!--join.jsp-->

<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>회원가입 | 커뮤니티</title>
  <link rel="stylesheet" href="/css/style.css" />
</head>
<body class="theme-dark aws">
  <main class="center-wrap">
    <section class="card form-card" aria-labelledby="signupTitle">
      <header class="card-header">
        <h1 id="signupTitle" class="title-xl">회원가입</h1>
        <p class="subtitle">서비스 이용을 위한 계정 정보를 입력해 주세요.</p>
      </header>

      <form id="signupForm" action="/register" method="post" novalidate class="form">
        <div class="grid-2">
          <div class="form-item">
            <label for="username" class="label">아이디</label>
            <input id="username" name="username" type="text" placeholder="아이디"
                   required minlength="4" maxlength="20" autocomplete="username" />
          </div>

          <div class="form-item">
            <label for="name" class="label">이름</label>
            <input id="name" name="name" type="text" placeholder="이름" required autocomplete="name" />
          </div>

          <div class="form-item">
            <label for="email" class="label">이메일</label>
            <input id="email" name="email" type="email"
                   placeholder="example@school.ac.kr" required autocomplete="email" />
          </div>

          <!-- 생년월일(선택) -->
          <div class="form-item">
            <label for="birth" class="label">생년월일(선택)</label>
            <input id="birth" name="birth" type="date" inputmode="numeric" />
          </div>
        </div>

        <div class="divider"></div>

        <!-- 비밀번호 -->
        <div class="form-item">
          <label for="password" class="label">비밀번호</label>
          <div class="pw-wrap">
            <input id="password" name="password" type="password"
                   placeholder="비밀번호를 입력해 주세요" required minlength="8" autocomplete="new-password" />
            <button type="button" class="pw-toggle" data-target="password" aria-label="비밀번호 보기">보기</button>
          </div>

          <!-- 규칙 체크 -->
          <ul class="pw-rules" aria-live="polite">
            <li id="rLen" class="rule">8글자 이상</li>
            <li id="rNum" class="rule">숫자로만 구성된 조합 제외</li>
            <li id="rSeq" class="rule">연속되거나 동일한 문자/숫자 제외</li>
          </ul>
        </div>

        <div class="form-item">
          <label for="password2" class="label">비밀번호 확인</label>
          <div class="pw-wrap">
            <input id="password2" name="password2" type="password"
                   placeholder="비밀번호를 다시 입력해 주세요" required minlength="8" autocomplete="new-password" />
            <button type="button" class="pw-toggle" data-target="password2" aria-label="비밀번호 보기">보기</button>
          </div>
          <div id="matchLine" class="rule rule-inline">비밀번호 일치</div>
        </div>

        <label class="checkbox mt-2">
          <input type="checkbox" id="agree" required />
          <span>이용약관 및 개인정보처리방침에 동의합니다.</span>
        </label>

        <%-- 서버 메시지 (선택) --%>
        <%
          Object err = request.getAttribute("error");
          Object ok  = request.getAttribute("success");
          if (err != null) { %><p class="error-msg"><%= err %></p><% }
          if (ok  != null)  { %><p class="ok-msg"><%= ok %></p><% }
        %>

        <button id="btnSubmit" type="submit" class="btn btn-primary btn-lg mt-3">회원가입</button>

        <p class="helper-center mt-2">
          이미 계정이 있나요? <a class="helper-link" href="/index.jsp">로그인</a>
        </p>
      </form>
    </section>
  </main>

  <script>
    const email   = document.getElementById('email');
    const pw      = document.getElementById('password');
    const pw2     = document.getElementById('password2');
    const agree   = document.getElementById('agree');
    const submitB = document.getElementById('btnSubmit');

    const rLen  = document.getElementById('rLen');
    const rNum  = document.getElementById('rNum');
    const rSeq  = document.getElementById('rSeq');
    const matchLine = document.getElementById('matchLine');

    // 연속/동일 금지 검사(3자 이상)
    function hasBadSequence(s){
      if (!s) return false;
      // 동일 반복
      let rep = 1;
      for (let i=1;i<s.length;i++){
        rep = (s[i]===s[i-1]) ? rep+1 : 1;
        if (rep>=3) return true;
      }
      // 증가/감소 연속
      const isAlnum = c => /[A-Za-z0-9]/.test(c);
      for (let i=0;i+2<s.length;i++){
        const a=s.charCodeAt(i), b=s.charCodeAt(i+1), c=s.charCodeAt(i+2);
        if (!isAlnum(s[i])||!isAlnum(s[i+1])||!isAlnum(s[i+2])) continue;
        if ((b-a===1 && c-b===1) || (a-b===1 && b-c===1)) return true;
      }
      return false;
    }

    function updateState(){
      const v  = pw.value;
      const v2 = pw2.value;
      const hasInput = v.length > 0;

      // 입력 전에는 전부 X로
      const okLen = hasInput && v.length >= 8;
      const okNum = hasInput && !/^\d+$/.test(v);
      const okSeq = hasInput && !hasBadSequence(v);
      const okMat = hasInput && v === v2 && v2.length > 0;

      rLen.classList.toggle('ok', okLen);
      rNum.classList.toggle('ok', okNum);
      rSeq.classList.toggle('ok', okSeq);
      matchLine.classList.toggle('ok', okMat);

      submitB.disabled = !(email.validity.valid && okLen && okNum && okSeq && okMat && agree.checked);
      submitB.style.opacity = submitB.disabled ? .7 : 1;
    }

    // 비밀번호 보기/가리기
    document.querySelectorAll('.pw-toggle').forEach(btn=>{
      btn.addEventListener('click', ()=>{
        const t = document.getElementById(btn.dataset.target);
        const isPw = t.type === 'password';
        t.type = isPw ? 'text' : 'password';
        btn.textContent = isPw ? '가리기' : '보기';
      });
    });

    [email, pw, pw2, agree].forEach(el=>{
      el.addEventListener('input', updateState);
      el.addEventListener('change', updateState);
    });
    updateState();

    // 생년월일 min/max (미래일 금지, 1900-01-01 이후만)
    (function(){
      const el = document.getElementById('birth');
      if (!el) return;
      const t = new Date();
      const yyyy = t.getFullYear();
      const mm = String(t.getMonth()+1).padStart(2,'0');
      const dd = String(t.getDate()).padStart(2,'0');
      el.max = `${yyyy}-${mm}-${dd}`;
      el.min = `1900-01-01`;
    })();
  </script>
</body>
</html>
