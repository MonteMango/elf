# RocketSim Usage (Landscape Apps)

> ## ⚠️ FIRST: rotate the Simulator to landscape
>
> This project is **landscape-only**. Before any RocketSim geometry work, make
> sure the **Simulator device itself is in landscape**. When the device
> orientation matches the app, the accessibility tree and the tap event space are
> the **same coordinate space**, so taps land directly and your geometry
> calculations are correct — **no transform needed**.
>
> - Rotate: Simulator menu **Device → Rotate Left/Right** (or `⌘←` / `⌘→` with
>   the Simulator window focused).
> - Verify it actually rotated (a landscape-only app can render rotated *inside*
>   a portrait device window, which looks similar but is NOT landscape): the true
>   framebuffer must be **landscape** (long edge horizontal). Check with
>   `xcrun simctl io <udid> screenshot /tmp/x.png && sips -g pixelWidth -g pixelHeight /tmp/x.png`
>   — for iPhone 17 a landscape device reports **2622 × 1206 px**; a still-portrait
>   device reports **1206 × 2622 px**. (RocketSim's own screenshot is
>   portrait-normalized, so judge orientation by `simctl`, not by RocketSim.)
> - Once in real landscape, tap with the element-center coordinates directly.
>
> The coordinate-transform section below is the **fallback** for when the device
> is still in physical portrait (app rotated-in-portrait).

## Fallback: portrait device, app rotated to landscape

If the device is in **physical portrait** while the app renders landscape,
RocketSim's accessibility tree reports element coordinates in the app's logical (landscape) space, but tap/long-press/swipe events are delivered in the simulator's **physical portrait** coordinate space. Tapping the raw `cx`/`cy` from `rocketsim elements` will silently miss the target — `rocketsim interact tap` returns `{"success": true}` even when the tap lands outside any hit zone.

## The transformation

The simulator's physical orientation is portrait; the app is rotated to landscape. To convert a landscape-space point `(lx, ly)` from the accessibility tree to a portrait-space tap point `(px, py)`:

```
px = ly
py = portrait_height - lx
```

For iPhone 17 / iPhone 17 Pro (logical portrait size **402 × 874** points):

```
px = ly
py = 874 - lx
```

> **Coordinate space:** `rocketsim interact tap <px> <py>` expects **logical points** (the 402 × 874 portrait space), *not* screenshot pixels. The screenshot is 1206 × 2622 px (3× scale); passing pixel values silently misses (e.g. an x of 600 is off the 402-pt-wide screen). Divide pixels by the scale, or just use the AX→point formula above.

> **History:** an earlier version of this doc had `px = 402 - ly, py = lx`. That is **wrong** for this build — it mirrors both axes. The formula above (`px = ly, py = 874 - lx`) was verified empirically by driving a full dungeon run (menu → game day → dungeon → 4 rooms → finish): every tap landed only with this mapping.

### Example

`rocketsim elements --agent-mode debug` reports the Close button centered at landscape `(790, 32)`:

```bash
# ❌ Does not work (success: true but no UI reaction)
rocketsim interact tap 790 32
rocketsim interact tap --label "Close"

# ✅ Works
rocketsim interact tap 32 84    # px=ly=32, py=874-790=84
```

## Practical workflow

1. `rocketsim simulator focused` — confirm device.
2. `rocketsim elements --agent-mode debug` — get each element's `frame`
   (`[[x, y], [w, h]]` in landscape space). The compact `--agent` nav/act modes
   return only `id|role|label` rows **without** coordinates — use `debug` (or
   `elements` without `--agent`) when you need a frame to tap.
3. Take the element's center `(lx, ly)` = `(x + w/2, y + h/2)`, convert with the
   formula above, then call `rocketsim interact tap <px> <py>`.
4. Re-fetch elements after each interaction to confirm the screen changed.

> **Resolving the CLI:** an agent shell may not have `rocketsim` on `PATH`. Try
> `command -v rocketsim` first; otherwise use the bundled helper
> `/Applications/RocketSim.app/Contents/Helpers/rocketsim` (substitute it
> everywhere an example below starts with `rocketsim`).

## What does *not* need transformation

- `rocketsim interact button home|lock|siri` — hardware buttons, no coord involved.
- Tapping the **Springboard** icon to relaunch the app (`rocketsim interact tap --label "elf"`) — Springboard is portrait, so selector-based tap works directly.
- `rocketsim interact swipe --direction up|down|left|right|...` — named directions; no coords.

## What still does *not* work in landscape

Selector-based interaction (`--label`, `--type`, `--value`) inside the elf app: RocketSim's semantic activation falls back to a coord tap at the reported center, which is in landscape space, so it misses just like a raw coord tap. **Always use the manually transformed coordinate form** for in-app taps and long-presses.

## If the device size changes

If the active simulator is no longer iPhone 17 / 17 Pro, update `portrait_height` in the formula (the `874` constant). Read the running device with `rocketsim simulator focused` and look up the device's logical portrait size; `portrait_height` is the larger (long-edge) point dimension.
