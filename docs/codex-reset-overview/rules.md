# Epic operating rules

1. Pillow is PIC and owns task breakdown, integration, review decisions, revisions,
   simplicity, maintainability, security, unit/e2e coverage, and final delivery.
2. Use the user's configured Paseo profiles. Spawn or reuse agents in this exact
   workspace. Read profile settings before launch. Switch to an available profile
   if an agent is unavailable; do not allow availability to block progress.
3. Delegate bounded work with explicit file ownership. Parallelize independent work;
   serialize shared-file edits, builds, formatting, commits, and GUI ownership.
4. Explicitly tell every reviewer to treat `plan.md` as the original source of truth.
   Reviewers provide evidence and severity. Pillow independently evaluates correctness
   and urgency, adopts only findings Pillow agrees with, and defers noncritical scope.
5. Follow repository AGENTS.md and Windows development/fork guidance. Keep upstream
   CLI/Core unchanged, preserve provider/profile isolation, and keep tests offline.
6. Never persist credentials or user-supplied orchestration secrets in source, docs,
   logs, prompts to unnecessary parties, or screenshots.
7. Use CUA for native app launch/control and visual smoke; user permits stopping a
   running CodexBar when needed. Confirm process path and fresh build before testing.
   Use agent-browser for applicable browser smoke. Record what each check proves.
8. Save evidence and sanitized logs/URLs in `docs/codex-reset-overview`; relevant
   screenshots in `docs/screenshots`. Do not claim screenshots or mocks prove live data.
9. Work on a feature branch, open the fork PR, monitor CI and applicable manual e2e,
   fix failures iteratively, and report final status. Do not merge or publish a release
   unless separately authorized.
10. Keep the scratchpad current with assignments, decisions, outcomes, and next steps.
    Preserve the original plan; record scope clarifications separately.
