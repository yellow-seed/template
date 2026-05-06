# Tool Sidecar Environment
# This Dockerfile provides a tool sidecar for repository checks and setup tasks
# with mise-managed tools (bats, dotenvx, gh, node, openspec, prettier, qlty, terraform).

FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for mise and tool installation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy mise config and installer scripts
COPY .mise.toml /workspace/.mise.toml
COPY scripts/ /workspace/scripts/

# Install mise and all tools declared in .mise.toml
RUN STRICT_MODE=true bash /workspace/scripts/install-tools.sh

# Make mise-managed tools available in PATH
ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:${PATH}"
ENV OPENSPEC_TELEMETRY=0
