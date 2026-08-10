# Responsive Splash Design

## Goal

Eliminate Fold 8 letterboxing, large-screen crop, and native-to-Flutter splash discontinuities by making the splash a layered composition rather than a single portrait poster.

## Design

Native Android and iOS display a full-window `#8B6CF6` background plus a centered platform-safe logo. The first Flutter frame uses the same background plus a transparent key illustration with `BoxFit.contain` and bounded maximum dimensions. The existing full-bleed `BoxFit.cover` poster is not used at startup.

Android 12 and later retain the system SplashScreen model: opaque background plus a masked icon. Android 11 and lower use a centered image over the same opaque background. iOS uses a generated launch storyboard with a centered image. The Android 12 icon is not used as the Flutter key illustration.

## Layout Contract

- The native and Flutter background is opaque `#8B6CF6`.
- Flutter centers a transparent key image with `BoxFit.contain`.
- The Flutter key image is bounded to 440 logical pixels wide, 760 logical pixels tall, and 72% of the available window in either dimension.
- Excess viewport area remains the brand background; it is never black, white, or transparent.
- No global orientation lock; foldables, tablets, and multi-window retain their available dimensions.
- Preserve `assets/splash.webp` until the new transparent asset is visually reviewed; add the new asset non-destructively as `assets/splash_key.png`.

## Validation

Widget tests cover phone, Fold 8 cover, Fold 8 unfolded portrait, and Fold 8 unfolded landscape constraints. Generated Android and iOS launch resources are validated after regenerating `flutter_native_splash`.
