# Shell Development Environment
# This Dockerfile provides a complete shell script development environment
# with shellcheck, shfmt, bats-core, and actionlint installed.

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install shellcheck and dependencies
RUN apt-get update && \
    apt-get install -y \
    shellcheck \
    wget \
    git \
    bats \
    curl \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.23 (required for shfmt v3.12.0)
RUN wget -O /tmp/go.tar.gz https://go.dev/dl/go1.23.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# Install shfmt via go install (secure and maintainable)
RUN go install mvdan.cc/sh/v3/cmd/shfmt@v3.12.0 && \
    mv /root/go/bin/shfmt /usr/local/bin/shfmt

# Install actionlint via go install (secure and maintainable)
RUN go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.5 && \
    mv /root/go/bin/actionlint /usr/local/bin/actionlint

# Install Prettier
RUN npm install -g prettier@3.4.2

# Set working directory
WORKDIR /workspace

# Install lint helper scripts
COPY scripts/lint-shell.sh /usr/local/bin/lint-shell
COPY scripts/lint-docs.sh /usr/local/bin/lint-docs
RUN chmod +x /usr/local/bin/lint-shell /usr/local/bin/lint-docs

# Default command
CMD ["lint-shell"]
