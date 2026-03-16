#!/bin/sh

# Pass K8s env to JVM system properties
CATALINA_OPTS="$CATALINA_OPTS \
  -DDB_HOST=${DB_HOST} \
  -DDB_PORT=${DB_PORT} \
  -DDB_NAME=${DB_NAME} \
  -DDB_USER=${DB_USER} \
  -DDB_PASSWORD=${DB_PASSWORD}"

# OpenTelemetry Java Agent
# OTEL_EXPORTER_OTLP_ENDPOINT: OTel Collector 서비스 주소 (K8s 환경변수로 주입)
CATALINA_OPTS="$CATALINA_OPTS \
  -javaagent:/opt/opentelemetry-javaagent.jar \
  -Dotel.service.name=community-was \
  -Dotel.service.version=${IMAGE_TAG:-unknown} \
  -Dotel.exporter.otlp.endpoint=${OTEL_EXPORTER_OTLP_ENDPOINT:-http://otel-collector.monitoring.svc:4317} \
  -Dotel.exporter.otlp.protocol=grpc \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -Dotel.traces.exporter=otlp \
  -Dotel.instrumentation.jdbc.enabled=true \
  -Dotel.instrumentation.servlet.enabled=true"

export CATALINA_OPTS
