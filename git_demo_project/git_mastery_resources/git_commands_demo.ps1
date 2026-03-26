# Git & GitHub Operational Mastery: Command Test Script (.ps1)
# -----------------------------------------------------------------------------
# PURPOSE: This script contains real-world command variants for testing and learning.
# USAGE: Open PowerShell in your 'git_demo_project' directory and copy-paste these blocks.
# -----------------------------------------------------------------------------

# --- 1. CONFIGURATION & IDENTITY ---
# git config --global user.name "Your Name"
# git config --global user.email "your.email@example.com"
# git config --list --show-origin

# --- 2. LOCAL WORKFLOW ---
# Create a new file
# New-Item -Path "app.py" -ItemType "file" -Value "print('Hello Git')"

# Check status (Short format)
# git status -s

# Stage changes
# git add app.py

# Commit with a clear message
# git commit -m "Add core application logic"

# Undo the last commit but keep changes (Soft Reset)
# git reset --soft HEAD~1

# Amend the last commit
# git commit --amend --no-edit

# --- 3. BRANCHING & MERGING ---
# Create and switch to a feature branch
# git switch -c feature/v1

# Add more changes
# Set-Content -Path "app.py" -Value "print('Hello Git V1')"
# git add app.py
# git commit -m "Upgrade app to V1"

# Switch back to main
# git switch main

# Merge feature branch (Fast-forward if possible)
# git merge feature/v1

# Delete the branch after merge
# git branch -d feature/v1

# --- 4. ADVANCED HISTORY (REBASE & REFLOG) ---
# Interactive rebase (Pick the last 3 commits to squash/reword)
# git rebase -i HEAD~3

# View Reflog if you accidentally deleted something
# git reflog

# --- 5. STASHING ---
# Save work without committing
# git stash push -m "Work in progress on auth"

# List stashes
# git stash list

# Apply and remove the latest stash
# git stash pop

# --- 6. DISASTER RECOVERY ---
# Revert a commit (Create an inverse commit)
# git revert <commit_id>

# Remove untracked files (DANGEROUS: deletes files not in git)
# git clean -fd

# --- 7. ADVANCED INSPECTION (BLAME & CHERRY-PICK) ---
# See who changed a specific line
# git blame -L 1,5 README.md

# Cherry-pick a specific commit from another branch
# git cherry-pick <commit_id>

# --- 8. REMOTE MANAGEMENT ---
# Add a new remote
# git remote add upstream https://github.com/original-repo/project.git

# Rename a remote
# git remote rename origin github-origin

# --- 9. BINARY SEARCH (BISECT) ---
# git bisect start
# git bisect bad HEAD
# git bisect good <commit_id>
# (Test code...)
# git bisect good  # or git bisect bad
# git bisect reset

# --- 10. GITHUB ACTIONS (CI/CD ENHANCED) ---
# Ensure you have .github/workflows directory
# New-Item -Path ".github/workflows" -ItemType "directory" -Force
# Copy the YAML below into .github/workflows/ci_advanced.yml

# name: Git-Demo-Advanced-CI
# on: 
#   push:
#     branches: [ main, develop ]
#   pull_request:
#     branches: [ main ]
#
# jobs:
#   lint:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - name: Check formatting
#         run: echo "Linting code..."
#
#   test:
#     needs: lint
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v4
#       - name: Run logic tests
#         run: echo "Running tests..."
#       - name: Print secrets placeholder
#         run: echo "Secret is ${{ secrets.APP_API_KEY }}"
