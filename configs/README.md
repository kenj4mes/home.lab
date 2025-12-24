# 📁 Configs

Service configuration files for HomeLab containers.

## Structure

| Directory | Service | Description |
|-----------|---------|-------------|
| `alertmanager/` | Alertmanager | Alert routing configuration |
| `aria2/` | Aria2 | Download manager config |
| `comfyui/` | ComfyUI | Node-based image gen config |
| `grafana/` | Grafana | Dashboard provisioning |
| `homeassistant/` | Home Assistant | Smart home automation |
| `kiwix/` | Kiwix | Offline knowledge server |
| `nginx/` | Nginx | Web server configs |
| `nginx-proxy/` | NPM | Nginx Proxy Manager |
| `nitter/` | Nitter | Twitter frontend |
| `pihole/` | Pi-hole | DNS ad blocking |
| `pq-nginx/` | PQ-NGINX | Post-quantum TLS config |
| `prometheus/` | Prometheus | Metrics scrape configs |
| `promtail/` | Promtail | Log collection |
| `stable-diffusion/` | SD WebUI | Image generation |
| `synapse/` | Matrix Synapse | Chat server config |
| `vault/` | HashiCorp Vault | Secrets management |
| `youtube/` | YouTube tools | Archive configs |

## Usage

Configs are mounted into containers via Docker Compose volumes:

```yaml
volumes:
  - ./configs/prometheus:/etc/prometheus:ro
```

## Customization

1. Copy the default config
2. Edit for your environment
3. Restart the service: `docker compose restart <service>`
