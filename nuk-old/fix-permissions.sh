#!/bin/bash
set -e

echo "=== Fixing Grafana Stack Permissions ==="

BASE="/data0/grafana-inc"

# Fix ownership for container UIDs
echo "Fixing grafana-data (uid 472)..."
sudo chown -R 472:0 "$BASE/grafana-data"

echo "Fixing prometheus-data (uid 65534)..."
sudo chown -R 65534:0 "$BASE/prometheus-data"

echo "Fixing alertmanager-data (uid 65534)..."
sudo chown -R 65534:0 "$BASE/alertmanager-data"

echo "Fixing loki-data (uid 10001)..."
sudo chown -R 10001:0 "$BASE/loki-data"

echo "Fixing tempo-data (uid 10001)..."
sudo chown -R 10001:0 "$BASE/tempo-data"

# Copy updated configs
echo "Copying updated configs..."
cp ~/nuk/docker-compose.yml "$BASE/docker-compose.yml"
cp ~/nuk/alertmanager.yml "$BASE/alertmanager-config/alertmanager.yml"

# Restart stack
echo "Restarting stack..."
cd "$BASE"
sudo docker compose down
sudo docker compose up -d

echo ""
echo "=== Done ==="
echo "Check status: docker ps"
