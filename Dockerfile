# Shell Development Environment
# This Dockerfile provides a complete shell script development environment
# with shellcheck, shfmt, and bats-core installed.

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
    && rm -rf /var/lib/apt/lists/*

# Install shfmt
RUN wget -O /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_amd64 && \
    chmod +x /usr/local/bin/shfmt

# Set working directory
WORKDIR /workspace

# Create a script to run both linters
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Running shellcheck..."\n\
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck --severity=warning\n\
echo ""\n\
echo "Running shfmt..."\n\
find . -name "*.sh" -not -name "*.bats" -type f -print0 | xargs -0 shfmt -i 2 -d\n\
echo ""\n\
echo "All linting checks passed!"\n\
' > /usr/local/bin/lint-shell && \
    chmod +x /usr/local/bin/lint-shell

# Default command
CMD ["lint-shell"]
