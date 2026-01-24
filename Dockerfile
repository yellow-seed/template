# Development Environment
# This Dockerfile provides a complete development environment with:
# - Shell: shellcheck, shfmt, bats-core
# - GitHub Actions: actionlint
# - Documentation: prettier (for Markdown, YAML, JSON)

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install shellcheck, Node.js and dependencies
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

# Install prettier globally for document formatting
RUN npm install -g prettier@3.4.2

# Set working directory
WORKDIR /workspace

# Create a script to run shell linters
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Running shellcheck..."\n\
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck --severity=warning\n\
echo ""\n\
echo "Running shfmt..."\n\
find . -name "*.sh" -not -name "*.bats" -type f -print0 | xargs -0 shfmt -i 2 -d\n\
echo ""\n\
echo "All shell linting checks passed!"\n\
' > /usr/local/bin/lint-shell && \
    chmod +x /usr/local/bin/lint-shell

# Create a script to run document linters
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Running Prettier check on Markdown files..."\n\
prettier --check "**/*.md"\n\
echo ""\n\
echo "Running Prettier check on YAML files..."\n\
prettier --check "**/*.{yml,yaml}"\n\
echo ""\n\
echo "Running Prettier check on JSON files..."\n\
prettier --check "**/*.json"\n\
echo ""\n\
echo "All document formatting checks passed!"\n\
' > /usr/local/bin/lint-docs && \
    chmod +x /usr/local/bin/lint-docs

# Default command
CMD ["lint-shell"]
