# Git & GitHub Operational Mastery Guide

This guide is an operational system for senior engineers. It focuses on the internal mechanics, precise command syntax, and real-world recovery scenarios.

---

## Phase 1: Environment Setup & Repository Initialization

### 1.1 Global Configuration & Security
Before any repository exists, the environment must be hardened and standardized.

**Internal Model:** Git reads configurations from three levels:
1. `system`: (/etc/gitconfig) - All users.
2. `global`: (~/.gitconfig) - Current user.
3. `local`: (.git/config) - Specific repository.

**Commands:**
```bash
# Set identity (Global)
git config --global user.name "John Doe"
git config --global user.email "jdoe@example.com"

# Set default branch name (prevent legacy 'master' issues)
git config --global init.defaultBranch main

# Security: Enable GPG signing for all commits
git config --global commit.gpgsign true
git config --global user.signingkey <GPG_KEY_ID>

# Performance: Parallelize fetching
git config --global fetch.parallel 0

# Review configurations
git config --list --show-origin
```

### 1.2 SSH vs HTTPS Authentication
**SSH** is preferred for automation and security via keyed access. **HTTPS** is often used for read-only access or behind restrictive firewalls (using Personal Access Tokens).

**Setup Workflow (SSH):**
1. Generate key: `ssh-keygen -t ed25519 -C "jdoe@example.com"`
2. Add to agent: `ssh-add ~/.ssh/id_ed25519`
3. Add public key to GitHub Settings -> SSH keys.

### 1.3 Repository Initialization & Cloning Variants
**Internal Model:** `git init` creates the `.git` directory—the "heart" containing the object database, refs, and configuration.

**Commands:**
*   **Standard Init:** `git init`
*   **Bare Repository (Server-side):** `git init --bare`
    *   *When:* Creating a central sync point without a working directory.
*   **Cloning Variants:**
    ```bash
    # Standard clone
    git clone git@github.com:user/repo.git

    # Shallow clone (History truncation for performance)
    git clone --depth 1 git@github.com:user/repo.git
    # Use: CI/CD pipelines where history is irrelevant.

    # Mirror clone (Exact copy of all refs)
    git clone --mirror git@github.com:user/repo.git
    # Use: Migrating between GitHub and GitLab.

    # Partial clone (Blob filtering)
    git clone --filter=blob:none git@github.com:user/repo.git
    # Use: Massive monorepos where you only need the commit graph.
    ```

---

## Phase 2: Local Development & Internal State

### 2.1 The Three States
Git operates across three distinct areas:
1. **Working Directory:** Files currently being edited.
2. **Staging Area (Index):** A snapshot of what will be in the next commit.
3. **Repository (.git):** Permanent storage of snapshots.

**Internal Model: The Object Graph**
*   **Blob:** The content of a file (hashed).
*   **Tree:** A list of blobs and sub-trees (replaces the concept of directories).
*   **Commit:** A pointer to a tree, parent commit(s), author, and message.

### 2.2 Advanced Staging & Committing
**Commands:**
```bash
# Partial staging (Hunk selection)
git add -p <file>
# Use: Committing only specific logical changes if multiple tasks were coded in one file.

# View what is staged (Index vs HEAD)
git diff --cached

# Amend the last commit (Internal: creates a NEW commit, replaces old one)
git commit --amend --no-edit

# Commit with specific date/author (Manual override)
git commit --author="Senior Eng <eng@corp.com>" --date="yesterday" -m "Fixed legacy bug"
```

### 2.3 Stashing Operations
**When:** You need to switch branches but have uncommitted (dirty) work.

**Commands:**
```bash
# Push with message (Best practice)
git stash push -m "Refactoring API layer"

# Stash untracked files
git stash -u

# Apply and keep in stash list
git stash apply stash@{0}

# Pop and remove from list
git stash pop

# Create branch directly from stash
git stash branch <new_branch_name> stash@{0}
```

**Failure Case:** `git stash pop` fails due to conflicts.
*   *Recovery:* Resolve conflicts manually, then run `git stash drop` only after successful resolution.

---

## Phase 3: Branching Strategies & Collaboration

### 3.1 Advanced Branching Mechanics
**Internal Model:** A branch is NOT a copy of the files. It is a lightweight, 41-character file (pointer) in `.git/refs/heads/` that contains the SHA-1 hash of a commit.

**Commands:**
```bash
# Atomic branch creation and switch
git checkout -b <name>
# Modern equivalent (Recommended)
git switch -c <branch_name>

# Visualizing the branch graph
git log --oneline --graph --all

# List merged branches (candidates for cleanup)
git branch --merged

# Rename branch (Local and Remote)
git branch -m <old_name> <new_name>
git push origin -u <new_name>
git push origin --delete <old_name>
```

### 3.2 Merge vs. Rebase
**When to Merge:** Preserving project history and context. Use for merging feature branches into protected branches (Production/Main).
**When to Rebase:** Keeping a linear history. Use for updating your local feature branch with the latest changes from Main.

**Commands:**
```bash
# Standard Merge (creates a merge commit)
git checkout main
git merge <feature_branch>

# Interactive Rebase (Rewrite your local history before PR)
git checkout <feature_branch>
git rebase -i main
# (Internal: rewinds HEAD to common ancestor, applies each of your commits on top of main)

# Abort rebase if it goes wrong
git rebase --abort
```

### 3.3 Remote Operations & Synchronization
**Commands:**
```bash
# Fetch without merging (Internal: updates remote tracking branches in refs/remotes/)
git fetch origin

# Professional Pull (Always rebase to avoid unnecessary merge commits)
git pull --rebase origin main

# Force with lease (THE SAFEST destructive push)
git push --force-with-lease
# Use: Re-writing history on your OWN feature branch. 
# Why: Fails if someone else pushed to the branch, preventing accidental overwrite.
```

### 3.4 Conflict Handling: The Two-Developer Scenario
**Real Scenario:** Dev A and Dev B modify the same line in `config.py`. Dev A pushes first. Dev B pulls.

**Commands:**
```bash
git pull --rebase origin main
# REBASE PAUSE: Git stops at the conflicting commit.
# 1. Open config.py, look for <<<<<< HEAD, resolve manually.
# 2. Stage the fix:
git add config.py
# 3. Continue the rebase:
git rebase --continue
```
*   **Pro Tip:** Enable `git config --global rerere.enabled true` (Reuse Recorded Resolution) to automate repetitive conflict fixes.

---

## Phase 4: History Management & Advanced Tools

### 4.1 Git Reflog (The Black Box Recorder)
**When:** You "lost" a commit, accidentally reset a branch, or performed a failed rebase.

**Internal Model:** Git records every change to the HEAD pointer in the reflog. Even deleted commits are physically present for ~30 days until garbage collection.

**Commands:**
```bash
# View all recent HEAD movements
git reflog

# Restore branch to a specific state (e.g., before an accidental reset)
git reset --hard HEAD@{5}
```

### 4.2 Git Bisect (Automated Regression Debugging)
**Real Scenario:** A bug was introduced somewhere in the last 100 commits.

**Commands:**
```bash
git bisect start
git bisect bad HEAD           # Current state is broken
git bisect good <commit_id>   # This old version was fine

# Git will checkout the middle commit. Test your code.
# If broken: git bisect bad
# If working: git bisect good

# Git continues binary search until it finds the "first bad commit".
git bisect reset              # Return to original state
```

### 4.3 Git Worktree (Multi-tasking without Stashing)
**When:** You are in the middle of a massive refactor and need to fix a critical production bug NOW.

**Commands:**
```bash
# Create a parallel workspace in a different folder
git worktree add ../hotfix-folder main

# Switch to that folder and fix the bug
cd ../hotfix-folder
# (Work on code...)
git commit -m "Critical Fix"

# Return to original work
cd ../original-repo
git worktree remove ../hotfix-folder
```

### 4.4 History Manipulation: Reset, Cherry-pick, and Revert
**Git Reset (Internal: Moving the branch pointer)**
*   **Soft:** `git reset --soft HEAD~1` (Keeps changes in staging. Use: Squashing local commits).
*   **Mixed (Default):** `git reset HEAD~1` (Keeps changes in working dir, unstages them).
*   **Hard:** `git reset --hard HEAD~1` (DESTROYS all changes. Use: Aborting bad experiments).

**Git Cherry-pick (Internal: Applying a single commit's patch to current HEAD)**
```bash
# Apply a specific fix from another branch
git cherry-pick <commit_id>
# If conflict occurs: resolve, git add, git cherry-pick --continue
```

**Git Clean (Housekeeping)**
```bash
# Preview what will be deleted
git clean -nd
# Force delete all untracked files and directories
git clean -fd
```

### 4.5 Inspecting the Past: Blame and Tags
**Git Blame (Accountability)**
```bash
# See who changed which line and why
git blame -L 10,20 path/to/file.py
# -L filters by line range.
```

**Git Tag (Versioning)**
```bash
# Lightweight tag (just a pointer)
git tag v1.0.0
# Annotated tag (Stored as a full object - Recommended for releases)
git tag -a v1.1.0 -m "Production release"
# Push tags to remote
git push origin --tags
```

---

## Phase 5: Debugging, Recovery & Disaster Scenarios

### 5.1 Undoing Pushed Commits Safely
**Scenario:** You pushed a commit that breaks production, but others have already pulled it.

**Commands:**
```bash
# Safely undo changes by creating a NEW inverse commit
git revert <commit_id>
git push origin main
# (Internal: Git calculates the difference and applies the opposite patch)

# If multiple commits need reverting:
git revert <oldest_commit>..<newest_commit>
```

### 5.2 Recovering Secrets (The "Oh No" Scenario)
**Scenario:** You accidentally committed and pushed an `.env` file or API key.

**Commands:**
```bash
# 1. Remove from local history (using git-filter-repo is preferred, via built-in:)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/secret.txt" \
  --prune-empty --tag-name-filter cat -- --all

# 2. Force push the cleaned history
git push origin --force --all

# 3. CRITICAL: Rotate the secret immediately. Git history removal is not 100% foolproof.
```

### 5.3 Fixing a "Detached HEAD"
**Internal Model:** HEAD points to a specific commit SHA instead of a branch name. New commits will be "orphaned" if you switch away.

**Recovery:**
```bash
# Create a temporary branch to save your work
git checkout -b temp-recovery-branch
# Merge it into your main feature branch
git checkout feature-branch
git merge temp-recovery-branch
```

---

## Phase 6: Maintenance, Scaling & GitHub Integration

### 6.1 GitHub Professional Workflow
**Pull Requests (PRs):**
*   **Draft PRs:** Use for early feedback without triggering CI or blocking merges.
*   **Squash & Merge:** Combines all PR commits into one clean commit on Main.
    *   *When:* feature branch has "messy" intermediate commits.

**GitHub Actions (Basic CI Pipeline):**
File: `.github/workflows/ci.yml`
```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Tests
        run: npm test
```

### 6.2 Scaling Large Repositories
**Git LFS (Large File Storage):**
*   **When:** Managing binary assets > 100MB.
*   **Command:** `git lfs track "*.psd"`

**Git Maintenance:**
```bash
# Optimize the object database and packfiles
git maintenance run --auto

# Sparse Checkout (Monorepo strategy)
git sparse-checkout init --cone
git sparse-checkout set folder/subfolder
# (Internal: Only populates the working directory with specified folders)
```

### 6.3 Performance Summary
- **Cleanup:** `git gc --prune=now --aggressive`
- **Audit:** `git count-objects -vH`

---

## Conclusion: The Professional Mindset
A senior engineer treats Git as a **database of snapshots**, not just a backup tool. 
- **Atomic Commits:** One logical change per commit.
- **Clean History:** Rebase local changes; Merge shared changes.
- **Reflog First:** Never panic; the data is usually still there.
