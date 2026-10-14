# Primary-source implementation references

Consulted 2026-10-14. These document API contracts; reading them is not equivalent
to compiling against a macOS SDK or verifying runtime behavior. The live `main`
header URLs are not immutable SDK snapshots. The local SDK remains authoritative
for native compilation, and its version must be recorded at acceptance.

1. **Apple Security — SecStaticCode public header**
   https://raw.githubusercontent.com/apple-oss-distributions/Security/main/OSX/libsecurity_codesigning/lib/SecStaticCode.h
   Basis: static on-disk code references; explicit architecture attributes; the
   architecture selector can be ignored on non-Mach-O inputs; canonical paths;
   signature validity is a separate operation with filesystem-race limitations.

2. **Apple Security — SecCode public header**
   https://raw.githubusercontent.com/apple-oss-distributions/Security/main/OSX/libsecurity_codesigning/lib/SecCode.h
   Basis: generic signing-information extraction; unsigned success may omit the
   signing identifier; unverified data may be partial/invalid; metadata extraction
   does not establish signature validity. See SecCodeCopySigningInformation and
   the kSecCodeInfo declarations.

3. **Apple — kSecCodeInfoEntitlementsDict**
   https://developer.apple.com/documentation/security/kseccodeinfoentitlementsdict
   Basis: an absent decoded dictionary does not unconditionally mean that no raw
   entitlement representation exists. The adapter checks raw-blob presence and
   fails explicitly rather than interpreting an undecoded blob itself.

4. **Apple — CFBundleCopyExecutableArchitecturesForURL**
   https://developer.apple.com/documentation/corefoundation/cfbundlecopyexecutablearchitecturesforurl(_:)
   Basis: native executable architecture discovery returns architecture CFNumbers
   for Mach-O executable inputs and nil when the executable is unavailable/not
   Mach-O. Used on the resolved main-executable URL, without loading target code.

5. **Apple — CFBundle architecture constants**
   https://developer.apple.com/documentation/corefoundation/kcfbundleexecutablearchitecturex86_64
   https://developer.apple.com/documentation/corefoundation/kcfbundleexecutablearchitecturearm64
   Basis: public CPU architecture identifiers used by the native preflight.

6. **Apple — URL security-scoped resources**
   https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource()
   https://developer.apple.com/documentation/foundation/url/stopaccessingsecurityscopedresource()
   Basis: balanced explicit access lifetime for user-selected scoped URLs. A
   false start result is not used as an automatic access-denied verdict outside
   a sandbox; the actual filesystem/native read determines success.

7. **Apple — Date.timeIntervalSinceReferenceDate**
   https://developer.apple.com/documentation/foundation/date/timeintervalsincereferencedate-swift.property
   Basis: the tagged date report representation is seconds from the Foundation
   reference instant, not Unix epoch seconds or a localized date string.

No Apple implementation source or header bodies are vendored; references above
support original API-adapter code. Synthetic examples contain no user app data.
The source handoff has no third-party package dependencies. OS frameworks are
platform dependencies, not copied artifacts.
