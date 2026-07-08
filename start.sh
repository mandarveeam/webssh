#!/bin/bash

set -ex

echo "=================================="
echo "Starting WebSSH Container"
echo "=================================="

echo "Current user:"
id

echo "SSH host keys:"
ls -l /etc/ssh/ssh_host_* || true

echo "Starting SSH daemon..."
/usr/sbin/sshd -D -e &

sleep 2

echo "Starting WebSSH..."
exec wssh \
    --address=0.0.0.0 \
    --port=29000
