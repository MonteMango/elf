# RocketSim Usage (Landscape Apps)

This project runs **landscape-only**. RocketSim's accessibility tree reports element coordinates in the app's logical (landscape) space, but tap/long-press/swipe events are delivered in the simulator's **physical portrait** coordinate space. Tapping the raw `cx`/`cy` from `rocketsim elements` will silently miss the target — `rocketsim interact tap` returns `{"success": true}` even when the tap lands outside any hit zone.

## The transformation

The simulator's physical orientation is portrait. The app is rotated to landscape-right (home indicator on the right side of the visible screen, status bar on the left). To convert a landscape-space point `(lx, ly)` to a portrait-space tap point `(px, py)`:

```
px = portrait_width  - ly
py = lx
```

For iPhone 17 / iPhone 17 Pro (logical portrait size **402 × 874** points):

```
px = 402 - ly
py = lx
```

### Example

`rocketsim elements --agent` reports the Close button at landscape `(790, 32)`:

```bash
# ❌ Does not work (success: true but no UI reaction)
rocketsim interact tap 790 32
rocketsim interact tap --label "Close"

# ✅ Works
rocketsim interact tap 370 790    # 402-32=370, 790
```

## Practical workflow

1. `rocketsim simulator focused` — confirm device.
2. `rocketsim elements --agent` — list elements; remember `cx`/`cy` are landscape coords.
3. Convert to portrait coords with the formula above before calling `rocketsim interact tap <px> <py>`.
4. Re-fetch elements after each interaction to confirm the screen changed.

## What does *not* need transformation

- `rocketsim interact button home|lock|siri` — hardware buttons, no coord involved.
- Tapping the **Springboard** icon to relaunch the app (`rocketsim interact tap --label "elf"`) — Springboard is portrait, so selector-based tap works directly.
- `rocketsim interact swipe --direction up|down|left|right|...` — named directions; no coords.

## What still does *not* work in landscape

Selector-based interaction (`--label`, `--type`, `--value`) inside the elf app: RocketSim's semantic activation falls back to a coord tap at the reported center, which is in landscape space, so it misses just like a raw coord tap. **Always use the manually transformed coordinate form** for in-app taps and long-presses.

## If the device size changes

If the active simulator is no longer iPhone 17 / 17 Pro, update `portrait_width` in the formula. Read the running device with `rocketsim simulator focused` and look up the device's logical portrait size.
