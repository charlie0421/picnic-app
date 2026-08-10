# Responsive Splash Design

## Goal

Eliminate Fold 8 letterboxing, large-screen crop, and native-to-Flutter splash discontinuities by making the splash a layered composition rather than a single portrait poster.

## Design

Native Android and iOS display a full-window `#8B6CF6` background plus centered platform-appropriate artwork. On iOS, the launch image uses `scaleAspectFit` so the transparent key illustration scales with the available phone window instead of remaining at its intrinsic 1x size. The first Flutter frame uses the same background plus that transparent key illustration with `BoxFit.contain` and bounded maximum dimensions. The existing full-bleed `BoxFit.cover` poster is not used at startup.

Android 12 and later retain the system SplashScreen model: opaque background plus a masked icon. Android 11 and lower use a centered image over the same opaque background. iOS uses a generated launch storyboard with an aspect-fitted image. The Android 12 icon is not used as the Flutter key illustration.

## Layout Contract

- The native and Flutter background is opaque `#8B6CF6`.
- Flutter centers a transparent key image with `BoxFit.contain`.
- The Flutter key image may use the full available window and is bounded to 440 logical pixels wide and 960 logical pixels tall.
- On a 375x812 iPhone 12 mini window, the key image canvas occupies at least 95% of the viewport in both dimensions. With the existing transparent margins, the visible illustration is approximately 75% of the viewport width, matching the former full-bleed splash scale.
- Excess viewport area remains the brand background; it is never black, white, or transparent.
- No global orientation lock; foldables, tablets, and multi-window retain their available dimensions.
- Preserve `assets/splash.webp` until the new transparent asset is visually reviewed; add the new asset non-destructively as `assets/splash_key.png`.
- Do not replace or redraw native splash assets for the phone-scale correction; update only the iOS content mode and regenerated launch storyboard metadata.

## Validation

Widget tests cover 375x812 and 393x852 phones plus Fold 8 unfolded portrait and landscape constraints. Every viewport retains `BoxFit.contain` and no-overflow checks, while the 375x812 case also verifies the restored image-canvas occupancy. Generated iOS launch resources are validated after regenerating `flutter_native_splash`, followed by a physical iPhone 12 mini launch check.
