@echo off
SET REPO_URL=https://github.com/Ajithcse28/DigitalVault-Marketplace.git

echo ================================================================
echo  DigitalVault Marketplace - GitHub Push Helper (Windows)
echo  Target Repository: %REPO_URL%
echo ================================================================

IF NOT EXIST ".git" (
  git init -b main
)

git remote remove origin 2>nul
git remote add origin %REPO_URL%
git add .
git commit -m "feat: full-stack DigitalVault marketplace with Razorpay & Vercel config"
git branch -M main
git push -u origin main

echo.
echo Successfully pushed! Now import Ajithcse28/DigitalVault-Marketplace at https://vercel.com/new
pause
