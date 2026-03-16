#!/bin/bash
# 모니터링 스택 배포 스크립트
# 설치 순서: Prometheus → Loki → Tempo → OTel Collector
# (Grafana는 kube-prometheus-stack에 포함)

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
NAMESPACE=monitoring

echo "=== 모니터링 스택 배포 ==="

# ── 네임스페이스 생성 ──────────────────────────────────────────
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# ── Helm 레포 등록 ─────────────────────────────────────────────
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana              https://grafana.github.io/helm-charts
helm repo add open-telemetry       https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# ── 1. kube-prometheus-stack (Prometheus + Grafana + Alertmanager) ──
echo "[1/4] kube-prometheus-stack 설치..."
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace ${NAMESPACE} \
  --values "${SCRIPT_DIR}/kube-prometheus-stack-values.yaml" \
  --wait --timeout 10m

# ── 2. Loki ───────────────────────────────────────────────────
echo "[2/4] Loki 설치..."
helm upgrade --install loki \
  grafana/loki \
  --namespace ${NAMESPACE} \
  --values "${SCRIPT_DIR}/loki-values.yaml" \
  --wait --timeout 5m

# ── 3. Tempo ──────────────────────────────────────────────────
echo "[3/4] Tempo 설치..."
helm upgrade --install tempo \
  grafana/tempo \
  --namespace ${NAMESPACE} \
  --values "${SCRIPT_DIR}/tempo-values.yaml" \
  --wait --timeout 5m

# ── 4. OpenTelemetry Collector (DaemonSet) ─────────────────────
echo "[4/4] OTel Collector 설치..."
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace ${NAMESPACE} \
  --values "${SCRIPT_DIR}/otel-collector-values.yaml" \
  --wait --timeout 5m

# ── 결과 확인 ─────────────────────────────────────────────────
echo ""
echo "=== 배포 완료 ==="
kubectl get pods -n ${NAMESPACE}

echo ""
echo "Grafana 접속:"
echo "  kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n ${NAMESPACE}"
echo "  http://localhost:3000  (admin / changeme)"
