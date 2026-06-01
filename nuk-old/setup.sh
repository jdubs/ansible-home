#!/bin/bash
set -e

echo "=== Nuk Grafana Stack Setup ==="

# Phase 0: Check sudo access
if ! sudo -n true 2>/dev/null; then
    echo "WARNING: sudo requires password. Setting up passwordless sudo for current user..."
    echo "Please enter your password once for sudo:"
    USERNAME=$(whoami)
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-$USERNAME
    echo "Passwordless sudo configured."
fi

# 1. Mount NVMe to /data0
echo "[1/6] Mounting NVMe drive to /data0..."
if ! mountpoint -q /data0; then
    sudo mkdir -p /data0
    sudo mount /dev/nvme0n1p1 /data0
    if ! grep -q "nvme0n1p1" /etc/fstab; then
        echo "/dev/nvme0n1p1 /data0 ext4 defaults 0 2" | sudo tee -a /etc/fstab
        echo "  Added to fstab"
    fi
else
    echo "  /data0 already mounted"
fi

# 2. Apply netplan config
echo "[2/6] Applying netplan configuration..."
if [ -f /tmp/50-netplan.yaml ]; then
    sudo cp /tmp/50-netplan.yaml /etc/netplan/50-netplan.yaml
    sudo rm -f /etc/netplan/00-installer-config.yaml
    sudo netplan apply
    echo "  Netplan applied (IP: 192.168.1.209, VLAN.15: 192.168.15.209)"
else
    echo "  WARNING: /tmp/50-netplan.yaml not found - skip netplan update"
fi

# 3. Create directory structure
echo "[3/6] Creating directory structure..."
BASE="/data0/grafana-inc"
sudo mkdir -p "$BASE"/{loki-config,loki-data,prometheus-config,prometheus-data,alertmanager-config,alertmanager-data,tempo-config,tempo-data,grafana-data,grafana-provisioning/datasources,grafana-provisioning/dashboards,docker-config,promtail-config,rsyslog-config,blackbox-config}
sudo chown -R $(id -u):$(id -g) "$BASE"

# Fix ownership for container UIDs
sudo chown -R 472:0 "$BASE/grafana-data"
sudo chown -R 65534:0 "$BASE/prometheus-data"
sudo chown -R 65534:0 "$BASE/alertmanager-data"
sudo chown -R 10001:0 "$BASE/loki-data"
sudo chown -R 10001:0 "$BASE/tempo-data"

# 4. Copy configs
echo "[4/6] Copying configuration files..."
if [ -d ~/nuk ]; then
    cp ~/nuk/loki-config.yaml "$BASE/loki-config/"
    cp ~/nuk/prometheus-config.yaml "$BASE/prometheus-config/"
    cp ~/nuk/alertmanager.yml "$BASE/alertmanager-config/"
    cp ~/nuk/tempo-config.yaml "$BASE/tempo-config/"
    cp ~/nuk/grafana.ini "$BASE/"
    cp ~/nuk/grafana-provisioning/datasources/datasources.yaml "$BASE/grafana-provisioning/datasources/datasources.yaml"
    cp ~/nuk/grafana-provisioning/dashboards/dashboards.yaml "$BASE/grafana-provisioning/dashboards/dashboards.yaml"
    cp ~/nuk/dashboards/*.json "$BASE/grafana-provisioning/dashboards/"
    cp ~/nuk/blackbox-config.yaml "$BASE/blackbox-config/"
    cp ~/nuk/promtail-config.yaml "$BASE/promtail-config/"
    cp ~/nuk/docker-compose.yml "$BASE/docker-compose.yml"
    echo "  Configs copied"
else
    echo "  ERROR: ~/nuk not found"
    exit 1
fi

# 5. Install Docker
echo "[5/6] Installing Docker..."
if command -v docker &>/dev/null; then
    echo "  Docker already installed ($(docker --version))"
else
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $(whoami)
    echo "  Docker installed (re-login required for group)"
fi

# 6. Install rsyslog for syslog collection
echo "[6/7] Installing rsyslog..."
if ! command -v rsyslogd &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y rsyslog
    echo "  rsyslog installed"
else
    echo "  rsyslog already installed"
fi
sudo cp ~/nuk/rsyslog.conf /etc/rsyslog.d/50-remote.conf
sudo mkdir -p /data0/syslog
sudo chown syslog:adm /data0/syslog
sudo chmod 775 /data0/syslog

# Add /data0/syslog to AppArmor profile for rsyslog
sudo sed -i "/# Site-specific additions/i\\  # Centralized syslog collection\\n  /data0/syslog/** rwk," /etc/apparmor.d/usr.sbin.rsyslogd
sudo systemctl reload apparmor

sudo systemctl restart rsyslog
echo "  rsyslog configured (listening on UDP/TCP 514, writing to /data0/syslog/\$host)"

# 7. Start stack
echo "[7/7] Starting Grafana stack..."
cd "$BASE"
sudo docker compose up -d

echo ""
echo "=== Setup Complete ==="
echo "Grafana: http://192.168.1.209:3000 (admin/admin)"
echo "Prometheus: http://192.168.1.209:9090"
echo "Loki: http://192.168.1.209:3100"
echo "Tempo: http://192.168.1.209:3200"
echo "Alertmanager: http://192.168.1.209:9093"
echo "Node Exporter: http://192.168.1.209:9100"
