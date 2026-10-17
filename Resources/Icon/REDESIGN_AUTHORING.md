# Dimensional icon redesign — 2026-10-17

Status: accepted redesign, promoted into the canonical icon resources on
2026-10-17. See docs/ICON_REDESIGN_ACCEPTANCE.md for the subsequent local app
integration and native runtime inspection. Version/build and release artifacts
remain unchanged. No external write.

Design: midnight indigo enclosure; two independently tilted violet and ice-blue
glass plates; 22/26-point lower thickness contours; warm amber raised comparison
tab. Four native groups separate the rear plate, clear front plate, front metadata
inlays and floating comparison. Rear markings live with the rear plate, below the
front plate. No drawn white highlight traces remain in the final artwork.

Native authoring: opened this .icon in Icon Composer.app; visually inspected the
initial Default material composition; enabled front refraction and Inside
specular, and saved the native document. Corrected rear-marking occlusion in SVG,
removed draft highlight traces and adjusted native refraction to strength 0.65,
depth 0.22. Final Default/Dark/Mono renders were inspected from the app's own
ictool; the final geometry was not revisited in the GUI because another document
became active. These are two distinct evidence boundaries.

Executed once for each final R = Default, Dark, Mono:

```
'/Applications/Icon Composer.app/Contents/Executables/ictool' Resources/Icon/DepthStudy/EntitlementDiff.icon --export-image --output-file Resources/Icon/DepthStudy/Previews/R.png --platform macOS --rendition R --width 1024 --height 1024 --scale 1 --design-generation 27
```

Final native source compiled once successfully before promotion, receipt compile.log:
The historical DepthStudy paths below are now Resources/Icon paths; no compilation
was repeated during promotion.

```
xcrun actool Resources/Icon/DepthStudy/EntitlementDiff.icon --compile Resources/Icon/DepthStudy/Compiled --output-format human-readable-text --app-icon EntitlementDiff --include-all-app-icons --target-device mac --platform macosx --minimum-deployment-target 14.0 --output-partial-info-plist Resources/Icon/DepthStudy/Compiled/partial-info.plist
```

Compiler produced layered Assets.car, compatibility .icns and icon plist keys.
This authoring receipt establishes icon-source compilation. Subsequent user
acceptance and local app integration are recorded in ICON_REDESIGN_ACCEPTANCE.md.
Distribution readiness is outside this change. No unchanged
behavioral tests, app build, hashes or signature/dependency checks were rerun.
