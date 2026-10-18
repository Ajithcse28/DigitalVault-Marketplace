#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/Ajithcse28/DigitalVault-Marketplace.git"

echo "================================================================"
echo " DigitalVault Marketplace — GitHub Push Helper"
echo " Target Repository: $REPO_URL"
echo "================================================================"

if [ ! -d ".git" ]; then
  git init -b main
fi

git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

git add .
git commit -m "feat: full-stack DigitalVault marketplace with Razorpay & Vercel config" || true
git branch -M main

echo "Pushing to $REPO_URL (main)..."
git push -u origin main

echo ""
echo "Successfully pushed to GitHub!"
echo "Next step: Open https://vercel.com/new and import Ajithcse28/DigitalVault-Marketplace"
