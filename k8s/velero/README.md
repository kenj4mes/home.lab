# Velero Backup Configuration

Kubernetes disaster recovery with Velero.

## Files

| File | Description |
|------|-------------|
| `backup-storage.yaml` | S3-compatible backup storage location |
| `backup-schedules.yaml` | Automated backup schedules (daily/hourly/weekly) |
| `restore-templates.yaml` | Restore procedures for common scenarios |

## Installation

```bash
# Install Velero CLI
wget https://github.com/vmware-tanzu/velero/releases/download/v1.13.0/velero-v1.13.0-linux-amd64.tar.gz
tar -xvf velero-v1.13.0-linux-amd64.tar.gz
sudo mv velero-v1.13.0-linux-amd64/velero /usr/local/bin/

# Create credentials file
cat > credentials-velero <<EOF
[default]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_KEY
EOF

# Install Velero (with MinIO/S3 backend)
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.9.0 \
  --bucket homelab-backups \
  --secret-file ./credentials-velero \
  --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio:9000

# Apply schedules
kubectl apply -f .
```

## Backup Schedules

| Schedule | Frequency | Retention | Namespaces |
|----------|-----------|-----------|------------|
| daily-backup | 3 AM daily | 7 days | All except velero |
| hourly-database | Every hour | 24 backups | databases |
| weekly-full | Sunday 2 AM | 4 weeks | All |
| critical-services | Every 4 hours | 6 backups | monitoring, security, databases |

## Manual Operations

```bash
# Create manual backup
velero backup create manual-backup --include-namespaces default

# List backups
velero backup get

# Restore from backup
velero restore create --from-backup daily-backup-20241224

# Check backup status
velero backup describe daily-backup-20241224
```

## Related

- [Velero Documentation](https://velero.io/docs/)
- [Installation Guide](../../docs/INSTALLATION.md)
