---
summary: "How to contribute, update from upstream, and publish Windows releases."
read_when:
  - Contributing to the Windows fork or updating its upstream version
---

# Windows fork workflow

## Branches and pull requests

- `main` copies the original CodexBar repository's `main` branch. Do not add Windows changes there.
  **Sync upstream main** updates it daily and can also be run manually. If the histories have
  diverged, the workflow must stop rather than overwrite either history.
- `windows-native-app` is the default branch and contains the Windows app. Start a
  `windows/<feature>` branch from it, then open a PR back to this fork's `windows-native-app`.
  Do not target `main` or the original CodexBar repository.
- Keep each PR focused on one change. Squash-merge it after all required checks pass, except
  upstream-update PRs, which land by fast-forward (see below).
- Keep deletion protection enabled for `main` and `windows-native-app`. Administrator bypass is
  reserved for repository maintenance, such as landing upstream updates, not ordinary PRs or failing builds.

## Upstream updates

- The Windows branch is currently based on upstream `v0.78.0`, recorded in
  `.github/windows-upstream-base`. Prefer published upstream releases when updating it. Syncing
  `main` alone does not update the Windows app.

1. Fetch upstream tags. From `windows-native-app`, start a `windows/upstream-<version>` branch and
   merge the chosen upstream release tag. Do not rebase: merging keeps the published Windows history
   intact and resolves each conflict once.
2. Keep the merge commit to conflict resolution. Make Windows adaptations in separate commits on the
   same branch, and update `.github/windows-upstream-base` to the new tag.
3. Leave `Sources/CodexBarCLI` and `Sources/CodexBarCore` identical to that upstream release. The
   Windows CI job fails if they differ from the tag in `.github/windows-upstream-base`.
4. Keep the fork's release workflow and Windows jobs when resolving `.github/workflows` conflicts.
   Upstream's macOS `release.yml` is deleted in the fork: it calls upstream's reusable release workflow,
   which the fork replaces, so GitHub would reject it on every push. Resolve its modify/delete conflicts
   by deleting it again. Upstream's release-policy workflow stays guarded to the original repository.
5. Run the Windows tests and native x64/ARM64 CI, verify the packages, and visually check the packaged
   app. Fix any failures that would block a release, then open a PR.
6. After the required checks pass on the PR's head commit, confirm `windows-native-app` has not moved and
   fast-forward it to that commit (`git push fork <head-sha>:refs/heads/windows-native-app`). GitHub then
   marks the PR as merged. Never squash-merge an upstream update: squashing drops the upstream parent, so
   the next update would conflict across every upstream change again.

- The mirror sync workflow never merges into or pushes the Windows branch.

## Builds and releases

- CI runs for PRs targeting `windows-native-app` and for pushes to that branch. The required native
  Windows checks and `lint-build-test` must pass before merging a PR.
- Run **Release artifacts** manually on `windows-native-app` to test packaging without publishing.
  The optional tag field names the output files; it does not choose which commit to build.
- Before publishing, require passing installer tests on both architectures and a visual check of
  the packaged app. Record any provider connections that have not been tested with a real account.
- Tag the tested Windows commit with a fork-specific version such as `v0.78.0-windows.1`, then
  publish a GitHub release for that tag. Publication starts the build that uploads installers,
  portable ZIPs, and checksums for both architectures. Never move a published tag or reuse an upstream tag.
- State in the release notes that packages are unsigned, and link to the WSL requirements and
  setup instructions. Do not trigger the original project's Homebrew update process.

- Build commands, code layout, tests, and packaging instructions are in the
  [Windows development guide](windows-development.md).
- User requirements, installation, credentials, and troubleshooting live in the
  [Windows user guide](windows.md).
