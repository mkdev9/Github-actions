# Git Interactive Training Lab: task_manager_app

Welcome to the hands-on Git lab. Follow these steps exactly in your terminal to experience Git's internal state changes and workflows.

---

## PHASE 1: INIT (Project Genesis)

### Step 1: Initialize the Project
**OBJECTIVE:** Create a clean environment and start Git tracking.

**COMMANDS:**
```bash
mkdir task_manager_app && cd task_manager_app
git init -b main
```

**EXPECTED OUTPUT:**
`Initialized empty Git repository in .../task_manager_app/.git/`

**WHAT JUST HAPPENED:**
Git created the hidden `.git` folder. You are now on the `main` branch, but no commits exist yet.

---

### Step 2: Create Baseline Files & Initial Commit
**OBJECTIVE:** Create the project structure and save the first snapshot.

**COMMANDS:**
```bash
# Create files
echo "def main(): print('Task Manager Active')" > app.py
echo "def validate_task(task): return True" > utils.py
echo "# Task Manager App" > README.md

# Stage and commit
git add .
git commit -m "initial: base project structure"
```

**FILE CHANGES:**
- `app.py`: Created with basic print.
- `utils.py`: Created with dummy validation.

**WHAT JUST HAPPENED:**
- `git add .` moved files to the Staging Area (Index).
- `git commit` created the first commit object. `HEAD` now points to this commit.

---

## PHASE 2: DEVELOPMENT (The Daily Cycle)

### Step 3: Modify and Diff
**OBJECTIVE:** Observe how Git tracks changes before they are saved.

**COMMANDS:**
```bash
# Add a new feature to utils.py
echo "def delete_task(id): print(f'Deleting {id}')" >> utils.py

# Check the difference
git status
git diff
```

**EXPECTED OUTPUT:**
`git diff` will show the new `delete_task` function in green (+).

**WHAT JUST HAPPENED:**
Git compared your Working Directory to the Index and identified that `utils.py` has un-staged modifications.

---

### Step 4: Atomic Commits
**OBJECTIVE:** Practice staging only specific logical changes.

**COMMANDS:**
```bash
git add utils.py
git commit -m "feat: add delete utility"
```

---

## PHASE 3: BRANCHING (Parallel Work)

### Step 5: Feature Branching
**OBJECTIVE:** Work on a "Priority" feature without affecting `main`.

**COMMANDS:**
```bash
git switch -c feat/priority-tasks
```

**WHAT JUST HAPPENED:**
Git created a new pointer `feat/priority-tasks` at the same commit as `main` and moved `HEAD` to point to it.

---

### Step 6: Implement Feature
**COMMANDS:**
```bash
echo "def set_priority(task, level): task['p'] = level" >> app.py
git add app.py
git commit -m "feat: implement task prioritization"
```

---

## PHASE 4: CONFLICT (Intentional Collision)

### Step 7: The "Main" Branch Moves Forward
**OBJECTIVE:** Simulate a colleague pushing a change to the same file you are working on.

**COMMANDS:**
```bash
# Switch back to main
git switch main

# Edit the same file (app.py) in a different way
echo "def main(): print('Nexus Task Manager v1.0')" > app.py
git add app.py
git commit -m "chore: update app title on main"
```

---

### Step 8: Trigger and Resolve Conflict
**OBJECTIVE:** Experience the "Merge Conflict" state and fix it manually.

**COMMANDS:**
```bash
git merge feat/priority-tasks
```

**EXPECTED OUTPUT:**
`CONFLICT (content): Merge conflict in app.py`
`Automatic merge failed; fix conflicts and then commit the result.`

**RECOVERY / FIX:**
1. Open `app.py`. You will see markers:
```python
<<<<<<< HEAD
def main(): print('Nexus Task Manager v1.0')
=======
def main(): print('Task Manager Active')
def set_priority(task, level): task['p'] = level
>>>>>>> feat/priority-tasks
```
2. Manually edit `app.py` to keep both:
```python
def main(): print('Nexus Task Manager v1.0')
def set_priority(task, level): task['p'] = level
```
3. Finalize merge:
```bash
git add app.py
git commit -m "merge: integrate priority features and resolve conflicts"
```

**WHAT JUST HAPPENED:**
Git could not reconcile the `main()` function change. You manually performed the three-way merge, and `git commit` created a Merge Commit with two parents.

---

## PHASE 5: HISTORY MANIPULATION (The Time Machine)

### Step 9: Soft Reset (Undo Commit, Keep Changes)
**OBJECTIVE:** Fix a mistake in the last commit while keeping your work.

**COMMANDS:**
```bash
# Accidentally commit a "debug" note
echo "print('DEBUGGING')" >> app.py
git add app.py
git commit -m "chore: debug print (mistake)"

# Undo the commit but keep the code in Staging
git reset --soft HEAD~1
```

**WHAT JUST HAPPENED:**
Git moved the `main` branch pointer back one commit. Your "DEBUGGING" line is still in the index, ready to be fixed or removed.

---

### Step 10: Mixed Reset (Unstage Changes)
**COMMANDS:**
```bash
# Move the "DEBUGGING" change out of Staging back to Working Dir
git reset HEAD app.py
```

---

### Step 11: Hard Reset (The Nuclear Option)
**OBJECTIVE:** Completely discard a failed experiment.

**COMMANDS:**
```bash
# Discard the debug change entirely
git reset --hard HEAD
```

**EXPECTED OUTPUT:**
`HEAD is now at ... merge: integrate priority features and resolve conflicts`

**WHAT JUST HAPPENED:**
Git updated the Working Directory and Index to match the last good commit. The "DEBUGGING" line is gone.

---

### Step 12: Reflog Recovery (Undo the Undo)
**OBJECTIVE:** Recover a commit you deleted via `reset --hard`.

**COMMANDS:**
```bash
# View the list of all HEAD movements
git reflog
```

**RECOVERY / FIX:**
1. Find the SHA of the "debug print (mistake)" commit in the log.
2. Restore it:
```bash
git reset --hard <SHA_FROM_REFLOG>
```

**WHAT JUST HAPPENED:**
The Reflog is an internal log of `HEAD` movements. It allows you to "time travel" even to commits that are no longer part of any branch.
*Now, hard reset back to the clean state before continuing:*
`git reset --hard HEAD@{1}` (or whatever the clean merge commit SHA is).

---

### Step 13: Revert (Public Undo)
**OBJECTIVE:** Undo a commit in a way that is safe for sharing with others.

**COMMANDS:**
```bash
# Create a change to revert
echo "def old_api(): pass" >> app.py
git add app.py
git commit -m "feat: add legacy api support"

# Revert it
git revert HEAD --no-edit
```

**WHAT JUST HAPPENED:**
Git created a **new commit** that does the exact opposite of the legacy API commit. The history stays linear and safe.

---

## PHASE 6: STASH (Context Switching)

### Step 14: Stash Dirty Changes
**OBJECTIVE:** Switch tasks without committing half-finished work.

**COMMANDS:**
```bash
# Start a new task
echo "def new_feature():" >> app.py

# Emergency: must fix a bug on 'main', but don't want to commit yet
git stash push -m "WIP: new feature logic"

# Check state
git status
```

**EXPECTED OUTPUT:**
`nothing to commit, working tree clean`

---

### Step 15: Restore Stash
**COMMANDS:**
```bash
# (Imagine you did some other work...)
git stash list
git stash pop
```

**WHAT JUST HAPPENED:**
`git stash push` moved your uncommitted changes into a special internal stack. `git stash pop` applied them back and removed them from the stack.

---

## PHASE 7: REBASE VS MERGE (History Aesthetics)

### Step 16: Prepare Divergent History
**OBJECTIVE:** Create a scenario where `main` and a feature branch have diverged.

**COMMANDS:**
```bash
# Branch off
git switch -c feat/optimizations

# Change on feature
echo "import time" >> app.py
git add app.py
git commit -m "feat: add timing utilities"

# Change on main
git switch main
echo "VERSION = '1.1.0'" >> config.json
git add config.json
git commit -m "chore: bump version"
```

---

### Step 17: Rebase for a Clean Graph
**OBJECTIVE:** Make the feature branch look like it started from the latest `main`.

**COMMANDS:**
```bash
git switch feat/optimizations
git rebase main
```

**WHAT JUST HAPPENED:**
Git found the common ancestor, temporary took off your "timing utilities" commit, updated the branch to the latest `main`, and then reapplied your commit on top. No merge commit was created.

---

## PHASE 8: DEBUGGING (The Detective Work)

### Step 18: Introduce a "Stealth" Bug
**OBJECTIVE:** Simulate a bug that was introduced several commits ago.

**COMMANDS:**
```bash
# Create a series of commits
echo "# Log content" > logs.txt
git add logs.txt
git commit -m "docs: add log file"

# INTRODUCE BUG: change the function logic to break
sed -i "s/True/False/g" utils.py
git add utils.py
git commit -m "refactor: clean up utils"

echo "print('App running...')" >> app.py
git add app.py
git commit -m "feat: app heartbeat"
```

---

### Step 19: Use Git Bisect to find the Bug
**OBJECTIVE:** Perform a binary search through history to identify the "bad" commit.

**COMMANDS:**
```bash
git bisect start
git bisect bad HEAD
git bisect good <INITIAL_COMMIT_SHA>  # Use your first SHA from log or reflog
```

**WORKFLOW:**
1. Git will checkout a middle commit.
2. Review `utils.py`. If it has `True`, it's good. If `False`, it's bad.
3. Tell Git: `git bisect good` or `git bisect bad`.
4. Result: `[SHA] refactor: clean up utils is the first bad commit`.
5. Finish: `git bisect reset`.

---

## PHASE 9: REMOTE SIMULATION (The Cloud Bridge)

### Step 20: Simulate a Local "Remote"
**OBJECTIVE:** Practice `push` and `pull` using a local folder as a "server".

**COMMANDS:**
```bash
# Create a bare repository to act as the "Remote"
cd ..
git init --bare server.git
cd task_manager_app

# Connect your project to the simulated server
git remote add origin ../server.git
git push -u origin main
```

---

### Step 21: Fetch and Pull
**OBJECTIVE:** Update your local repo from the "Remote".

**COMMANDS:**
```bash
git fetch origin
git pull origin main
```

**WHAT JUST HAPPENED:**
`git push` uploaded your commits to the `server.git` folder. `git remote` tracked that folder as `origin`. You have successfully simulated a full GitHub collaboration cycle offline.

---

## CONGRATULATIONS!
You have completed the Hands-On Git Lab.
- You created, modified, and saved work.
- You survived a merge conflict.
- You recovered "deleted" work using the Reflog.
- You used a binary search to find a bug.
- You simulated cloud collaboration.

**Final cleanup (Optional):**
`cd .. && rm -rf task_manager_app server.git`
