#!/bin/bash
#
# Skills Directory Setup Script
#
# This script provides a fallback for environments where symlinks are not supported
# (e.g., Windows without admin privileges, Git with core.symlinks=false).
#
# If .claude/skills or .codex/skills are not directories (e.g., text files containing the symlink path),
# this script will copy .github/skills to those directories.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAUDE_SKILLS="${REPO_ROOT}/.claude/skills"
CODEX_SKILLS="${REPO_ROOT}/.codex/skills"
GITHUB_SKILLS="${REPO_ROOT}/.github/skills"

# Check if .github/skills exists
if [ ! -d "${GITHUB_SKILLS}" ]; then
  echo "✗ Error: .github/skills directory not found"
  exit 1
fi

setup_skills_dir() {
  local target_dir="$1"
  local dir_name="$2"

  echo "Checking ${dir_name} setup..."

  # Check if target directory exists and is a directory
  if [ -d "${target_dir}" ]; then
    echo "✓ ${dir_name} is already a directory (symlink or real directory)"
    return 0
  fi

  # Remove the file if it exists (e.g., text file from failed symlink)
  if [ -e "${target_dir}" ]; then
    echo "⚠ Removing non-directory ${dir_name}..."
    rm -f "${target_dir}"
  fi

  # Copy .github/skills to target directory
  echo "Copying .github/skills to ${dir_name}..."
  cp -r "${GITHUB_SKILLS}" "${target_dir}"

  echo "✓ Successfully set up ${dir_name}"
}

# Set up both .claude/skills and .codex/skills
setup_skills_dir "${CLAUDE_SKILLS}" ".claude/skills"
setup_skills_dir "${CODEX_SKILLS}" ".codex/skills"

echo ""
echo "Note: In environments with symlink support, .claude/skills and .codex/skills are symlinks to .github/skills."
echo "In this environment, they have been created as copies."
echo "Please ensure to manually sync changes between .github/skills and these directories if needed."
