# Advanced Git Internals & Operational Tutorial
**Project Context:** Development of a "NexusPay SDK" (A high-concurrency Node.js Payment Gateway).

---

## 1. BASIC COMMANDS

### Command: git init

**1. PURPOSE**
Transforms a standard directory into a Git repository. It is the genesis of version control for any new project (e.g., starting the NexusPay SDK from scratch).

**2. INTERNAL MODEL**
Creates a hidden `.git` directory. 
- Initializes the `objects` database (empty).
- Creates `refs/heads` (pointers to branches).
- Sets the `HEAD` pointer to `refs/heads/main` (or master).

**3. SYNTAX**
`git init [-b <branch-name>] [--bare] [<directory>]`

**4. COMMON USAGE PATTERNS**
- `git init`: Initialize current directory.
- `git init -b main`: Initialize with 'main' as the default branch.
- `git init --bare`: Create a repository without a working directory (for servers).

**5. STEP-BY-STEP EXAMPLE**
```bash
mkdir nexus-pay-sdk && cd nexus-pay-sdk
git init -b main
```
*Before:* Empty directory.
*After:* Directory containing `.git/` metadata.

**6. OUTPUT EXPLANATION**
`Initialized empty Git repository in /path/to/nexus-pay-sdk/.git/`
Meaning: Git has successfully created the tracking infrastructure.

**7. FAILURE CASES**
- Running inside an existing repository (results in a nested repository, usually avoided).
- Permission denied (lack of write access to the directory).

**8. RECOVERY / FIX**
If run accidentally: `rm -rf .git`.

**9. BEST PRACTICES**
Always specify `-b main` to follow modern standards. Use `--bare` only for central team servers.

---

### Command: git add

**1. PURPOSE**
Moves changes from the Working Directory to the Staging Area (Index). It prepares the "next snapshot."

**2. INTERNAL MODEL**
- Calculates the SHA-1 hash of the file content.
- Creates a **Blob object** in `.git/objects`.
- Updates the **Index file** to map the filename to the new Blob hash.

**3. SYNTAX**
`git add <pathspec>... [-p] [-u] [-A]`

**4. COMMON USAGE PATTERNS**
- `git add .`: Stage all changes.
- `git add src/gateway.ts`: Stage a specific file.
- `git add -p`: Interactive "patch" mode (partial staging).

**5. STEP-BY-STEP EXAMPLE**
```bash
# Create the first file
echo "export class Gateway {}" > src/index.ts
git add src/index.ts
```
*Working Directory:* Has new `index.ts`.
*Staging Area:* Now has a reference to the blob representing "export class Gateway {}".

**6. OUTPUT EXPLANATION**
Usually silent. Use `git status` to verify.

**7. FAILURE CASES**
- Adding a file listed in `.gitignore` (requires `-f` to override).
- Technical: "LF will be replaced by CRLF" (automatic line-ending conversion).

**8. RECOVERY / FIX**
To unstage a file: `git restore --staged <file>`.

**9. BEST PRACTICES**
Avoid `git add .`. Prefer `git add -p` to review every line before staging, ensuring no debug logs or secrets are included.

---

### Command: git commit

**1. PURPOSE**
Saves the current state of the Staging Area as a permanent snapshot in the repository history.

**2. INTERNAL MODEL**
- Creates a **Tree object** representing the project structure.
- Creates a **Commit object** containing:
  - Pointer to the Tree.
  - Parent commit SHA.
  - Author/Committer, Timestamp, and Message.
- Moves the current Branch Pointer (and `HEAD`) to this new Commit SHA.

**3. SYNTAX**
`git commit [-m <msg>] [--amend] [-a]`

**4. COMMON USAGE PATTERNS**
- `git commit -m "feat: implement stripe provider"`: Standard commit.
- `git commit --amend --no-edit`: Fix a typo in the last commit without changing the message.
- `git commit -v`: Shows the diff in the editor while writing the message.

**5. STEP-BY-STEP EXAMPLE**
```bash
git commit -m "initial: nexus-pay-sdk core structure"
```
*Before:* HEAD -> main (no commits).
*After:* HEAD -> main -> [SHA1: 4f2a1...]

**6. OUTPUT EXPLANATION**
`[main (root-commit) 4f2a170] initial: nexus-pay-sdk core structure`
Meaning: On branch 'main', created commit '4f2a170'.

**7. FAILURE CASES**
- "nothing to commit, working tree clean": You forgot to `git add`.
- "empty commit message": Aborts the commit.

**8. RECOVERY / FIX**
If you committed to the wrong branch: `git reset --soft HEAD~1` (moves HEAD back but keeps changes).

**9. BEST PRACTICES**
Follow Conventional Commits (feat:, fix:, docs:). Keep commits atomic (one logical change per commit).

---

### Command: git status

**1. PURPOSE**
Provides a snapshot of the difference between the Working Directory, Staging Area, and HEAD.

**2. INTERNAL MODEL**
Performs a three-way comparison:
- HEAD vs Index (Staged changes).
- Index vs Working Directory (Unstaged changes).
- Discovery of "untracked" files (not in Index or HEAD).

**3. SYNTAX**
`git status [-s] [-b]`

**4. COMMON USAGE PATTERNS**
- `git status`: Standard verbose output.
- `git status -s`: "Short" format (ideal for scripts or fast scanning).
- `git status -u`: Shows individual files in untracked directories.

**5. STEP-BY-STEP EXAMPLE**
```bash
# Modify file and create new one
echo "// TODO" >> src/index.ts
touch src/utils.ts
git status
```
*Output:* `index.ts` shows as "modified" (unstaged), `utils.ts` shows as "untracked".

**6. OUTPUT EXPLANATION**
- `Changes to be committed`: Staged.
- `Changes not staged for commit`: Modified but not staged.
- `Untracked files`: New and ignored by Git.

**7. FAILURE CASES**
- Slow performance on massive repos (Solution: use `git status -uno`).

**8. RECOVERY / FIX**
N/A (Read-only command).

**9. BEST PRACTICES**
Run `git status` before every `add` and `commit`. Use `-s` for a "dashboard" view.

---

### Command: git log

**1. PURPOSE**
Displays the history of commits, allowing you to trace the evolution of the system.

**2. INTERNAL MODEL**
Traverses the commit graph backwards starting from `HEAD` (or a specific branch/commit).

**3. SYNTAX**
`git log [<options>] [<revision-range>] [--] [<path>...]`

**4. COMMON USAGE PATTERNS**
- `git log --oneline --graph --all`: The "Master View" of the entire repository structure.
- `git log -p src/index.ts`: See actual code changes for a specific file.
- `git log --author="Jane"`: Filter by contributor.

**5. STEP-BY-STEP EXAMPLE**
```bash
git log --oneline
```
*Output:*
`4f2a170 initial: nexus-pay-sdk core structure`

**6. OUTPUT EXPLANATION**
Each line is a commit SHA + the first line of the message.

**7. FAILURE CASES**
- Output is too long (automatically piped to `less`, press `q` to exit).

**8. RECOVERY / FIX**
N/A (Read-only).

**9. BEST PRACTICES**
Set an alias: `git config --global alias.lg "log --graph --oneline --all"`.

---

### Command: git diff

**1. PURPOSE**
Shows line-by-line differences between different states of the project.

**2. INTERNAL MODEL**
Compares content hashes of files between:
- Working Dir vs Index (Default).
- Index vs HEAD (`--cached`).
- Commit A vs Commit B.

**3. SYNTAX**
`git diff [<options>] [<commit>] [--] [<path>...]`

**4. COMMON USAGE PATTERNS**
- `git diff`: What have I changed but not yet staged?
- `git diff --cached`: What am I about to commit?
- `git diff main..feature-auth`: Compare two branches.

**5. STEP-BY-STEP EXAMPLE**
```bash
git diff
```
*Output:*
`- export class Gateway {}`
`+ export class PaymentGateway {}`

**6. OUTPUT EXPLANATION**
`--- a/src/index.ts` (old version)
`+++ b/src/index.ts` (new version)
`-` red: removed.
`+` green: added.

**7. FAILURE CASES**
- Large binary files (diff will say "Binary files differ").

**8. RECOVERY / FIX**
N/A.

**9. BEST PRACTICES**
Always `git diff --cached` before committing to ensure you aren't committing "shadow" changes or console logs.

---

## 2. BRANCHING COMMANDS

### Command: git branch

**1. PURPOSE**
Creates, lists, or deletes "lanes" of development. In NexusPay SDK, this allows a developer to build a "Stripe Integration" without breaking the main "Checkout" flow.

**2. INTERNAL MODEL**
A branch is a **file** in `.git/refs/heads/` that stores a 40-character commit SHA.
- **Creation:** Git creates a new pointer to the current commit.
- **Listing:** Reads all files in `refs/heads/`.
- **Deletion:** Deletes the specific file (if merged).

**3. SYNTAX**
`git branch [-a] [-d] [-m <new_name>] [--merged]`

**4. COMMON USAGE PATTERNS**
- `git branch`: List local branches.
- `git branch -a`: List all local and remote branches.
- `git branch -d feat/old-api`: Safe delete (fails if not merged).
- `git branch -m feat/fix-paypal`: Rename branch.

**5. STEP-BY-STEP EXAMPLE**
```bash
git branch feat/stripe-api
```
*Graph:*
```text
(Commit A) <- [main][HEAD]
           <- [feat/stripe-api]
```
Both branches point to Commit A.

**6. OUTPUT EXPLANATION**
The asterisk `*` in the branch list indicates which branch the `HEAD` is currently pointing to.

**7. FAILURE CASES**
- "error: branch 'X' not fully merged": You will lose work if you delete it.
- "fatal: A branch named 'X' already exists."

**8. RECOVERY / FIX**
To force delete an unmerged branch: `git branch -D <name>`.

**9. BEST PRACTICES**
Use descriptive prefixes: `feat/`, `fix/`, `hotfix/`. Cleanup local branches monthly.

---

### Command: git checkout / git switch

**1. PURPOSE**
Navigates the project state between branches or specific commits. `switch` is the modern alternative for branch navigation.

**2. INTERNAL MODEL**
- Updates the `HEAD` file to point to the new branch reference.
- Updates the **Index** and **Working Directory** to match the snapshot of the target commit.

**3. SYNTAX**
- `git checkout <branch>` / `git switch <branch>`
- `git checkout -b <new_branch>` / `git switch -c <new_branch>`

**4. COMMON USAGE PATTERNS**
- `git switch main`: Return to main.
- `git switch -c fix/logic-bug`: Create and jump to a fix branch.
- `git checkout README.md`: Discard local changes to a specific file (Checkout only).

**5. STEP-BY-STEP EXAMPLE**
```bash
git switch -c dev/auth-v2
```
*Before:* HEAD -> main.
*After:* HEAD -> dev/auth-v2.

**6. OUTPUT EXPLANATION**
`Switched to a new branch 'dev/auth-v2'`
Meaning: HEAD is now tracking the new branch file.

**7. FAILURE CASES**
- "error: Your local changes to the following files would be overwritten": Must commit or stash first.

**8. RECOVERY / FIX**
If you switch branches and realize your changes vanished: `git switch -` to return.

**9. BEST PRACTICES**
Prefer `git switch` for branches and `git restore` for files. It avoids the "overloaded" ambiguity of `checkout`.

---

### Comparison: checkout vs switch
| Feature | `git checkout` | `git switch` |
| --- | --- | --- |
| Create Branch | `checkout -b <name>` | `switch -c <name>` |
| Branch Navigation | Yes | Yes |
| File Restoration | Yes | No (`git restore` instead) |
| Safety | Overloaded, risky | Specialized, safer |

---

### Command: git merge

**1. PURPOSE**
Combines two independent development histories. e.g., Merging the verified "Stripe Integration" back into the "Main SDK".

**2. INTERNAL MODEL**
- If target is ahead: **Fast-forward** (just move the pointer).
- If diverge: **Three-way merge**. Git identifies a Common Ancestor (CA), and reconciles changes from both paths into a NEW **Merge Commit**.

**3. SYNTAX**
`git merge [--no-ff] [--squash] <branch>`

**4. COMMON USAGE PATTERNS**
- `git merge feat/stripe-api`: Standard merge into current branch.
- `git merge --no-ff dev`: Forces a merge commit even if fast-forward is possible.
- `git merge --abort`: Cancel everything if conflicts are overwhelming.

**5. STEP-BY-STEP EXAMPLE**
```bash
git switch main
git merge feat/stripe-api
```
*Graph (Three-way):*
```text
      (C1)---(C2) [feat] 
     /         \
(CA)---(A1)---(Merge Commit) [main][HEAD]
```

**6. OUTPUT EXPLANATION**
`Merge made by the 'recursive' strategy.`
Meaning: Complex merge succeeded via automated reconciliation.

**7. FAILURE CASES**
- **Merge Conflicts:** Git cannot resolve overlapping changes.

**8. RECOVERY / FIX**
In conflict: Edit files, `git add`, then `git merge --continue` or `git commit`.

**9. BEST PRACTICES**
Always `git pull` before merging to minimize divergence. Use `--no-ff` for significant features to preserve history context.

---

### Command: git rebase

**1. PURPOSE**
Re-writes the commit history. It places your current branch's commits as if they were built directly on top of the latest target branch commit.

**2. INTERNAL MODEL**
- Finds Common Ancestor.
- Temporary "parks" your work.
- Resets current branch to the target branch.
- Re-applies (re-plays) each of your commits one-by-one. Each commit gets a **NEW SHA-1**.

**3. SYNTAX**
`git rebase <upstream>`
`git rebase -i <upstream>` (Interactive)

**4. COMMON USAGE PATTERNS**
- `git rebase main`: Clean up history before a PR.
- `git rebase -i HEAD~3`: Squash 3 local commits into one "atomic" feature commit.

**5. STEP-BY-STEP EXAMPLE**
```bash
git switch feat/stripe
git rebase main
```
*Visual Transformation:*
```text
(Before)
main: (C1)---(C2)
feat:    \---(F1)

(After Rebase)
main: (C1)---(C2)
feat:           \---(F1') [Note: SHA has changed]
```

**6. OUTPUT EXPLANATION**
`Successfully rebased and updated refs/heads/feat/stripe.`
Meaning: Commits were detached and re-attached to the new base.

**7. FAILURE CASES**
- Rebasing commits that are already shared (pushed) with a team.

**8. RECOVERY / FIX**
To undo a bad rebase: `git reflog` -> `git reset --hard HEAD@{n}`.

**9. BEST PRACTICES**
**Golden Rule:** Never rebase public history. Use interactive rebase to "tidy up" local work before sharing.

---

### Comparison: merge vs rebase
| Scenario | Merge | Rebase |
| --- | --- | --- |
| History | Non-linear, true to timeline | Linear, clean |
| Traceability | Preserves merge commits | Simplifies graph |
| Conflicts | Resolved once at end | Resolved per commit |
| Complexity | Low | High (rewrites hash) |
| Usage | Teams / Protected branches | Individual / Local branches |

---

## 3. REMOTE COMMANDS

### Command: git remote

**1. PURPOSE**
Manages the connections to external repositories (e.g., GitHub). For NexusPay SDK, this defines where the central source of truth lives.

**2. INTERNAL MODEL**
Entries in `.git/config` under `[remote "name"]`.
- Maps a "nickname" (like `origin`) to a URL.
- Defines **Refspecs** (rules for how local branches map to remote ones).

**3. SYNTAX**
`git remote [-v] [add <name> <url>] [remove <name>] [rename <old> <new>]`

**4. COMMON USAGE PATTERNS**
- `git remote -v`: List names and URLs.
- `git remote add origin https://github.com/nexus/sdk.git`: Setup initial link.
- `git remote set-url origin <new_url>`: Change migration destination.

**5. STEP-BY-STEP EXAMPLE**
```bash
git remote add origin git@github.com:nexus/nexus-pay-sdk.git
git remote -v
```
*Output:*
`origin  git@github.com:nexus/nexus-pay-sdk.git (fetch)`
`origin  git@github.com:nexus/nexus-pay-sdk.git (push)`

**6. OUTPUT EXPLANATION**
Shows that `origin` is the handle for both downloading (fetch) and uploading (push).

**7. FAILURE CASES**
- "fatal: remote origin already exists": You tried to add a name that's taken.

**8. RECOVERY / FIX**
`git remote remove origin` and then re-add.

**9. BEST PRACTICES**
Always use SSH for `origin` to avoid constant password prompts. Use `upstream` as the naming convention for original forks.

---

### Command: git fetch

**1. PURPOSE**
Downloads objects and refs from another repository. It updates your local "view" of the remote without touching your working files.

**2. INTERNAL MODEL**
- Contacts the remote server.
- Downloads any missing **Objects** (commits, trees, blobs).
- Updates **Remote-Tracking Branches** in `.git/refs/remotes/origin/`.

**3. SYNTAX**
`git fetch [<remote>] [<branch>] [--all] [--prune]`

**4. COMMON USAGE PATTERNS**
- `git fetch origin`: Update all remote branches for origin.
- `git fetch --all`: Update from every configured remote.
- `git fetch --prune`: Delete local references to remote branches that no longer exist on the server.

**5. STEP-BY-STEP EXAMPLE**
```bash
git fetch origin
```
*Mental Diagram:*
Remote: `main` [C3]
Local: `main` [C2], `origin/main` [C2]
*After Fetch:*
Local: `main` [C2], `origin/main` [C3] **(Working Directory still at C2)**.

**6. OUTPUT EXPLANATION**
`[new branch]      main       -> origin/main`
Meaning: Local tracking branch was moved forward to match the server.

**7. FAILURE CASES**
- Public key denied (SSH error).
- Network timeouts.

**8. RECOVERY / FIX**
Check SSH connection: `ssh -T git@github.com`.

**9. BEST PRACTICES**
Run `git fetch` frequently. It is 100% safe as it never changes your code.

---

### Command: git pull

**1. PURPOSE**
The combination of `fetch` + `merge` (or rebase). It brings your local branch up-to-date with its remote counterpart.

**2. INTERNAL MODEL**
1. Runs `git fetch`.
2. Runs `git merge` (or `git rebase` if configured) to integrate `origin/branch` into your current branch.

**3. SYNTAX**
`git pull [<remote>] [<branch>] [--rebase]`

**4. COMMON USAGE PATTERNS**
- `git pull origin main`: Standard update.
- `git pull --rebase origin main`: Updates and keeps local history linear (Highly Recommended).

**5. STEP-BY-STEP EXAMPLE**
```bash
git pull --rebase origin main
```
*Before:* Local: [C2], Remote: [C3].
*After Fetch:* Local: [C2], `origin/main`: [C3].
*After Rebase:* Local: [C3] (HEAD moved).

**6. OUTPUT EXPLANATION**
`1 file changed, 10 insertions(+)` + `Fast-forward`
Meaning: Changes were successfully integrated without a merge commit.

**7. FAILURE CASES**
- **Conflicts during integration:** Git can't decide between your changes and the remote's.

**8. RECOVERY / FIX**
If conflicts occur: Resolve files, `git add`, then `git rebase --continue`.

**9. BEST PRACTICES**
Use `git config --global pull.rebase true` to make rebase the default behavior for all pulls.

---

### Comparison: fetch vs pull
| Command | Action | Risk | Impact |
| --- | --- | --- | --- |
| `git fetch` | Download only | Zero | Updates `refs/remotes/` |
| `git pull` | Download + Integrate | Medium (Conflicts) | Updates `Working Directory` |

---

### Command: git push

**1. PURPOSE**
Uploads local repository content to a remote repository. it "publishes" your commits.

**2. INTERNAL MODEL**
- Determines which local commits are missing on the remote.
- Sends a **Packfile** (compressed objects).
- Remote server updates its branch pointers.

**3. SYNTAX**
`git push [<remote>] [<branch>] [--force-with-lease] [-u]`

**4. COMMON USAGE PATTERNS**
- `git push -u origin main`: Push and link local `main` to remote `main`.
- `git push --force-with-lease`: Force overwrite remote (Safe variant).
- `git push origin --delete feat/temp`: Delete a branch from the server.

**5. STEP-BY-STEP EXAMPLE**
```bash
git push -u origin feat/stripe-api
```
*Result:* Others can now see and pull `feat/stripe-api`.

**6. OUTPUT EXPLANATION**
`* [new branch]      feat/stripe-api -> feat/stripe-api`
Meaning: Remote branch created and local branch "tracked" to it.

**7. FAILURE CASES**
- "rejected - non-fast-forward": Someone else pushed changes you don't have.

**8. RECOVERY / FIX**
Run `git pull --rebase`, resolve conflicts, then push again. **NEVER** use `--force` on shared branches.

**9. BEST PRACTICES**
Always use `-u` (upstream) on the first push. Always use `--force-with-lease` instead of plain `--force`.

---

## 4. ADVANCED COMMANDS

### Command: git stash

**1. PURPOSE**
Temporarily shelves (hides) dirty working directory changes so you can work on something else.

**2. INTERNAL MODEL**
- Creates two special commits: one for the Index, one for the Working Directory.
- Stores them in `.git/refs/stash`.
- Runs `git reset --hard` to clean your workspace.

**3. SYNTAX**
`git stash [push [-m <message>]] [pop] [apply] [drop] [list] [show]`

**4. COMMON USAGE PATTERNS**
- `git stash push -m "fix: logic error"`: Save work.
- `git stash list`: See what's hidden.
- `git stash pop`: Restore most recent work and remove it from stash.

**5. STEP-BY-STEP EXAMPLE**
```bash
# Dirty state
git stash push -m "WIP on Gateway"
git switch hotfix/v1.1
# (Fix bug...)
git switch -
git stash pop
```

**6. OUTPUT EXPLANATION**
`Saved working directory and index state WIP on main: 4f2a170...`
Meaning: Changes are tucked away in the stack.

**7. FAILURE CASES**
- Popping into a workspace with conflicting changes.

**8. RECOVERY / FIX**
If pop fails, conflicts are marked. Resolve them, then manually `git stash drop` only if satisfied.

**9. BEST PRACTICES**
Always use names (`-m`). Don't let stashes accumulate—treat them as 1-hour storage.

---

### Command: git cherry-pick

**1. PURPOSE**
Applies the change introduced by an existing commit(s) from another branch onto your current HEAD.

**2. INTERNAL MODEL**
- Calculates the diff of the target commit.
- Applies that patch to the current working tree.
- Creates a **NEW** commit with the same message and content (but new SHA).

**3. SYNTAX**
`git cherry-pick <commit-ish>...`

**4. COMMON USAGE PATTERNS**
- `git cherry-pick a1b2c3d`: Take one specific bugfix.
- `git cherry-pick v1.0..v1.1`: Take a range of commits.

**5. STEP-BY-STEP EXAMPLE**
```bash
git switch release-1.0
git cherry-pick 4f2a170  # Copy critical fix from main
```

**6. OUTPUT EXPLANATION**
`[release-1.0 7b8c9d0] fix: security patch`
Meaning: Commit 4f2a... was successfully duplicated as 7b8c... on the current branch.

**7. FAILURE CASES**
- Conflicts if the target code doesn't fit the current context.

**8. RECOVERY / FIX**
`git cherry-pick --abort`.

**9. BEST PRACTICES**
Use sparingly. If you're cherry-picking 10+ commits, consider a merge or rebase instead.

---

### Command: git reset

**1. PURPOSE**
Resets the current HEAD to a specified state. It acts as a "Time Machine" for your local branch, allowing you to unstage changes or destroy failed work.

**2. INTERNAL MODEL**
Git Reset works in three modes, affecting three areas:
- **Soft:** Moves `HEAD` pointer. (Index and Working Dir untouched).
- **Mixed (Default):** Moves `HEAD` + Updates **Index**. (Working Dir untouched).
- **Hard:** Moves `HEAD` + Updates **Index** + Updates **Working Dir**. (Destructive).

**3. SYNTAX**
`git reset [--soft | --mixed | --hard] <commit>`

**4. COMMON USAGE PATTERNS**
- `git reset --soft HEAD~1`: Undo last commit, keep changes staged.
- `git reset HEAD <file>`: Unstage a specific file.
- `git reset --hard origin/main`: Make local main exactly match the server (discarding all local work).

**5. STEP-BY-STEP EXAMPLE**
```bash
git commit -m "Commit A"
git reset --soft HEAD~1
```
*Before:* HEAD -> Commit A.
*After:* HEAD -> Parent of A. Changes from A are in Staging.

**6. OUTPUT EXPLANATION**
Usually silent. Use `git status` to see where your changes are.

**7. FAILURE CASES**
- Using `--hard` and losing unsaved work (there is no "Undo" for `--hard` except via Reflog).

**8. RECOVERY / FIX**
If you hard reset accidentally: `git reflog` -> `git reset --hard HEAD@{1}`.

**9. BEST PRACTICES**
Use `--soft` for squashing. Use `--hard` only when you are 100% sure you want to delete work.

---

### Command: git revert

**1. PURPOSE**
Undoes a specific commit by creating a **NEW** inverse commit. This is the safe way to undo shared/pushed history.

**2. INTERNAL MODEL**
- Calculates the patch that would reverse the target commit.
- Applies that patch to the current HEAD.
- Creates a new commit object.

**3. SYNTAX**
`git revert <commit> [-n]`

**4. COMMON USAGE PATTERNS**
- `git revert 4f2a170`: Revert a specific buggy commit.
- `git revert HEAD`: Revert the most recent commit.

**5. STEP-BY-STEP EXAMPLE**
```bash
git revert a1b2c3d
```
*History:* [C1] -> [C2 (Bug)] -> [C3 (Inverse of C2)]

**6. OUTPUT EXPLANATION**
`[main 9e8f7a1] Revert "buggy feature"`
Meaning: A new commit was added to neutralize the previous one.

**7. FAILURE CASES**
- Conflicts if the code has moved too far from the original commit state.

**8. RECOVERY / FIX**
`git revert --abort`.

**9. BEST PRACTICES**
Always prefer `revert` over `reset` for any commit that has been pushed to a remote server.

---

### Comparison: reset vs revert
| Feature | `git reset` | `git revert` |
| --- | --- | --- |
| History | Rewrites/Removes commits | Adds new Inverse commit |
| Shared Branches| DANGEROUS (breaks others) | SAFE (additive only) |
| Use Case | Fixing local mistakes | Undoing pushed errors |
| Metadata | Destroyed (unless reflog) | Preserved |

---

### Command: git reflog

**1. PURPOSE**
The "Ultimate Safety Net." It records every single movement of the `HEAD` pointer, including things not visible in `git log`.

**2. INTERNAL MODEL**
A local-only log in `.git/logs/HEAD`. It records SHA-1 transitions for every checkout, reset, commit, and rebase.

**3. SYNTAX**
`git reflog [show] [expire] [delete]`

**4. COMMON USAGE PATTERNS**
- `git reflog`: See recent history.
- `git reset --hard HEAD@{5}`: Jump back to 5 movements ago.

**5. STEP-BY-STEP EXAMPLE**
```bash
# Accidentally deleted a branch
git reflog
# Find the SHA where the branch was: abc1234
git checkout -b recovered-branch abc1234
```

**6. OUTPUT EXPLANATION**
`HEAD@{0}: reset: moving to origin/main`
Meaning: The most recent action was a reset.

**7. FAILURE CASES**
- Items are pruned after 30-90 days (garbage collection).

**8. RECOVERY / FIX**
N/A.

**9. BEST PRACTICES**
Never panic if you "lose" work. Check `reflog` first.

---

### Command: git bisect

**1. PURPOSE**
Uses binary search to find the exact commit that introduced a bug or regression.

**2. INTERNAL MODEL**
Automates a binary search between a "good" (working) commit and a "bad" (broken) commit. It checks out the middle commit and asks for feedback.

**3. SYNTAX**
`git bisect [start | bad | good | reset]`

**4. COMMON USAGE PATTERNS**
- `git bisect start`: Begin process.
- `git bisect bad HEAD`: Current is broken.
- `git bisect good v1.0`: Release 1.0 was working.

**5. STEP-BY-STEP EXAMPLE**
```bash
git bisect start
git bisect bad HEAD
git bisect good 4f2a170
# Git: "Checking out abc1234..."
# (Test the payment flow...)
git bisect bad # Still broken
# Git: "Checking out def4567..."
# (Test...)
git bisect good # Works!
# Git result: "def4567 is the first bad commit"
git bisect reset
```

**6. OUTPUT EXPLANATION**
`Bisecting: 5 revisions left to test after this (roughly 3 steps)`
Meaning: Git predicts how many tests you have left.

**7. FAILURE CASES**
- "Flaky" tests giving false good/bad reports (invalidates the search).

**8. RECOVERY / FIX**
`git bisect reset`.

**9. BEST PRACTICES**
Automate it: `git bisect run ./test.sh`.

---

### Command: git worktree

**1. PURPOSE**
Allows you to have multiple working directories linked to a single repository. You can work on two different branches simultaneously in different folders.

**2. INTERNAL MODEL**
Creates a secondary `index` and `HEAD` in a separate directory but shares the `.git/objects` database.

**3. SYNTAX**
`git worktree add <path> [<branch>]`

**4. COMMON USAGE PATTERNS**
- `git worktree add ../hotfix main`: Switch to fix a prod bug without stashing local work.
- `git worktree list`: See active workspaces.

**5. STEP-BY-STEP EXAMPLE**
```bash
git worktree add ../emergency-fix main
cd ../emergency-fix
# (Fix bug, commit, push)
cd -
git worktree remove ../emergency-fix
```

**6. OUTPUT EXPLANATION**
`Preparing worktree (checking out 'main')`
Meaning: A new folder with its own working files is ready.

**7. FAILURE CASES**
- Trying to checkout the SAME branch in two active worktrees (Forbidden to prevent state corruption).

**8. RECOVERY / FIX**
If a folder is deleted manually: `git worktree prune`.

**9. BEST PRACTICES**
Use for large monorepos where `checkout` is slow, or when you need to run tests on `main` while coding on `feature`.

---

### Final Maintenance/Scaling Commands (Quick Reference)

### git clean
- **Internal Model:** Scans working tree for files not present in the Index.
- **Syntax:** `git clean -fd` (f: force, d: directories).
- **Recovery:** None (Deletes files permanently). Use `-n` for dry-run first.

### git blame
- **Internal Model:** For every line in a file, traverses history to find the last commit that modified it.
- **Syntax:** `git blame -L 10,20 <file>`.

### git tag
- **Internal Model:** A static reference (unlike a branch which moves).
- **Syntax:** `git tag -a v1.0.0 -m "Launch"`.

---

## CONCLUSION
Operating like a professional engineer means respecting the **Object Graph**. 
1. **Always rebase local changes** to keep a linear history.
2. **Never force push shared history** unless coordinated.
3. **Use the Reflog** as your ultimate safety net.
4. **Think in Blobs, Trees, and Commits**, not just "files".
