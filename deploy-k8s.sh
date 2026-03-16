#!/bin/bash
# EKS 배포 스크립트
# 사전 조건:
#   1. terraform apply 완료 (EKS 클러스터 생성)
#   2. .env 파일 작성 (AWS_ACCOUNT_ID, AWS_REGION, EKS_CLUSTER_NAME 등)
#   3. AWS Load Balancer Controller Helm 설치 (최초 1회)

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "오류: .env 파일이 없습니다. .env.example을 복사해서 만들어주세요."
  echo "  cp .env.example .env"
  exit 1
fi

export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)

# ---- kubeconfig 업데이트 ----
echo "=== kubeconfig 설정 ==="
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${EKS_CLUSTER_NAME}"

# ---- AWS Load Balancer Controller 설치 (최초 1회) ----
if ! kubectl get deployment aws-load-balancer-controller -n kube-system &>/dev/null; then
  echo "=== AWS Load Balancer Controller 설치 ==="
  helm repo add eks https://aws.github.io/eks-charts
  helm repo update
  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName="${EKS_CLUSTER_NAME}" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${ALB_CONTROLLER_ROLE_ARN}"
fi

# ---- 네임스페이스 생성 ----
kubectl create namespace was --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -

echo "=== 애플리케이션 배포 ==="
echo "Account: ${AWS_ACCOUNT_ID} / Region: ${AWS_REGION} / Cluster: ${EKS_CLUSTER_NAME}"

# WAS
kubectl apply -f "$SCRIPT_DIR/was/db_config.yaml"
kubectl apply -f "$SCRIPT_DIR/was/db_secret.yaml"
envsubst < "$SCRIPT_DIR/was/tomcat-deployment.yaml" | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/was/tomcat-service.yaml"
kubectl apply -f "$SCRIPT_DIR/was/tomcat-hpa.yaml"

# Web
envsubst < "$SCRIPT_DIR/web/nginx-deployment.yaml" | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/web/nginx-service.yaml"
kubectl apply -f "$SCRIPT_DIR/web/web-ingress.yaml"

echo ""
echo "=== 배포 완료 ==="
kubectl get pods -n was
kubectl get pods -n web
echo ""
echo "ALB 주소 확인 (생성까지 1-2분 소요):"
echo "  kubectl get ingress web-ingress -n web"
