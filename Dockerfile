# -----------------------------------------------------------------------------
# Stage 1 - Builder
# -----------------------------------------------------------------------------
FROM python:3.12-slim-bookworm AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install \
        --no-cache-dir \
        --prefix=/install \
        -r requirements.txt

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

# Create runtime directories
RUN mkdir -p \
        /var/run/sshd \
        /app/logs

# SSH configuration
RUN sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "UsePAM no" >> /etc/ssh/sshd_config && \
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config && \
    echo "UseDNS no" >> /etc/ssh/sshd_config

COPY --from=builder /install /usr/local

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 22
EXPOSE 29000

ENTRYPOINT ["/usr/bin/dumb-init","--"]

CMD ["/start.sh"]
