v0.1.1 released and installed (2026-10-14): Reload/Retry shipped as 0.1.1 build 2.
Sanitized source commit 7d737fd, public README follow-up dcb20f9. Both source and
notarized arm64 ZIPs published to GitHub v0.1.1. Developer ID Jeffrey Cooney,
team 5HR49PU83V; Apple submission 09A8C0D9-817C-4513-A02D-F06A9EA15BBD Ready to distribute.
First new-artifact ticket/Gatekeeper checks passed. Published ZIP downloaded and
installed in /Applications; About confirms 0.1.1 (2), window open. v0.1.0 preserved
under dist/installed-backups. See evidence/94–103. Accepted 87–93 feature checks
reused; no full suite or unchanged verification repeated. Accessibility stopped.
Private local evidence/history remains unpushed. Earlier v0.1.0-only/local-feature
statements below are historical and superseded.

# Reload Inputs and Retry Inspection — 2026-10-14

Each live source pane has Reload; an inspection failure labels that action Retry.
The action rereads the retained selected URL using the current explicit architecture.
Empty/synthetic panes have no reload action. Reload Both is enabled only with two
retained live URLs, including failed inputs, and appears in the toolbar and native
Comparison menu (Shift-Command-R). UI actions are disabled during relevant reads or
file/report operations. Replace and Clear remain available under their existing rules.

Model reload routes directly through load(_:side:), retaining security-scoped access,
off-MainActor native reads, cancellation and request generations. Old snapshots and
exportable reports are invalidated before rereading. Failure preserves the URL for
Retry and remains an error, never an empty dictionary. Swapping transfers URLs with
snapshots; clearing, examples and architecture changes remove retained URLs. Reload
Both captures both URLs before mutation and invalidates both synchronously before
its tasks can run. The model also safely supports superseding an in-flight read;
UI prevents redundant reload clicks while reading. There is no persistent history,
automatic monitoring, expanded architecture selection or target execution.

## Focused evidence

- `swift test --filter ReloadInputTests -Xswiftc -warnings-as-errors` exited 0:
  five new test methods passed (evidence/87). Covers rereading same URL/architecture,
  report invalidation, failure/retry, swapped URL identity, Both eligibility and
  concurrent starts, synthetic/cleared no-op, and late completion after replacement,
  clear and architecture changes. No existing tests/full suite reran.
- `./script/build_and_run.sh > evidence/88-reload-development-launch.log 2>&1`
  exited 0. Actual SwiftUI app built, staged, development signed and launched.
  No extra signature verification or distribution operation.
- Native panels selected two disposable arm64 fixtures, initially integer 1/1.
  Only these temporary fixtures were compiled/re-signed; none was launched.
  Changed Previous to 2 at the same path; Reload showed 2/1 (evidence/89).
  Moving Previous away then reloading removed the report, showed error/Retry and
  retained Current (90). Restoring the path and Retry recovered. Changed both to
  3/4 and toolbar Reload Both showed both fresh values (91). Native menu command
  observed (92); physical keyboard shortcut not separately exercised. No execution
  marker exists. Receipt 93 summarizes exact scope.

Accepted extraction/native architecture, cancellation internals, browser, inspector,
export and published distribution checks reused. Five new methods exercised the
new orchestration without rerunning unrelated accepted methods. The development app
was visually inspected in the current appearance; no accessibility audit or system
appearance setting changes. No blanket clean-log/runtime claim.

The installed notarized v0.1.0 app and GitHub release remain unchanged. This feature
is in the local development build; a future binary update needs its own version,
signing/notarization and targeted distribution evidence. Nothing pushed online.
