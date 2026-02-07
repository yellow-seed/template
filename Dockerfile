# Shell Development Environment
# This Dockerfile provides a complete shell script development environment
# with shellcheck, shfmt, bats-core, and actionlint installed.

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for tool installation
RUN apt-get update && \
    apt-get install -y \
    bats \
    ca-certificates \
    curl \
    git \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy installer and scripts
COPY scripts/ /workspace/scripts/

# Install tools via shared installer
RUN STRICT_MODE=true bash /workspace/scripts/install-tools.sh

# Default command
CMD ["lint-shell"]
