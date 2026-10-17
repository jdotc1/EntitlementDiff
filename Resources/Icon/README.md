# EntitlementDiff Liquid Glass icon

The accepted 2026-10-17 redesign is the canonical EntitlementDiff.icon source.
Four native glass groups separate the violet rear plate, refractive ice-blue
front plate, front metadata inlays, and raised amber comparison tab. The enclosure
uses a midnight indigo automatic gradient. Plates have independent tilt and
visible lower thickness contours. Rear markings correctly remain behind the
front plate. No text, security shield, trust verdict or enclosure mask is drawn.

The front plate uses Inside specular highlights and native refraction (strength
0.65, depth 0.22). Native neutral shadow and translucency are annotated per group.
Design Generation 27 renders in Previews/ cover Default, Dark and Mono. All were
visually inspected during authoring. The native source and compiled resources
were promoted unchanged from the accepted design; compilation was not repeated.
See REDESIGN_AUTHORING.md for the historical authoring commands and boundaries.

Compiled/Assets.car contains layered assets; Compiled/EntitlementDiff.icns is the
compiler-generated compatibility fallback. The existing app build script copies
both to Contents/Resources. Existing CFBundleIconFile and CFBundleIconName keys
already name EntitlementDiff and need no change. The actual locally staged app
was built/launched once after promotion; its native About panel visibly rendered
the redesigned icon next to Version 0.1.22 (23).

After changing the native document, explicitly run ./script/compile_icon.sh once
and update previews. Ordinary app builds reuse compiled icon resources. Do not
rerun unchanged compilation, tests or validation solely for additional confidence.

See docs/ICON_REDESIGN_ACCEPTANCE.md for local integration evidence. This change
does not replace the installed release or alter signing identities, permissions,
entitlements or deployment target. Raw workstation logs remain in the private
local audit; compile.log uses relative paths for the readable compiler receipt.

References:
- https://developer.apple.com/icon-composer/
- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer
- https://bjango.com/articles/macappiconworkflow/
