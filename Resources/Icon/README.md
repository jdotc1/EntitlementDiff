# EntitlementDiff Liquid Glass icon

Completed in /Applications/Icon Composer.app on 2026-10-14 with Design Generation
27 selected. EntitlementDiff.icon is the editable native source. macOS Only is
selected; watchOS is disabled. All three SVG layers retain their 1024 × 1024
canvas coordinates. Front to back: Difference, Current, Previous. The native
background is Azure with an automatic gradient. Native glass effects, neutral
shadow (0.5), and translucency (0.3) supply material depth without baked artwork
effects. No text, mask, shield, lock or trust verdict is drawn into the artwork.

Default, Dark and Mono were individually selected and visually inspected in
Icon Composer. The cyan/pale cards, three metadata lines and minus/plus tab remain
recognizable. Dark uses the system's dark enclosure; Mono retains the silhouettes
and comparison mark without depending on color. Previews/ contains 1024px exports
from Icon Composer's bundled ictool, using --design-generation 27. Native About
panel inspection also confirmed the integrated icon at its ordinary display size.

Compiled/Assets.car is the layered asset catalog. Compiled/EntitlementDiff.icns
is the compiler-generated compatibility fallback. The build script copies both
into Contents/Resources; Resources/Info.plist names EntitlementDiff in both
CFBundleIconFile and CFBundleIconName. SwiftPM source and deployment target (14.0)
are unchanged. No custom runtime icon replacement is needed.

After editing the .icon in Icon Composer, explicitly run ./script/compile_icon.sh
once and update the previews. Ordinary builds reuse the compiled resources.
Do not rerun icon compilation or unchanged validation solely for additional confidence.

Accepted icon compilation and visual inspection receipts are retained in the
private local audit. Raw workstation logs are excluded from source releases.
Icon integration evidence does not establish distribution signing.

References:
- https://developer.apple.com/design/human-interface-guidelines/icons
- https://developer.apple.com/design/human-interface-guidelines/app-icons
- https://developer.apple.com/icon-composer/
- https://developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer
- https://developer.apple.com/documentation/xcode/configuring-your-app-icon
- https://bjango.com/articles/macappiconworkflow/
- https://github.com/bjango/Bjango-Templates

Apple's separate SVG artwork layers leave material effects and enclosure masking
to Icon Composer. Bjango's silhouette, color and Dock-scale recognition principles
informed the simple overlapping-card design.
