# NUK System — Grafana Stack + Nginx with Let's Encrypt

## Services

- **Grafana** (3000) — Dashboards & visualization
- **Prometheus** (9090) — Metrics collection
- **Loki** (3100) — Log aggregation
- **Promtail** (9080) — Log shipper to Loki
- **Fluent Bit** (514/1514) — Syslog receiver for network devices
- **Uptime Kuma** (3001) — Internet/service monitoring
- **Node Exporter** (9100) — System metrics
- **Nginx** (80/443) — Reverse proxy with HTTPS
- **Certbot** — SSL certificate management

## Nginx & SSL

Nginx fronts **all** Grafana stack services under a single domain with HTTPS:

**Domain:** `https://grafana.home.xomar.com`

### URL Routing

| Path | Service |
|------|---------|
| `/` | Grafana (main dashboard) |
| `/prometheus` | Prometheus |
| `/loki` | Loki |
| `/uptime-kuma` | Uptime Kuma |
| `/node-exporter` | Node Exporter |

## Quick Start

```bash
# 1. Install Ansible collections
ansible-galaxy install -r requirements.yml

# 2. Update inventory (NUC IP, SSH key)
#    Edit inventory/production

# 3. Update domain (if different)
#    Edit group_vars/nuk.yml — nginx_domain and nginx_email

# 4. Deploy
ansible-playbook -i inventory/production playbooks/site.yml

# 5. Access services (all under single domain)
#    https://grafana.home.xomar.com/          — Grafana
#    https://grafana.home.xomar.com/prometheus — Prometheus
#    https://grafana.home.xomar.com/loki      — Loki
#    https://grafana.home.xomar.com/uptime-kuma — Uptime Kuma
#    https://grafana.home.xomar.com/node-exporter — Node Exporter
```

## Directory Layout

```
nuk-system/
├── playbooks/
│   └── site.yml              # Main playbook — uses all 3 roles
├── roles/
│   ├── docker-install/       # Installs Docker on Ubuntu 26.04
│   ├── compose-stack/        # Deploys Grafana stack services
│   └── nginx/                # Nginx reverse proxy + SSL
├── inventory/
│   └── production            # NUC inventory (IP, SSH key)
├── group_vars/
│   └── nuk.yml               # All variables (ports, domains, passwords)
├── requirements.yml          # Ansible collections
├── grafana/provisioning/     # Datasources & dashboards
├── loki/loki-config.yaml     # Log retention config
├── prometheus/prometheus.yml # Scrape targets
├── fluent-bit/               # Syslog receiver config
├── promtail/config.yaml      # Log shipper config
├── setup.sh                  # Data directory initialization
└── README.md                 # This file
```

## Data Storage

All persistent data in `/data0/`:
- `/data0/grafana/` — Grafana databases
- `/data0/prometheus/` — Prometheus data
- `/data0/loki/` — Loki logs
- `/data0/fluent-bit/` — Fluent Bit config
- `/data0/uptime-kuma/` — Uptime Kuma database
- `/data0/nginx/` — Nginx config, SSL certs, logs

## Maintenance

```bash
# View service logs
docker compose -f /opt/nuk-system/docker-compose.yml logs -f

# Restart services
docker compose -f /opt/nuk-system/docker-compose.yml restart

# Update to latest images
docker compose -f /opt/nuk-system/docker-compose.yml pull
docker compose -f /opt/nuk-system/docker-compose.yml up -d

# Check SSL certificate status
docker compose -f /opt/nuk-system/docker-compose.yml exec certbot certbot certificates

# Renew SSL certificates (manual)
docker compose -f /opt/nuk-system/docker-compose.yml exec certbot certbot renew --force-renewal
```

## Nginx SSL Renewal

Certbot runs automatically via the certbot container, renewing certificates every 12 hours.

## Firewall

Ensure ports 80 and 443 are open for HTTP/HTTPS:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Notes

- **DNS:** Ensure `grafana.home.xomar.com` points to the NUC's IP
- **Ports:** 514/1514 for syslog (network devices), 80/443 for web access
- **Retention:** Logs retained 7 days, metrics 30 days (configurable)
- **Security:** SSL/TLS enabled, security headers set, client body limit 50MB
- **Single Domain:** All services accessible via `https://grafana.home.xomar.com` with path-based routing
