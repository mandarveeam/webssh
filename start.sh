#!/bin/sh

set -e

echo "Starting SSH server..."
/usr/sbin/sshd

echo "Starting WebSSH..."
exec wssh \
    --address=0.0.0.0 \
    --port=29000
