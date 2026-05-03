# Shell Development Environment
# This Dockerfile provides a complete shell script development environment
# with mise-managed tools (bats, dotenvx, gh, qlty, terraform).

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for mise and tool installation
RUN apt-get update && \
    apt-get install -y \
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
RUN bash /workspace/scripts/install-tools.sh

# Make mise-managed tools available in PATH
ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:${PATH}"

# Default command
CMD ["qlty", "check", "--all"]
