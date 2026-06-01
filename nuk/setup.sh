#!/bin/bash
# Setup script — create /data0 directories for each service

set -e

DATA_DIR="/data0"

SERVICES=(
  grafana
  loki
  promtail
  prometheus
  fluent-bit
  uptime-kuma
)

echo "Creating $DATA_DIR service directories..."

for service in "${SERVICES[@]}"; do
  mkdir -p "$DATA_DIR/$service/data"
  echo "  ✓ $DATA_DIR/$service"
done

echo ""
echo "Setup complete. Data directories created in $DATA_DIR"
echo ""
echo "Next steps:"
echo "  1. cp .env.example .env && vim .env"
echo "  2. docker compose up -d"
