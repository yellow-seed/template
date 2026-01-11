#!/bin/bash
#
# Skills Directory Setup Script
#
# This script provides a fallback for environments where symlinks are not supported
# (e.g., Windows without admin privileges, Git with core.symlinks=false).
#
# If .claude/skills is not a directory (e.g., it's a text file containing the symlink path),
# this script will copy .github/skills to .claude/skills.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAUDE_SKILLS="${REPO_ROOT}/.claude/skills"
GITHUB_SKILLS="${REPO_ROOT}/.github/skills"

echo "Checking .claude/skills setup..."

# Check if .claude/skills exists and is a directory
if [ -d "${CLAUDE_SKILLS}" ]; then
  echo "✓ .claude/skills is already a directory (symlink or real directory)"
  exit 0
fi

# Check if .github/skills exists
if [ ! -d "${GITHUB_SKILLS}" ]; then
  echo "✗ Error: .github/skills directory not found"
  exit 1
fi

# Remove the file if it exists (e.g., text file from failed symlink)
if [ -e "${CLAUDE_SKILLS}" ]; then
  echo "⚠ Removing non-directory .claude/skills..."
  rm -f "${CLAUDE_SKILLS}"
fi

# Copy .github/skills to .claude/skills
echo "Copying .github/skills to .claude/skills..."
cp -r "${GITHUB_SKILLS}" "${CLAUDE_SKILLS}"

echo "✓ Successfully set up .claude/skills"
echo ""
echo "Note: In environments with symlink support, .claude/skills is a symlink to .github/skills."
echo "In this environment, .claude/skills has been created as a copy."
echo "Please ensure to manually sync changes between .github/skills and .claude/skills if needed."
