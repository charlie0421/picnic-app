# PICNIC-2232 Static Fullscreen Policy Design

## Goal

Refine the fullscreen expiry policy dialog so its title is centered on the
screen and all policy sections are visible without disclosure controls.

## Layout

- Keep the existing edge-to-edge white `FullScreenDialog`.
- Center `VoteCommonTitle` against the full screen width, not the remaining
  space beside the close button.
- Give the title equal left and right reserved space so long translations
  cannot overlap the close button.
- Keep the close button in the shared fullscreen shell and inside `SafeArea`.
- Keep one vertical `SingleChildScrollView` for the complete policy content.

## Static Sections

- Remove `_Disclosure` and `_DisclosureState`.
- Render the expiry timing, example, and Picnic policy sections in their
  current order.
- Each section always renders its title and body.
- Remove disclosure arrows, tap handlers, expansion animation, expansion
  state, reveal timers, and automatic scrolling triggered by expansion.
- Keep section dividers and existing typography, copy, calculations, cards,
  wallet states, login states, and error states.

## State and Data

No provider, API, calculation, localization, or data-flow changes are in
scope. Only presentation and disclosure behavior change.

The dialog continues to support:

- logged-in and logged-out users;
- bonus and wallet loading/error/data states;
- empty and populated expiry rows;
- supported locales and text scaling;
- small screens through the existing single scroll view.

## Testing

- A widget test proves the title is horizontally centered on the screen.
- Widget/layout tests prove every section body is present immediately and no
  disclosure arrows remain.
- Tests that tap or assert collapsed state are replaced with static-section
  assertions.
- Golden images are regenerated for the existing size, locale, text-scale,
  and scroll-position matrix.
- Scoped analysis, focused dialog tests, and the full Flutter test suite must
  pass before merge approval is requested again.

## Out of Scope

- Copy or localization changes.
- Card visual redesign.
- Close-button redesign.
- Provider, API, wallet, expiry calculation, or navigation changes.
