#!/usr/bin/env bash
# Update golangci-lint to the latest version using official installer

set -euo pipefail

echo "Installing/updating golangci-lint to latest version..."

# Install the latest version using the official installer
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin

# Verify installation
if command -v golangci-lint &> /dev/null; then
    echo "✅ golangci-lint installed successfully!"
    echo "Version: $(golangci-lint --version)"
else
    echo "❌ Failed to install golangci-lint"
    exit 1
fi