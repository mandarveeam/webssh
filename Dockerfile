# -----------------------------------------------------------------------------
# Stage 1 - Build
# -----------------------------------------------------------------------------
FROM python:3.12.7-alpine3.20 AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    --prefix=/install \
    -r requirements.txt

# -----------------------------------------------------------------------------
# Stage 2 - Runtime
# -----------------------------------------------------------------------------
FROM python:3.12.7-alpine3.20

WORKDIR /app

RUN apk add --no-cache \
        bash \
        shadow \
        openssh \
        openssh-server \
        openssh-client \
        dumb-init \
    && adduser -D -s /bin/bash gcp \
    && echo "gcp:changeme" | chpasswd \
    && mkdir -p /run/sshd \
    && sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config \
    && echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config \
    && echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config \
    && echo "Subsystem sftp /usr/lib/ssh/sftp-server" >> /etc/ssh/sshd_config

COPY --from=builder /install /usr/local

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 22
EXPOSE 29000

ENTRYPOINT ["/usr/bin/dumb-init","--"]

CMD ["/start.sh"]
