# Install Git on Windows

## Quick Installation

### Option 1: Download Git for Windows (Recommended)

1. **Download Git**:
   - Go to: https://git-scm.com/download/win
   - The download should start automatically
   - Or click "Click here to download manually"

2. **Run the Installer**:
   - Double-click the downloaded `.exe` file
   - Click "Next" through the installation wizard
   - **Recommended settings**:
     - ✅ Use Git from Git Bash only (or "Git from the command line and also from 3rd-party software")
     - ✅ Use bundled OpenSSH
     - ✅ Use the OpenSSL library
     - ✅ Checkout Windows-style, commit Unix-style line endings
     - ✅ Use MinTTY (the default terminal of MSYS2)
     - ✅ Default (fast-forward or merge)
     - ✅ Git Credential Manager
     - ✅ Enable file system caching
     - ✅ Enable symbolic links

3. **Verify Installation**:
   - Open a **new** PowerShell or Command Prompt window
   - Run: `git --version`
   - You should see: `git version 2.x.x.windows.x`

### Option 2: Install via Winget (Windows Package Manager)

If you have Windows 10/11 with winget:

```powershell
# Install Git
winget install --id Git.Git -e --source winget

# Verify installation
git --version
```

### Option 3: Install via Chocolatey

If you have Chocolatey package manager:

```powershell
# Install Git
choco install git -y

# Verify installation
git --version
```

## After Installation

### 1. Configure Git (First Time Setup)

Open PowerShell or Git Bash and run:

```bash
# Set your name
git config --global user.name "Your Name"

# Set your email
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

### 2. Configure Line Endings (Important for Windows)

```bash
# Configure line endings for cross-platform compatibility
git config --global core.autocrlf true
```

### 3. Test Git Commands

```bash
# Navigate to your project
cd "C:\Users\Rishabh - PC\Desktop\serverless-microservices"

# Check git status
git status

# If you see files, you're ready to commit!
```

## Commit and Push Your Changes

Once Git is installed and configured:

```bash
# Stage all changes
git add .

# Commit with message
git commit -m "feat: Add Bedrock resilience with exponential backoff and multi-region fallback"

# Push to remote
git push origin main
```

## Troubleshooting

### Issue: "git: command not found" after installation

**Solution**: Close and reopen your terminal (PowerShell/CMD) to refresh the PATH.

### Issue: Authentication failed when pushing

**Solution 1 - Use Personal Access Token (GitHub)**:
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token (classic) with `repo` scope
3. Use token as password when prompted

**Solution 2 - Use Git Credential Manager**:
```bash
# This should be installed by default with Git for Windows
git config --global credential.helper manager
```

### Issue: Line ending warnings

**Solution**:
```bash
git config --global core.autocrlf true
```

### Issue: Permission denied (publickey)

**Solution**: Use HTTPS instead of SSH:
```bash
# Check current remote URL
git remote -v

# If it shows git@github.com, change to HTTPS
git remote set-url origin https://github.com/yourusername/your-repo.git
```

## Alternative: Use GitHub Desktop

If you prefer a GUI:

1. Download GitHub Desktop: https://desktop.github.com/
2. Install and sign in with your GitHub account
3. Open your repository in GitHub Desktop
4. It will show all your changes
5. Write commit message and click "Commit to main"
6. Click "Push origin" to push changes

## Quick Reference

```bash
# Check Git version
git --version

# Check Git configuration
git config --list

# Check repository status
git status

# Stage all changes
git add .

# Commit changes
git commit -m "your message"

# Push to remote
git push origin main

# Pull from remote
git pull origin main
```

## Next Steps After Installing Git

1. **Install Git** using one of the methods above
2. **Close and reopen** your terminal/PowerShell
3. **Configure Git** with your name and email
4. **Navigate to project**: `cd "C:\Users\Rishabh - PC\Desktop\serverless-microservices"`
5. **Run git commands**:
   ```bash
   git add .
   git commit -m "feat: Add Bedrock resilience with exponential backoff and multi-region fallback"
   git push origin main
   ```
6. **On EC2**: Pull changes and deploy
   ```bash
   cd ~/aws-serverless-microservices-ai
   git pull origin main
   cd agent-service
   bash deploy-resilience-fix.sh
   ```

## Download Links

- **Git for Windows**: https://git-scm.com/download/win
- **GitHub Desktop**: https://desktop.github.com/
- **Git Documentation**: https://git-scm.com/doc

---

**Estimated Time**: 5-10 minutes for installation and configuration
