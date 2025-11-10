# OnionFermenter Configuration Examples

This directory contains example configurations for OnionFermenter with different cryptocurrency types and features.

## Quick Start

### Using Bitcoin (BTC) with Telegram

1. Copy and edit the configuration:
```bash
cp examples/btc-config-example.env my-config.env
nano my-config.env  # Edit with your values
```

2. Create your address file:
```bash
cp examples/btc-addresses-example.txt my-btc-addresses.txt
nano my-btc-addresses.txt  # Add your Bitcoin addresses
```

3. Load configuration and run:
```bash
source my-config.env
make run
```

### Using Monero (XMR) with Telegram

1. Copy and edit the configuration:
```bash
cp examples/xmr-config-example.env my-config.env
nano my-config.env  # Edit with your values
```

2. Create your address file:
```bash
cp examples/xmr-addresses-example.txt my-xmr-addresses.txt
nano my-xmr-addresses.txt  # Add your Monero addresses
```

3. Load configuration and run:
```bash
source my-config.env
make run
```

## Environment Variables

### Required
- `VICTIM_ONION_ID`: Target onion service ID (without .onion suffix)
- `ADDRESS_FILE`: Path to file containing your cryptocurrency addresses

### Optional
- `CURRENCY_TYPE`: BTC (default), XMR, or MONERO
- `TELEGRAM_BOT_TOKEN`: Telegram bot token for notifications
- `TELEGRAM_CHAT_ID`: Telegram chat ID for notifications
- `NREPLICAS`: Number of replicas (Kubernetes only, default: 1)

## Telegram Setup

To enable Telegram notifications:

1. Create a Telegram bot:
   - Open Telegram and search for @BotFather
   - Send `/newbot` and follow instructions
   - Copy the bot token

2. Get your chat ID:
   - Search for @userinfobot on Telegram
   - Send `/start` to get your chat ID

3. Set environment variables:
```bash
export TELEGRAM_BOT_TOKEN=your_bot_token_here
export TELEGRAM_CHAT_ID=your_chat_id_here
```

## Address File Formats

### Bitcoin (BTC)
Bitcoin addresses can be in multiple formats:
- Legacy (1...): 26-35 characters
- SegWit (3...): 26-35 characters  
- Native SegWit (bc1...): 42-62 characters

Put one address per line in the file.

### Monero (XMR)
Monero addresses are 95 characters long and start with 4 or 8:
- Standard address (4...): 95 characters
- Subaddress (8...): 95 characters

Put one address per line in the file.

## 24/7 Operation

### Docker (Recommended)
The Docker deployment automatically restarts containers:
```bash
source my-config.env
make run
```

### Systemd Service
For bare-metal deployments:
```bash
sudo cp ../deploy/onionfermenter.service /etc/systemd/system/
sudo nano /etc/systemd/system/onionfermenter.service  # Edit configuration
sudo systemctl enable onionfermenter
sudo systemctl start onionfermenter
```

### Kubernetes
For production scale deployments:
```bash
source my-config.env
make deploy
```
