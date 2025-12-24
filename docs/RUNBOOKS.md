# 📖 Runbooks

Operational procedures for common tasks and incident response.

---

## 🚀 Deployment Procedures

### Standard Deployment

**When:** Deploying new version to production

**Steps:**

1. **Pre-flight checks**
   ```bash
   # Run health check
   ./scripts/health-check.sh
   
   # Verify all tests pass
   make test
   
   # Check disk space
   df -h
   ```

2. **Create backup**
   ```bash
   ./scripts/backup.sh
   ```

3. **Deploy**
   ```bash
   ./scripts/deploy.sh production
   ```

4. **Verify deployment**
   ```bash
   # Check service health
   curl http://localhost:5300/api/services
   
   # Monitor logs
   docker compose logs -f --tail=100
   ```

5. **Rollback if needed**
   ```bash
   ./scripts/deploy.sh production --rollback
   ```

---

### Emergency Rollback

**When:** Critical bug in production

**Steps:**

1. **Immediate rollback**
   ```bash
   ./scripts/deploy.sh production --rollback
   ```

2. **Verify services**
   ```bash
   ./scripts/health-check.sh
   ```

3. **Notify team**
   ```bash
   curl -X POST http://localhost:5400/send \
     -H "Content-Type: application/json" \
     -d '{"target":"slack","event":"alert","data":{"title":"Emergency Rollback","severity":"critical"}}'
   ```

4. **Post-mortem**
   - Document what went wrong
   - Update tests to catch issue
   - Schedule fix for next release

---

## 🔧 Maintenance Procedures

### Scheduled Maintenance Window

**When:** Weekly Sunday 3-5 AM

**Steps:**

1. **Enable maintenance mode**
   ```bash
   docker exec dashboard python -c "import redis; r=redis.Redis(); r.set('maintenance_mode', 'true')"
   ```

2. **Stop non-critical services**
   ```bash
   docker compose -f docker/optional.yml down
   ```

3. **Perform updates**
   ```bash
   # Update images
   docker compose pull
   
   # Apply security patches
   apt update && apt upgrade -y
   
   # Prune unused resources
   docker system prune -af
   ```

4. **Restart services**
   ```bash
   docker compose up -d
   ```

5. **Disable maintenance mode**
   ```bash
   docker exec dashboard python -c "import redis; r=redis.Redis(); r.delete('maintenance_mode')"
   ```

6. **Verify all services**
   ```bash
   ./scripts/health-check.sh
   ```

---

### Database Maintenance

**When:** Monthly or when performance degrades

**Steps:**

1. **Backup database**
   ```bash
   docker exec postgres pg_dump -U homelab homelab > backup.sql
   ```

2. **Analyze and vacuum**
   ```bash
   docker exec postgres psql -U homelab -c "VACUUM ANALYZE;"
   ```

3. **Check index health**
   ```bash
   docker exec postgres psql -U homelab -c "SELECT * FROM pg_stat_user_indexes;"
   ```

4. **Reindex if needed**
   ```bash
   docker exec postgres psql -U homelab -c "REINDEX DATABASE homelab;"
   ```

---

## 🚨 Incident Response

### Service Down

**Symptoms:** Health check failing, dashboard shows service unhealthy

**Steps:**

1. **Identify affected service**
   ```bash
   docker compose ps
   ```

2. **Check logs**
   ```bash
   docker compose logs {service_name} --tail=200
   ```

3. **Attempt restart**
   ```bash
   docker compose restart {service_name}
   ```

4. **If still failing, check resources**
   ```bash
   docker stats
   df -h
   free -m
   ```

5. **If resource issue, free up space**
   ```bash
   docker system prune -af
   ```

6. **Escalate if unresolved**

---

### High Memory Usage

**Symptoms:** System slow, OOM errors in logs

**Steps:**

1. **Identify memory hogs**
   ```bash
   docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
   ```

2. **Check for memory leaks**
   ```bash
   docker compose logs {service} | grep -i "memory\|oom"
   ```

3. **Restart affected service**
   ```bash
   docker compose restart {service}
   ```

4. **If Ollama, unload unused models**
   ```bash
   curl -X DELETE http://localhost:11434/api/generate
   ```

5. **Adjust memory limits**
   ```yaml
   # In docker-compose.yml
   services:
     {service}:
       deploy:
         resources:
           limits:
             memory: 2G
   ```

---

### AI Inference Failures

**Symptoms:** AI requests timing out or returning errors

**Steps:**

1. **Check Ollama status**
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. **Check model availability**
   ```bash
   docker exec ollama ollama list
   ```

3. **Check GPU utilization** (if applicable)
   ```bash
   nvidia-smi
   ```

4. **Restart Ollama**
   ```bash
   docker compose restart ollama
   ```

5. **Reload models**
   ```bash
   curl http://localhost:11434/api/generate -d '{"model":"llama3.2","prompt":"test"}'
   ```

6. **Check orchestrator logs**
   ```bash
   docker compose logs ai-orchestrator --tail=100
   ```

---

### Database Connection Failures

**Symptoms:** Services can't connect to PostgreSQL/Redis

**Steps:**

1. **Check database container**
   ```bash
   docker compose ps postgres redis
   ```

2. **Test connectivity**
   ```bash
   docker exec postgres pg_isready
   docker exec redis redis-cli ping
   ```

3. **Check connection limits**
   ```bash
   docker exec postgres psql -U homelab -c "SELECT count(*) FROM pg_stat_activity;"
   ```

4. **If maxed out, kill idle connections**
   ```bash
   docker exec postgres psql -U homelab -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND query_start < now() - interval '10 minutes';"
   ```

5. **Restart if needed**
   ```bash
   docker compose restart postgres redis
   ```

---

### Security Incident

**Symptoms:** Unusual activity, unauthorized access attempts

**Steps:**

1. **Isolate affected systems**
   ```bash
   # Block external access
   iptables -I INPUT -p tcp --dport 80 -j DROP
   iptables -I INPUT -p tcp --dport 443 -j DROP
   ```

2. **Capture evidence**
   ```bash
   # Export logs
   docker compose logs > incident_logs_$(date +%Y%m%d).txt
   
   # Export event store
   curl http://localhost:5101/events?limit=10000 > events_backup.json
   ```

3. **Run security audit**
   ```bash
   ./scripts/security/audit.sh
   ```

4. **Rotate secrets**
   ```bash
   # Regenerate all secrets
   ./scripts/rotate-secrets.sh
   ```

5. **Review and restore**
   ```bash
   # Review audit report
   cat /var/log/homelab/security-audit.json
   
   # Restore access when safe
   iptables -D INPUT -p tcp --dport 80 -j DROP
   iptables -D INPUT -p tcp --dport 443 -j DROP
   ```

6. **Document incident**
   - Timeline of events
   - Root cause analysis
   - Remediation steps taken
   - Prevention measures

---

## 📊 Monitoring Procedures

### Daily Health Check

**When:** Every morning

**Steps:**

1. **Review dashboard**
   - http://localhost:5300
   - Check all services green

2. **Check alerts**
   - Review any overnight alerts in Slack

3. **Review resource usage**
   ```bash
   docker stats --no-stream
   df -h
   ```

4. **Verify backups**
   ```bash
   ls -la /var/backups/homelab/
   ```

---

### Weekly Review

**When:** Every Monday

**Steps:**

1. **Review past week's events**
   ```bash
   curl "http://localhost:5101/events?since=$(date -d '7 days ago' +%Y-%m-%d)"
   ```

2. **Check resource trends in Grafana**
   - CPU usage trend
   - Memory usage trend
   - Disk usage trend

3. **Review AI usage**
   ```bash
   curl http://localhost:5200/stats
   ```

4. **Run security audit**
   ```bash
   ./scripts/security/audit.sh
   ```

5. **Update documentation if needed**

---

## 📞 Escalation

| Level | Contact | When |
|-------|---------|------|
| L1 | On-call | Service down > 5 min |
| L2 | Senior Admin | Data loss risk, security incident |
| L3 | External Support | Infrastructure failure |

---

**Remember:** Document everything. Update runbooks when you learn something new.
