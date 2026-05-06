#!/usr/bin/env bash
# push-to-github.sh
# Run this once after downloading/unzipping the project folder.
# Creates a local git repo and pushes to a new GitHub repository.
set -euo pipefail

if [ -z "${GITHUB_REPO:-}" ]; then
  echo "Usage: GITHUB_REPO=<org-or-user>/<repo-name> ./push-to-github.sh"
  echo "Example: GITHUB_REPO=acme/demo-app ./push-to-github.sh"
  exit 1
fi

git init
git config user.email "${GIT_EMAIL:-$(git config --global user.email)}"
git config user.name  "${GIT_NAME:-$(git config --global user.name)}"
git branch -m main
git add .
git commit -m "Initial commit: Spring Boot API + React frontend + Curity + PostgreSQL"

echo ""
echo "Go to https://github.com/new and create the repository '${GITHUB_REPO}' (empty, no README)."
echo "Then press Enter here to push…"
read -r

git remote add origin "git@github.com:${GITHUB_REPO}.git"
git push -u origin main

echo ""
echo "✅  Pushed to https://github.com/${GITHUB_REPO}"
