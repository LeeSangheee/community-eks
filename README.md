# 커뮤니티 웹 애플리케이션

<p align="center">
  <b>3계층 컨테이너 기반 커뮤니티 웹 애플리케이션 — 로컬 Docker Compose부터 Kubernetes 프로덕션까지</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Java-17-orange?logo=openjdk" alt="Java 17">
  <img src="https://img.shields.io/badge/Tomcat-10.1-yellow?logo=apachetomcat" alt="Tomcat 10.1">
  <img src="https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql" alt="MySQL 8.0">
  <img src="https://img.shields.io/badge/Nginx-1.14-green?logo=nginx" alt="Nginx">
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker" alt="Docker Compose">
  <img src="https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes" alt="Kubernetes">
</p>

---

## TL;DR

**문제:** 단일 서버 배포는 스케일링과 장애 격리가 어렵습니다.

**해결:** Nginx → Tomcat → MySQL 계층을 컨테이너로 완전 분리하고, Docker Compose IaC로 환경을 코드로 정의합니다. Kubernetes 매니페스트까지 포함해 프로덕션 배포를 지원합니다.

| 특징 | 효과 |
|------|------|
| 3-Stage 멀티스테이지 빌드 | 이미지 크기 ~800MB → ~150MB (약 80% 감소) |
| 계층 분리 아키텍처 | 각 tier 독립 스케일링 및 장애 격리 |
| .env 기반 시크릿 관리 | 민감정보 코드에서 완전 분리, git 추적 없음 |
| Kubernetes HPA | 트래픽 기반 Tomcat / Nginx 자동 수평 확장 |
| Terraform (ECR + IAM) | AWS 인프라를 코드로 정의 및 재현 가능한 프로비저닝 |

---

## 사전 요구사항

| 도구 | 버전 | 비고 |
|------|------|------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 최신 | Docker Compose 포함 |
| [JDK 17](https://aws.amazon.com/corretto/) | 17 이상 | `build.sh`의 `javac` 컴파일에 필요 |
| Git Bash (Windows) | — | Windows에서 `.sh` 스크립트 실행에 필요 |

> **Windows 사용자:** 모든 `./script.sh` 명령은 **Git Bash** 터미널에서 실행하세요.

---

## 빠른 시작

```bash
# 1. 저장소 클론
git clone https://github.com/LeeSangheee/community-eks.git
cd community-eks

# 2. 환경변수 파일 생성
cp .env.example .env
# .env 파일을 열어 MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD 값 수정 (나머지는 그대로 사용 가능)

# 3. WAR 빌드 (로컬 javac 사용 → build/community.war 생성)
chmod +x build.sh && ./build.sh

# 4. 전체 스택 실행 (Docker 이미지 빌드 포함, 첫 실행 시 수 분 소요)
docker-compose up -d

# 5. 상태 확인 (mysql: healthy, tomcat/nginx: running 확인)
docker-compose ps

# 6. 웹 접속 확인
curl -s -o /dev/null -w "%{http_code}" http://localhost
```

접속: **http://localhost** (Nginx → Tomcat 프록시)

> **주의:** 포트 80이 이미 사용 중이면 `docker-compose.yml`의 nginx ports를 `"8000:80"`으로 변경 후 `http://localhost:8000`으로 접속하세요.

---

## 시스템 아키텍처

### 로컬 개발: Docker Compose

```
┌─────────────────────────────────────────────────────────────────┐
│                   Docker Compose (IaC)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │  Nginx 1.14  │      │ Tomcat 10.1  │      │  MySQL 8.0   │  │
│  │(Reverse Proxy│─────▶│ (Application)│─────▶│  (Database)  │  │
│  │  Port: 80    │      │  Port: 8080  │      │ Port: 3306   │  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
│        │                      │                      │          │
│   Static Assets          JNDI DataSource        Volume Mount   │
│   Routing Rules          WAR Deployment          Init Scripts   │
│   Compression            JVM Config              Health Check   │
│                                                                 │
│  Network: community-network (bridge)                            │
│  Volume:  mysql-data (persistent storage)                       │
└─────────────────────────────────────────────────────────────────┘
```

### 프로덕션: AWS EKS

```
GitHub Actions (CI/CD)
    │  OIDC → IAM Role → ECR Push + kubectl apply
    ▼
Internet
    │
    ▼
[AWS ALB]  ← AWS Load Balancer Controller (IRSA)
    │
    ▼
[Nginx Pods]  namespace: web  (HPA: 1~4)
    │
    ▼
[Tomcat Pods]  namespace: was  (HPA: 1~10)
    │
    ▼
[MySQL]  was/db_config.yaml + db_secret.yaml

모니터링 (Helm):
  Prometheus + Grafana  → 메트릭 수집 및 시각화
  Loki  → 로그 수집 (S3 백엔드)
  Tempo → 트레이스 수집 (S3 백엔드)

인프라 (Terraform):
  VPC (public/private subnet × 2 AZ)
  EKS Cluster + Managed Node Group (t3.medium × 2)
  ECR (com-tomcat, com-nginx)
  IAM Roles (Cluster, Node, ALB Controller, EBS CSI, Loki/Tempo IRSA)
  GitHub Actions OIDC Provider + Deploy Role
  S3 버킷 (Loki 로그 30일, Tempo 트레이스 7일 보관)
```

| 컴포넌트 | 역할 | 위치 |
|----------|------|------|
| VPC + Subnet | 네트워크 격리 (public/private 분리) | `terraform/vpc.tf` |
| EKS Cluster | Kubernetes 컨트롤 플레인 | `terraform/eks.tf` |
| Managed Node Group | 워커 노드 (private subnet) | `terraform/eks.tf` |
| AWS Load Balancer Controller | ALB Ingress 프로비저닝 | `terraform/alb-controller.tf` |
| ECR | 컨테이너 이미지 레지스트리 | `terraform/ecr.tf` |
| GitHub Actions OIDC + IAM Role | CI/CD 파이프라인 권한 (IRSA) | `terraform/github-actions.tf` |
| S3 (Loki/Tempo) + IRSA | 로그·트레이스 저장소 및 접근 권한 | `terraform/monitoring.tf` |
| Nginx Deployment + HPA | 정적 자산 서빙 + 리버스 프록시 | `web/` |
| Tomcat Deployment + HPA | 비즈니스 로직 + WAR 실행 | `was/` |
| ALB Ingress | 외부 트래픽 → Nginx 라우팅 | `web/web-ingress.yaml` |
| Prometheus + Grafana | 메트릭 수집 및 시각화 (Helm) | `monitoring/` |
| Loki + Tempo | 로그·트레이스 수집 (Helm) | `monitoring/` |

---

## 프로젝트 구조

```
community/
├── src/com/example/              # Java 서블릿 소스
│   ├── BoardServlet.java
│   ├── Post.java, PostDao.java
│   ├── Comment.java, CommentDao.java
│   ├── LoginServlet.java, RegisterServlet.java
│   └── PostLikeServlet.java, PostScrapServlet.java
│
├── webapp/                       # 웹 루트
│   ├── WEB-INF/
│   │   ├── web.xml
│   │   ├── lib/                  # JDBC 드라이버, Jakarta EE API
│   │   └── jsp/common/
│   ├── css/, img/
│   └── *.jsp                     # 페이지 (index, board, post, join 등)
│
├── nginx/                        # Nginx 컨테이너
│   ├── Dockerfile
│   └── conf.d/default.conf
│
├── tomcat-config/
│   └── context.xml               # JNDI DataSource 설정
│
├── mysql/init/init.sql           # DB 초기화 스크립트
│
├── was/                          # Kubernetes WAS 매니페스트
│   ├── tomcat-hpa.yaml
│   ├── tomcat-service.yaml
│   ├── db_config.yaml
│   └── db_secret.yaml
│
├── web/                          # Kubernetes 웹 매니페스트
│   ├── nginx-hpa.yaml
│   ├── nginx-service.yaml
│   └── web-ingress.yaml
│
├── metallb/metallb-config.yaml   # (온프레미스 전용, EKS에서는 미사용)
│
├── terraform/                    # AWS 인프라 (VPC, EKS, ECR, IAM)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf                    # VPC, Subnet, IGW, NAT
│   ├── eks.tf                    # EKS Cluster, Node Group, Addon, IRSA
│   ├── ecr.tf                    # ECR 레포지토리
│   ├── alb-controller.tf         # ALB Controller IRSA
│   ├── alb-controller-iam-policy.json
│   ├── github-actions.tf         # GitHub Actions OIDC + IAM Role
│   └── monitoring.tf             # Loki/Tempo S3 버킷 + IRSA
│
├── monitoring/                   # 모니터링 스택 (Helm values)
│   └── ...                       # Prometheus, Grafana, Loki, Tempo
│
├── argocd/                       # ArgoCD GitOps 설정
│   └── ...
│
├── Dockerfile                    # 3-stage 멀티스테이지 빌드
├── docker-compose.yml
├── build.sh
├── run.sh, stop.sh
├── deploy-k8s.sh                 # Kubernetes 배포 스크립트 (envsubst 적용)
├── setenv.sh                     # JVM / Catalina 옵션
├── .env.example                  # 환경변수 템플릿 (.env는 gitignore)
└── README.md
```

---

## 핵심 기술 구현

### 1. 3-Stage 멀티스테이지 빌드

```
Stage 1 (jre-builder)   : Amazon Corretto 17 Alpine → jlink로 최소 JRE 생성
Stage 2 (tomcat-builder): Alpine 3.19 → Tomcat 10.1.30 다운로드 및 불필요 파일 제거
Stage 3 (runtime)       : Alpine 3.19 + Stage1 JRE + Stage2 Tomcat → 최종 이미지
```

결과: `amazoncorretto:17` (~800MB) → Alpine 기반 최소 런타임 (~150MB)

### 2. JNDI DataSource (커넥션 풀링)

```xml
<!-- tomcat-config/context.xml -->
<Resource name="jdbc/community"
          type="javax.sql.DataSource"
          url="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?..."
          username="${DB_USER}"
          password="${DB_PASSWORD}"
          maxActive="20" maxIdle="10" maxWait="30000"/>
```

```java
// 애플리케이션 코드
DataSource ds = (DataSource) new InitialContext()
    .lookup("java:comp/env/jdbc/community");
Connection conn = ds.getConnection();
```

### 3. 헬스체크 기반 의존성 관리

```yaml
# docker-compose.yml
tomcat:
  depends_on:
    mysql:
      condition: service_healthy   # MySQL 헬스체크 통과 후 Tomcat 시작

mysql:
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
    interval: 10s
    timeout: 5s
    retries: 5
```

### 4. Kubernetes HPA (자동 수평 확장)

```yaml
# was/tomcat-hpa.yaml
spec:
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

---

## 운영 명령어

```bash
# 서비스 상태
docker-compose ps

# 실시간 로그
docker-compose logs -f
docker-compose logs -f tomcat   # 특정 서비스

# DB 접속 (.env의 MYSQL_USER, MYSQL_PASSWORD 사용)
docker exec -it community-mysql mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}"

# 중지 (데이터 유지)
docker-compose down

# 전체 초기화 (볼륨 포함)
docker-compose down -v
```

---

## 설정 커스터마이징

### 포트 변경

```yaml
# docker-compose.yml
services:
  nginx:
    ports: ["8000:80"]
  tomcat:
    ports: ["8081:8080"]
  mysql:
    ports: ["3307:3306"]
```

### DB 비밀번호 변경

`.env` 파일만 수정하면 됩니다. `docker-compose.yml`과 `context.xml`은 모두 환경변수를 참조합니다.

```bash
# .env
MYSQL_PASSWORD=your-new-password
```

### JVM 튜닝

```bash
# setenv.sh
export CATALINA_OPTS="-Xmx1024m -Xms512m -XX:+UseG1GC"
```

---

## 배포 시나리오

```bash
# 로컬 개발
cp .env.example .env   # 값 수정 후
docker-compose up -d

# 스테이징 (환경 파일)
docker-compose --env-file .env.staging up -d

# AWS 인프라 프로비저닝 (최초 1회)
# VPC, EKS 클러스터, ECR, IAM, ALB Controller IRSA 생성
cd terraform
terraform init
terraform apply
# 출력된 alb_controller_role_arn 값을 .env의 ALB_CONTROLLER_ROLE_ARN에 복사
cd ..

# .env에 EKS_CLUSTER_NAME, ALB_CONTROLLER_ROLE_ARN 채우기

# 애플리케이션 배포 (Helm + kubectl)
chmod +x deploy-k8s.sh && ./deploy-k8s.sh

# ALB 주소 확인
kubectl get ingress web-ingress -n web
```

---

## 성능 특성

| 메트릭 | 값 | 비고 |
|--------|-----|------|
| 이미지 크기 | ~150MB | Alpine + 최소 JRE (jlink) |
| 전체 스택 기동 시간 | ~30초 | 헬스체크 포함 |
| 메모리 사용 | ~800MB | 전체 스택 기본값 |
| DB 커넥션 풀 | 최대 20 | JNDI maxActive |

---

## 보안 체크리스트

- [ ] `.env` 파일의 비밀번호를 강력한 값으로 설정 (절대 git에 커밋하지 않음)
- [ ] `was/db_secret.yaml`의 플레이스홀더를 실제 값으로 교체 후 배포
- [ ] Tomcat Manager 비활성화 또는 접근 제한
- [ ] Nginx HTTPS/TLS 설정
- [ ] 정기적 컨테이너 이미지 취약점 스캔 (ECR scan_on_push 활성화됨)

---

## 트러블슈팅

### Tomcat이 시작되지 않음 (MySQL 연결 실패)

증상: `docker-compose logs tomcat` 에서 `Communications link failure` 오류

원인: MySQL 헬스체크 완료 전에 Tomcat이 연결 시도

```bash
# MySQL 헬스 상태 확인
docker inspect community-mysql --format='{{.State.Health.Status}}'

# healthy 확인 후 Tomcat 재시작
docker-compose restart tomcat
```

### 포트 80이 이미 사용 중

증상: `Bind for 0.0.0.0:80 failed: port is already allocated`

```bash
# 사용 중인 프로세스 확인 (Linux/macOS)
sudo lsof -i :80

# 또는 docker-compose.yml nginx ports를 "8000:80"으로 수정 후 재실행
docker-compose up -d
```

### WAR 빌드 실패

증상: `build/community.war: No such file or directory`

```bash
chmod +x build.sh && ./build.sh
ls -lh build/community.war
```

### DB 데이터 초기화

```bash
docker-compose down -v && docker-compose up -d
```

---

## 제약사항

| 제약 | 내용 | 우회 방법 |
|------|------|----------|
| WAR 사전 빌드 필요 | `build.sh` 실행 없이 이미지 빌드 불가 | CI/CD에서 빌드 자동화 |
| HTTP만 지원 | HTTPS 설정 미포함 | Nginx SSL 또는 Ingress TLS 적용 |
| 단일 DB 인스턴스 | MySQL HA 구성 없음 | K8s StatefulSet 또는 외부 RDS 전환 권장 |

---

## 참고 자료

- [Docker Compose 공식 문서](https://docs.docker.com/compose/)
- [Tomcat 10.1 JNDI DataSource](https://tomcat.apache.org/tomcat-10.1-doc/jndi-datasource-examples-howto.html)
- [MySQL Docker 이미지](https://hub.docker.com/_/mysql)
- [MetalLB 설정 가이드](https://metallb.universe.tf/configuration/)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon ECR 사용 가이드](https://docs.aws.amazon.com/ecr/)

---

## 개발자

**LeeSangheee** — Cloud Engineer / Solutions Architect
[GitHub](https://github.com/LeeSangheee) · [Issues](https://github.com/LeeSangheee/community/issues)
