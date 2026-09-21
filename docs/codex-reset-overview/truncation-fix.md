# Overview truncation follow-up

The user rejected the truncated summary visible in the delivered installer:
`prolite • 1 reset (13d) • 0 credits …`. This supersedes the earlier acceptance of
trailing-balance ellipsis in the original QA report. The original plan remains the
source of truth for feature semantics; this follow-up corrects the row allocation.

The overview assigned a fixed 45% column to the scheduled reset, wasting space when
that label is short. Measure the label with its existing font and give unused width
to the summary. Retain the current maximum reset allocation, eight-pixel gap,
ellipsis for unusually long values, and existing popup width and row height.
Fallback to the old allocation if measurement fails.

Production scope: only `WindowsPopupWindow.drawOverviewRow`, approximately 15 lines.
Fattie owns implementation; the independent reviewer treats the original plan and
this user correction as the source of truth. PIC owns integration and VM evidence.

QA environment: `hinne@192.168.1.150` (`g4-vmware-win11`), CUA in its interactive
session. Reproduce the reported summary, verify the full balance and reset timestamp
fit, check a longer date-style reset, and smoke provider navigation. Offline fixtures
exercise the real decoder and native window without real-account probes.

Deliver an updated x64 installer from the branch's manual packaging workflow after
validation. Record CI, installer, and VM evidence in this directory and screenshots
under `docs/screenshots`.
