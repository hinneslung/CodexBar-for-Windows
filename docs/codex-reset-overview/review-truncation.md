# Independent review: overview truncation fix

Source of truth: `docs/codex-reset-overview/plan.md` and the later user correction in `docs/codex-reset-overview/truncation-fix.md`.

Verdict: no blocker.

The localized `drawOverviewRow` change satisfies the correction. It measures the scheduled-reset string with the same `secondaryFont` used for rendering and compatible `DrawTextW` flags (`DT_CALCRECT | DT_SINGLELINE | DT_NOPREFIX`). Font selection is guarded, and `defer` restores the exact prior GDI object when the measurement scope exits, before normal row drawing continues.

Only a positive measurement is accepted; missing DC/font, failed selection, failed measurement, or zero width retains the former 55% split. `max(oldResetLeft, rect.right - inset - measuredWidth)` reclaims unused reset-column space without allowing the reset label to consume more than its previous 45% allocation. The existing scaled eight-pixel gap, right-aligned scheduled reset, ellipsis behavior, popup width, and row height remain unchanged.

Scope is appropriately limited to `WindowsPopupWindow.drawOverviewRow`. No new production behavior outside layout allocation, dependency, setting, or polling path is introduced. PIC owns build, native-test, and SSH VM/CUA verification; this reviewer ran none of them.
