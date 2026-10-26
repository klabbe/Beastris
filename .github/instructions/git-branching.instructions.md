---
applyTo: "**"
description: "Use for all Git work in this repository: branch naming, feature development, committing, merging to main, and release preparation. This project does not use pull requests."
---

# Git branching strategy

- Keep `main` as the stable, releasable branch. Do not do routine feature or bug-fix work directly on `main`.
- Start each change from the latest `main` in a dedicated branch. Use short, descriptive kebab-case names with a type prefix:
  - `feature/<description>` for new functionality
  - `fix/<description>` for bug fixes
  - `hotfix/<description>` for urgent production fixes
  - `chore/<description>` for maintenance, tooling, or dependency updates
- Before creating a branch, inspect `git status` and preserve any existing user changes. Never reset, discard, or overwrite unrelated work.
- Keep branches focused and reasonably short-lived. Make small, meaningful commits; use imperative commit subjects, preferably Conventional Commit prefixes such as `feat:`, `fix:`, `chore:`, or `docs:`.
- Before integration, bring the branch up to date with `main` and run the relevant tests, analysis, and build checks. Fix failures introduced by the branch before merging.
- Integrate completed work directly into `main` with a local merge; **do not create or request a pull request**. Prefer a `--no-ff` merge with a descriptive merge commit so the feature branch remains visible in history.
- Do not merge unfinished or failing work. If there are conflicts, resolve them carefully without discarding either side, then rerun relevant checks.
- Do not push, force-push, delete branches, or publish releases unless the user explicitly asks. Never rewrite shared history on `main`.
- After a merge, verify the resulting `main` state and report the branch, merge commit, checks run, and any remaining unmerged work.
