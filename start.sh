#!/bin/bash

set -e

echo "=================================="
echo "Starting WebSSH Container"
echo "=================================="

# Generate SSH host keys if missing
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

echo "Starting SSH daemon..."
/usr/sbin/sshd

sleep 2

echo "Starting WebSSH..."

exec wssh \
    --address=0.0.0.0 \
    --port=29000
