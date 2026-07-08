#!/bin/sh

set -e

mkdir -p /run/sshd

# Generate host keys only if they don't exist
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

echo "Starting SSH server..."
/usr/sbin/sshd -D &
sleep 2

echo "Starting WebSSH..."
exec wssh \
    --address=0.0.0.0 \
    --port=29000
