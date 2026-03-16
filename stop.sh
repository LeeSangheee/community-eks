#!/bin/bash

echo "=== Docker 컨테이너 중지 ==="

docker stop community-nginx community-tomcat community-mysql 2>/dev/null
docker rm community-nginx community-tomcat community-mysql 2>/dev/null

echo ""
echo "✅ 중지 완료!"
echo ""
echo "💾 MySQL 데이터는 보존됨 (community-mysql-data 볼륨)"
echo ""
echo "완전 삭제: docker volume rm community-mysql-data"