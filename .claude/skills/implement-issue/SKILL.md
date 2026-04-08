---
name: implement-issue
description: Implement or fix a GitHub Issue in a Rails project end-to-end. Use this skill whenever the user wants to work on a GitHub issue, fix a bug tracked in GitHub, implement a feature from a GitHub issue, or says anything like "work on issue #123", "implement issue", "fix the GitHub issue", "pick up issue", or "let's work on that ticket". Handles the full workflow: fetching the issue, planning with clarifications, creating a git worktree, implementing with tests and linting, and opening a pull request.
---

# GitHub Issue Implementation for Ruby on Rails Skill

This skill guides you through implementing or fixing a GitHub Issue in a Rails project, end-to-end.

## Workflow Overview

1. **Get Issue** → fetch and read the GitHub issue
2. **Plan** → analyze, ask clarifying questions, build an implementation plan
3. **Confirm** → get user approval on the plan
4. **Implement** → create worktree, write code, tests, fix lint/Rubocop
5. **Document** → update README.md and CLAUDE.md where necessary
6. **Finish** → open PR, offer to start the Rails server

---

## Step 1: Get the Issue

If the user hasn't provided an issue number, ask:

> "Which GitHub issue number would you like to work on?"

Once you have the issue number, fetch it using the GitHub CLI:

```bash
gh issue view <NUMBER> --json number,title,body,labels,assignees,milestone,comments
```

If `gh` isn't available or not authenticated, fall back to:

```bash
curl -s -H "Authorization: token $(gh auth token)" \
  "https://api.github.com/repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/<NUMBER>"
```

Read the full issue body and all comments carefully before proceeding.

---

## Step 2: Analyze and Plan

Before writing any code, perform a thorough analysis.

### 2a. Codebase Exploration

Explore the relevant parts of the codebase to understand the existing patterns. Use the Glob and Grep tools (not shell `grep` or `find`) to search for related files and keywords. Check existing tests in `test/` for conventions.

### 2b. Identify Conflicts and Questions

Before presenting the plan, identify:

- **Ambiguities**: anything in the issue that could be interpreted multiple ways
- **Missing context**: edge cases, error handling expectations, UI/UX details not specified
- **Conflicts**: does this touch areas with recent changes, open PRs, or architectural concerns?
- **Scope questions**: are related items in scope or explicitly out of scope?
- **Test strategy**: what level of test coverage is expected (unit, integration, system)?

### 2c. Ask Clarifying Questions

Present your questions clearly before showing the plan. Group them logically:

```
Before I finalize the plan, I have a few questions:

1. [Ambiguity question]
2. [Scope question]  
3. [Technical approach question]

Once you answer these, I'll present the full implementation plan.
```

Wait for the user's answers before continuing.

### 2d. Build the Implementation Plan

Present a structured plan that includes:

**Issue Summary**
> Brief restatement of what needs to be done.

**Approach**
> High-level technical approach and key design decisions.

**Files to Change**
> List each file and what will change (new, modified, deleted).

**New Files**
> List any new files to be created.

**Test Plan**
> - Unit tests (models, services, helpers)
> - Controller/request specs
> - System/feature tests (if UI is involved)
> - Edge cases to cover

**Documentation Plan**
> Assess which of the following need updating based on the nature of the change:
> - `README.md` — user-facing docs: setup steps, feature descriptions, environment variables, usage examples
> - `CLAUDE.md` — AI-context docs: architecture notes, conventions, commands, decisions Claude should know about

**Quality Checklist**
> - [ ] All new code has corresponding tests
> - [ ] Existing tests still pass
> - [ ] `bin/rubocop` passes with no offenses
> - [ ] `bin/brakeman` reports no warnings or errors
> - [ ] `bin/bundler-audit` and `bin/importmap audit` are clean
> - [ ] `bin/rails db:migrate` runs cleanly (if migrations added)
> - [ ] No N+1 queries introduced
> - [ ] README.md updated if user-facing behavior changed
> - [ ] CLAUDE.md updated if architecture, conventions, or AI-relevant context changed

**Out of Scope**
> Anything explicitly not being addressed in this PR.

Ask the user: "Does this plan look good, or would you like to adjust anything before I start?"

---

## Step 3: Create a Git Worktree

> **⚠️ CRITICAL: This step is mandatory. Never skip worktree creation. All implementation work MUST happen inside a worktree — never in the main working tree. Do not proceed to Step 4 until the worktree is created, you have `cd`'d into it, and you have verified your working directory is inside `.claude/worktrees/`.**

Once the plan is approved, create an isolated worktree so the main working tree stays clean.

### 3a. Choose a Branch Name

Derive a descriptive branch name from the issue:

```
issue-<NUMBER>-<slugified-title>
```

For example, issue #42 titled "Add user avatar uploads" becomes `issue-42-add-user-avatar-uploads`.

### 3b. Create the Worktree

From the project root, create the worktree inside the `.claude/worktrees/` directory. This keeps all worktrees organized and out of the main project tree.

```bash
# Ensure the worktrees directory exists
mkdir -p .claude/worktrees

# Create a new worktree with a new branch based on the default branch
# Replace <DEFAULT_BRANCH> with main, master, or whatever the repo uses
BRANCH_NAME="issue-<NUMBER>-<slugified-title>"
WORKTREE_PATH=".claude/worktrees/$BRANCH_NAME"

git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" origin/<DEFAULT_BRANCH>
```

If the branch already exists (e.g., from a previous attempt), clean it up first:

```bash
git worktree remove ".claude/worktrees/$BRANCH_NAME" --force 2>/dev/null
git branch -D "$BRANCH_NAME" 2>/dev/null
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" origin/<DEFAULT_BRANCH>
```

### 3c. Switch into the Worktree

Change into the worktree directory for all subsequent work:

```bash
cd "$WORKTREE_PATH"
```

### 3d. Verify the Environment

Confirm the worktree is set up correctly and dependencies are ready:

```bash
# REQUIRED: Verify you are inside the worktree — abort if not
pwd | grep -q ".claude/worktrees/" || { echo "ERROR: Not inside a worktree. Stop and create one."; exit 1; }

# Confirm you're on the correct branch in the worktree
git status

# Install dependencies
bundle check || bundle install

# If using JavaScript dependencies
yarn install --frozen-lockfile 2>/dev/null || true

# Prepare the test database if migrations exist
bin/rails db:prepare
```

**STOP HERE if `pwd` does not show a path inside `.claude/worktrees/`.** Go back to 3b and create the worktree before continuing. All implementation work (code, tests, commits, pushes) happens inside the worktree from this point forward.

---

## Step 4: Implement

> **Pre-flight check:** Before writing any code, verify you are working inside the worktree:
> ```bash
> pwd | grep -q ".claude/worktrees/" || { echo "ERROR: Not in a worktree. Go back to Step 3."; exit 1; }
> ```
> **Do not proceed if this check fails.** Return to Step 3 and create the worktree first.

Work through the plan systematically.

### 4a. Write the Implementation

- Follow existing code conventions (check similar files for patterns)
- Use existing abstractions and service objects rather than duplicating logic
- Keep methods small and focused
- Add comments only where the "why" is non-obvious

### 4b. Write Tests

Write tests **alongside** implementation, not after. This project uses **Minitest** with fixtures (in `test/fixtures/*.yml`).

**Coverage requirements:**
- Every new public method gets at least one test
- Happy path AND sad path (errors, edge cases, invalid input)
- Controller tests cover all new routes/actions
- If you touch a model, test its validations and associations
- Use fixtures following existing patterns in `test/fixtures/`

### 4c. Run Tests

```bash
# Run the full test suite
bin/rails test

# Run just the tests for files you've changed (faster feedback)
bin/rails test test/models/your_model_test.rb test/controllers/your_controller_test.rb
```

Fix any failures before proceeding.

### 4d. Rubocop and Lint

```bash
# Check for Rubocop offenses
bin/rubocop

# Auto-fix safe offenses
bin/rubocop -a

# Check again and fix any remaining issues manually
bin/rubocop
```

Do not proceed until Rubocop reports zero offenses. The project uses `rubocop-rails-omakase` preset (`.rubocop.yml`).

### 4e. Final Verification

```bash
# Run the full test suite one more time
bin/rails test

# If there are database migrations
bin/rails db:migrate
bin/rails db:test:prepare

# Confirm no Rubocop issues remain
bin/rubocop

# Security scans
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/importmap audit
```

---

## Step 5: Update Documentation

After the implementation is complete and tests are passing, review both documentation files and update them where the changes warrant it.

### README.md

Read the current `README.md` and assess whether any of the following have changed:

- **Setup or installation steps** — new dependencies, environment variables, or configuration required
- **Feature descriptions** — new or changed user-facing functionality that should be described
- **Usage examples** — new commands, endpoints, UI flows, or API usage
- **Environment variables** — any new `ENV` keys introduced (add them to the documented list or example `.env`)
- **Architecture overview** — significant structural changes worth capturing at a high level

Update only the sections that are affected. Do not rewrite sections unrelated to this issue. Keep the existing tone and formatting style.

### CLAUDE.md

Read the current `CLAUDE.md` (if it exists) and assess whether any of the following have changed:

- **Project conventions** — new patterns, naming rules, or coding decisions introduced in this PR
- **Architecture or structure** — new services, modules, or layers that future AI sessions should be aware of
- **Key commands** — new rake tasks, scripts, or workflows added
- **Important constraints or decisions** — anything that would help an AI agent working on this project later avoid making wrong assumptions (e.g., "We use X instead of Y because...")
- **Testing conventions** — new factories, shared contexts, or test helpers introduced

If `CLAUDE.md` does not exist and the changes are substantial enough to warrant it, create it with a brief architectural summary.

### Documentation Decision Rule

Ask yourself for each file: *"Would a developer (or AI agent) starting fresh on this project be misled or confused without this update?"* If yes, update it. Most bug fixes, refactors, and test-only changes will **not** need documentation updates — only update docs when there's a meaningful change to behavior, setup, or architecture. When in doubt, skip the doc update.

---

## Step 6: Create the Pull Request

Commit the work with a clear commit message. Stage specific files rather than using `git add -A` to avoid accidentally including sensitive files:

```bash
git add <specific files>
git commit -m "Closes #<NUMBER>: <brief description of what was done>"
git push -u origin <BRANCH_NAME>
```

Create the pull request:

```bash
gh pr create \
  --title "<Issue title>" \
  --body "$(cat <<'EOF'
## Summary

<1-3 sentence summary of what was implemented/fixed>

## Changes

- <bullet list of key changes>

## Documentation

- <README.md: describe what was updated, or "No changes needed">
- <CLAUDE.md: describe what was updated, or "No changes needed">

## Testing

- <describe how to test the changes manually>
- All unit tests pass
- Rubocop: no offenses

Closes #<NUMBER>
EOF
)" \
  --assignee "@me"
```

Share the PR URL with the user.

---

## Step 7: Offer Server Start

After the PR is created, ask:

> "The PR is up at [URL]. Would you like me to start the Rails server in the worktree so you can review the changes in the browser?"

If yes:

```bash
bin/dev
```

This starts Puma + the Tailwind watcher. If port 3000 is already in use, use `PORT=3001 bin/dev`.

If the database is empty, seed the database

```bash
bin/rails db:seed
```

---

## Error Handling

**If tests fail:** Diagnose the failure, fix the code or test, and re-run. Never skip or comment out failing tests.

**If Rubocop can't auto-fix:** Read the offense message carefully, fix manually, and verify.

**If the issue is unclear after clarifying questions:** Implement the most conservative/minimal interpretation and note assumptions in the PR description.

**If a migration is needed:** Generate it properly with `rails generate migration`, never hand-edit the schema file.

**If the worktree already exists:** Remove it with `git worktree remove <path> --force` and delete the branch with `git branch -D <BRANCH_NAME>`, then recreate.

---

## Quality Standards

Every PR produced by this skill must meet these standards before the PR is created:

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Tests | `bin/rails test` | All green |
| Rubocop | `bin/rubocop` | 0 offenses |
| Brakeman | `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` | No warnings/errors |
| Bundle audit | `bin/bundler-audit` | No vulnerabilities |
| Importmap audit | `bin/importmap audit` | No vulnerabilities |
| Migrations | `bin/rails db:migrate` | Runs cleanly |
| Schema | `git diff db/schema.rb` | Only intentional changes |
| README.md | Manual review | Updated if user-facing behavior changed |
| CLAUDE.md | Manual review | Updated if architecture or conventions changed |