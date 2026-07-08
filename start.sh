#!/bin/sh

set -e

mkdir -p /app/ssh
mkdir -p /app/run

# Generate SSH host keys under /app
if [ ! -f /app/ssh/ssh_host_ed25519_key ]; then
    echo "Generating SSH host keys..."

    ssh-keygen -q -t rsa -N "" \
        -f /app/ssh/ssh_host_rsa_key

    ssh-keygen -q -t ecdsa -N "" \
        -f /app/ssh/ssh_host_ecdsa_key

    ssh-keygen -q -t ed25519 -N "" \
        -f /app/ssh/ssh_host_ed25519_key
fi

# Generate sshd_config dynamically
cat >/app/sshd_config <<EOF
Port 22
ListenAddress 0.0.0.0

HostKey /app/ssh/ssh_host_rsa_key
HostKey /app/ssh/ssh_host_ecdsa_key
HostKey /app/ssh/ssh_host_ed25519_key

PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UseDNS no

PidFile /app/run/sshd.pid

Subsystem sftp /usr/lib/ssh/sftp-server
EOF

echo "Starting SSH server..."
/usr/sbin/sshd -D -f /app/sshd_config &

sleep 2

echo "Starting WebSSH..."
exec wssh \
    --address=0.0.0.0 \
    --port=29000
