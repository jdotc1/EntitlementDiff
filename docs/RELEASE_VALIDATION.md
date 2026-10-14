# Accepted local validation summary

- Original macOS baseline: 58 tests in debug and 58 in release, including eight
  native integration methods. Native compilation and local development signature
  verification passed on Apple silicon, macOS 27.2 beta, Apple Swift 6.4.
- Comparison browser: three new focused methods passed and local UI inspected.
- Application drop: six new focused policy/action methods passed. Real Finder
  drops into both panes, explicit architecture rejection and invalid-file recovery
  were observed. Native multiple-file gesture and held-hover outline were not
  separately accepted; multiple-input rejection has focused test coverage.
- Structured inspector: three focused methods passed and local UI inspected.
- Inspector navigation: six affected methods passed (three new, three existing),
  and rebuilt app search, paging, filtering and complete filtered JSON copy were
  inspected. No full-suite rerun occurred after the baseline.

Raw workstation logs, screenshots, handoff archives, personal agent instructions
and local Git history are excluded. The local audit retains those accepted receipts.
This summary is not a new test run, independent release audit or binary-distribution
qualification. Accessibility work was explicitly stopped; complete acceptance is
not claimed. AppKit sharing-indicator geometry faults were previously localized to
system stacks; no product fix or fault-free-runtime claim follows.
