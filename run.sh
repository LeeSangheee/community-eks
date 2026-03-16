#!/bin/bash

echo "=== Docker 컨테이너 실행 ==="

PROJECT_DIR=$(pwd)

# .env 파일 로드
if [ -f "$PROJECT_DIR/.env" ]; then
  export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
else
  echo "오류: .env 파일이 없습니다. .env.example을 복사해서 만들어주세요."
  echo "  cp .env.example .env"
  exit 1
fi

# 안전장치: 기존 컨테이너가 있으면 삭제
docker rm -f community-nginx community-tomcat community-mysql 2>/dev/null

# 네트워크 생성
docker network create community-net 2>/dev/null

# MySQL 실행
echo "1. MySQL 실행..."
docker run -d \
  --name community-mysql \
  --network community-net \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
  -e MYSQL_USER="${MYSQL_USER}" \
  -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
  -p 3306:3306 \
  -v community-mysql-data:/var/lib/mysql \
  -v "$PROJECT_DIR/mysql/init:/docker-entrypoint-initdb.d" \
  mysql:8.0

echo "   MySQL 준비 중..."
sleep 10

# Tomcat 빌드 & 실행
echo "2. Tomcat 빌드..."
docker build -t community-tomcat . -q

echo "   Tomcat 실행..."
docker run -d \
  --name community-tomcat \
  --network community-net \
  -p 8080:8080 \
  -v "$PROJECT_DIR/tomcat-config/context.xml:/usr/local/tomcat/conf/context.xml:ro" \
  -v "$PROJECT_DIR/logs:/usr/local/tomcat/logs" \
  community-tomcat

echo "   Tomcat 시작 대기..."
sleep 5

# Nginx 빌드 & 실행
echo "3. Nginx 빌드..."
docker build -t community-nginx ./nginx -q

echo "   Nginx 실행..."
docker run -d \
  --name community-nginx \
  --network community-net \
  -p 80:80 \
  -v "$PROJECT_DIR/webapp/css:/usr/share/nginx/html/css:ro" \
  -v "$PROJECT_DIR/webapp/img:/usr/share/nginx/html/img:ro" \
  community-nginx

echo ""
echo "✅ 실행 완료!"
echo ""
echo "상태 확인: docker ps"
echo "접속: http://localhost/"