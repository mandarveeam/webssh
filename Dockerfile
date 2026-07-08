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
        dumb-init

# Create login user
RUN adduser -D -h /home/gcp -s /bin/bash gcp \
    && echo "gcp:changeme" | chpasswd

# Create writable directories
RUN mkdir -p \
        /app/ssh \
        /app/run \
        /app/logs

# Copy Python packages
COPY --from=builder /install /usr/local

# Startup script
COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 22
EXPOSE 29000

ENTRYPOINT ["/usr/bin/dumb-init","--"]

CMD ["/start.sh"]
