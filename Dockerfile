# -----------------------------------------------------------------------------
# Stage 1 - Builder
# -----------------------------------------------------------------------------
FROM python:3.12-slim-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /build

COPY requirements.txt .

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Install WebSSH
RUN pip install \
        --no-cache-dir \
        --prefix=/install \
        -r requirements.txt

# Generate SSH host keys
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    ls -l /etc/ssh/ssh_host_*

# -----------------------------------------------------------------------------
# Stage 2 - Runtime
# -----------------------------------------------------------------------------
FROM python:3.12-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        openssh-client \
        bash \
        dumb-init && \
    rm -rf /var/lib/apt/lists/*

# Create login user
RUN useradd -m -s /bin/bash gcp && \
    echo "gcp:changeme" | chpasswd

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "UseDNS no" >> /etc/ssh/sshd_config

# Copy Python packages
COPY --from=builder /install /usr/local

# Copy pre-generated SSH host keys
COPY --from=builder /etc/ssh/ssh_host_* /etc/ssh/

# Startup script
COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 22
EXPOSE 29000

ENTRYPOINT ["/usr/bin/dumb-init","--"]

CMD ["/start.sh"]
