# Spin Wheel Prep And Result Design

**Goal:** Redesign `指尖轮盘` so players configure the wheel on a dedicated preparation view, then enter a cleaner play view with a stronger result presentation.

## Context

The current `SpinWheelScreen` mixes setup and gameplay in one view:
- mode toggle and edit entry live in the top bar
- preset selection lives below the wheel
- there is no explicit preparation step
- result UI shows the selected segment text, but not the selected color as a first-class result
- penalty configuration is not surfaced before starting

That makes the screen feel busy and hides the game setup in scattered controls.

## Proposed UX

### Preparation View

The screen opens in a setup state.

Content order:
1. top bar: back, title, help
2. short prep description
3. preset selector directly on the page
4. mode toggle and edit entry directly on the page
5. reminder card: no player-count selector, default guidance says the game is best for up to 6 players
6. `PenaltyPresetCard`
7. bottom primary CTA: start

This keeps all setup visible without hiding it behind top-right controls.

### Play View

After tapping start:
- show the wheel as the main focus
- keep the drag-to-spin interaction
- keep the lightweight bottom hint
- remove setup controls from the top bar

### Result View

When the wheel stops:
- keep the result overlay
- show the selected option label
- show the selected color explicitly with a color swatch and hex token
- keep a textual punishment summary
- add `PenaltyBlindBoxOverlay` under the summary so the punishment component is visible and interactive

## Data Flow

- setup state remains local to `SpinWheelScreen`
- penalty preset remains local to `SpinWheelScreen`
- when `SpinPhase.result` is reached, build a blind-box result from the selected segment label
- result overlay reads the chosen segment and the generated penalty result

## Implementation Notes

- reuse existing `PenaltyPresetCard` and `PenaltyBlindBoxOverlay`
- avoid changing wheel physics logic in `SpinWheelNotifier`
- prefer adding small helper widgets inside `spin_wheel_screen.dart` rather than creating many new files
- add focused widget tests for:
  - setup screen contents
  - start button transitioning out of setup
  - result widget showing selected color info
