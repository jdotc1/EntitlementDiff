# Dimensional icon integration — 2026-10-17

## Scope and source

The user accepted the native dimensional redesign and authorized local app
integration, runtime inspection and a local commit. Promoted the accepted
DepthStudy document, SVG layers, three appearance renders and compiled resources
into Resources/Icon's canonical locations. The previous design remains in Git
history. The draft directory was removed after promotion to avoid duplicate
sources. No Swift, package, deployment, version/build, bundle icon-key or build
script changes were necessary. The existing bundle path consumes the new assets.

## Reused authoring evidence

Resources/Icon/REDESIGN_AUTHORING.md records the native Icon Composer authoring
and material edits, final Default/Dark/Mono renderer inspection, and successful
asset compilation before promotion. Its historical DepthStudy command paths now
map to the canonical Resources/Icon locations. The compile receipt is retained
as Resources/Icon/compile.log with relative output paths; the original raw receipt
remains in local icon integration evidence
No icon compilation, preview rendering or provenance hashing was repeated.

## New integration evidence

Executed once after promoting the changed icon resources:

```
./script/build_and_run.sh (local integration receipt) 2>&1
```

Exit 0. SwiftPM debug build completed in 2.87 seconds, staged bundle Info.plist
lint passed, the script applied its existing development-only ad-hoc signature
to the changed bundle and launched dist/EntitlementDiff.app.

Native Computer Use selected that exact staged app path. Its main window rendered
normally with the explicit architecture and metadata-not-trust contract visible.
Opened EntitlementDiff > About EntitlementDiff. Observed the redesigned midnight
indigo enclosure, violet rear plate, cyan front plate and amber minus/plus tab in
the native About image at its normal display size, alongside Version 0.1.22 (23).
The appearance matched the accepted design. This is direct runtime resource-use
and visual evidence, not merely process existence or compilation. No crash or
hang was observed during these interactions.

## Boundaries

Existing unchanged behavioral/native-test receipts remain reused; no tests,
corpus passes, signature verification, dependency checks or hashes were run.
Default/Dark/Mono authoring renders were reused; system appearance was not
changed for this runtime check. No accessibility work. macOS 14 fallback execution,
Finder/Dock cache refresh and clean-host acceptance were not newly exercised.
The installed release and distribution artifacts were not replaced. No Developer
ID signing, notarization, release publication, upload or online push occurred.
