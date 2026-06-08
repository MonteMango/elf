# Dynamic Crit + Dodge Suppression (base 0.8) — Full Run (2026-06-01)

**Change:** make both crit and dodge intuition-suppression multipliers
scale linearly with attacker level. Mirror mechanics, gentler slope on
crit (damage amp ≠ binary avoidance).

```swift
// Dodge: low-level dodgers nearly unsuppressed, high-level def's int crushes agi
dodgeIntuitionSuppressionBaseMultiplier   = 0.8
dodgeIntuitionSuppressionPerLevelDelta    = 0.04

// Crit: gentler — crit gets less boost early and lighter cap late
critIntuitionSuppressionBaseMultiplier    = 0.8
critIntuitionSuppressionPerLevelDelta     = 0.024
```

**Multiplier by level:**

| Level | Crit mult (0.8 + 0.024·L) | Dodge mult (0.8 + 0.04·L) |
|------:|--------------------------:|--------------------------:|
| L1 | 0.824 | 0.84 |
| L3 | 0.872 | 0.92 |
| L6 | 0.944 | 1.04 |
| L9 | 1.016 | 1.16 |
| L12 | 1.088 | 1.28 |

**Code state at test time:**
- def `1str + 2int + 3end`, crit `1str + 4pow + 1int`, dodge `1str + 4agi + 1int`
- Strength damage: `sqrt(str) × 0.6` (sqrt curve)
- INT reduction: `sqrt(int) × 0.12`
- END reduction: `sqrt(end) × 0.18` (independent, summed with INT)
- `blocksPerEndurancePoint = 0.3`
- **`blocksLostPerAttackerStrength = 0.1`** (lowered earlier this session)
- **Dodge suppression: dynamic 0.8 + 0.04·attLvl** (this change)
- **Crit suppression: dynamic 0.8 + 0.024·attLvl** (this change)
- Exhausted: −10 % all combat attrs
- Crit EP amplification (`critEPCostBonusRatio = 1.0`)

---

## TL;DR

✅ **L3 + L6 `crit>def` fixed** — was persistent inversion / under, now both in band.
✅ **L6 `dodge>crit` almost flipped** — was 43/46 ❌, now 45/45 ❌ tied.
✅ **DEF lost over-dominance** on L3 (mid-game shift) — now KING only at L3.
🟰 **`all-AGI for dodge` exploit unchanged** — 95.3 % (was 95.1 %).
🟰 **L3 `dodge>crit` still inverted** — single-multiplier knob can't fix it.

**Det scorecard:** 4 ✓ · 5 ~ · 1 ⚠ · 2 ❌ (was 3 ✓ / 5 ~ / 1 ⚠ / 3 ❌). +1 ✓.

---

## 1. Full Det Sweep

```
┌───────┬────────────┬───────────────────────────────┬─────────────────┐
│ Level │    Edge    │      DET adv/other/draw       │     Status      │
├───────┼────────────┼───────────────────────────────┼─────────────────┤
│    L3 │ crit>def   │ crit 42.5 / def 46.5 / 11.0   │ ✓ in band       │
│    L3 │ def>dodge  │ def 55.7 / dodge 33.8 / 10.5  │ ⚠ over          │
│    L3 │ dodge>crit │ dodge 42.9 / crit 45.3 / 11.8 │ ❌ marginal inv │
├───────┼────────────┼───────────────────────────────┼─────────────────┤
│    L6 │ crit>def   │ crit 51.4 / def 38.4 / 10.2   │ ✓               │
│    L6 │ def>dodge  │ def 49.5 / dodge 41.4 / 9.1   │ ~ just under 50 │
│    L6 │ dodge>crit │ dodge 44.9 / crit 45.0 / 10.1 │ ❌ tied (0.1pp) │
├───────┼────────────┼───────────────────────────────┼─────────────────┤
│    L9 │ crit>def   │ crit 61.2 / def 29.3 / 9.5    │ ✓               │
│    L9 │ def>dodge  │ def 47.5 / dodge 44.2 / 8.3   │ ~ under         │
│    L9 │ dodge>crit │ dodge 48.8 / crit 42.4 / 8.8  │ ~ under         │
├───────┼────────────┼───────────────────────────────┼─────────────────┤
│   L12 │ crit>def   │ crit 58.3 / def 31.8 / 9.9    │ ~ under         │
│   L12 │ def>dodge  │ def 54.9 / dodge 37.0 / 8.1   │ ~ under         │
│   L12 │ dodge>crit │ dodge 61.3 / crit 31.0 / 7.7  │ ✓               │
└───────┴────────────┴───────────────────────────────┴─────────────────┘
```

---

## 2. Per-Style Journey (Det averages across both opponents)

```
┌───────┬─────────┬──────────┬───────────┬──────────────────┐
│ Level │ DEF avg │ CRIT avg │ DODGE avg │       KING       │
├───────┼─────────┼──────────┼───────────┼──────────────────┤
│    L3 │  51.1%  │  43.9%   │   38.4%   │ 👑 DEF (over)    │
│    L6 │  44.0%  │  48.2%   │   43.2%   │ 👑 CRIT          │
│    L9 │  38.4%  │  51.8%   │   46.5%   │ 👑 CRIT          │
│   L12 │  43.4%  │  44.7%   │   49.2%   │ 👑 DODGE         │
└───────┴─────────┴──────────┴───────────┴──────────────────┘
```

### Comparison vs prior (base 0.9)

```
┌───────┬───────────────┬───────────────┬───────────────┐
│ Level │      DEF      │     CRIT      │     DODGE     │
├───────┼───────────────┼───────────────┼───────────────┤
│    L3 │ 51.1 (-1.0)   │ 43.9 (+0.9)   │ 38.4 (-0.3)   │
│    L6 │ 44.0 (-1.8)   │ 48.2 (+0.4)   │ 43.2 (+1.8) ↑ │
│    L9 │ 38.4 (-2.2) ↓ │ 51.8 (+0.9)   │ 46.5 (+1.6) ↑ │
│   L12 │ 43.4 (-1.1)   │ 44.7 (+1.0)   │ 49.2 (+0.3)   │
└───────┴───────────────┴───────────────┴───────────────┘
```

DEF lost over-dominance; CRIT/DODGE gained ground at mid levels. Triangle
rotation now: **DEF (L3) → CRIT (L6-L9) → DODGE (L12)**.

---

## 3. Strategy Test (Player Choice @ L12)

### DEF — best: **all-INT (60.2 %)**

```
┌──────────┬─────────┬──────────┬───────┬───────────────┐
│ Strategy │ vs crit │ vs dodge │  avg  │  draw-split   │
├──────────┼─────────┼──────────┼───────┼───────────────┤
│ all-INT  │   52.4% │    59.6% │ 56.0% │      60.2% 🥇 │
│ all-STR  │   39.6% │    55.8% │ 47.7% │      52.6% 🥈 │
│ all-POW  │   36.5% │    47.0% │ 41.8% │      45.6% 🥉 │
│ all-AGI  │   32.2% │    45.1% │ 38.6% │         41.5% │
│ random   │   17.9% │    37.7% │ 27.8% │         31.3% │
│ STR+END  │   16.6% │    32.4% │ 24.5% │         27.9% │
│ all-END  │    4.8% │    12.8% │  8.8% │ 10.2% ☠️ DEAD │
└──────────┴─────────┴──────────┴───────┴───────────────┘
```

### CRIT — best: **all-POW (62.4 %)**

```
┌──────────┬────────┬──────────┬───────┬───────────────┐
│ Strategy │ vs def │ vs dodge │  avg  │  draw-split   │
├──────────┼────────┼──────────┼───────┼───────────────┤
│ all-POW  │  93.4% │    26.5% │ 59.9% │      62.4% 🥇 │
│ random   │  74.9% │    40.9% │ 57.9% │      61.5% 🥈 │
│ STR+END  │  77.6% │    28.8% │ 53.2% │      55.9% 🥉 │
│ all-INT  │  23.9% │    58.8% │ 41.4% │         46.4% │
│ all-END  │  64.8% │    20.0% │ 42.4% │         45.1% │
│ all-STR  │  52.0% │    15.5% │ 33.8% │         37.7% │
│ all-AGI  │  31.8% │    14.9% │ 23.4% │         26.1% │
└──────────┴────────┴──────────┴───────┴───────────────┘
```

### DODGE — best: **all-AGI (95.3 %)** 💀 BROKEN

```
┌──────────┬────────┬─────────┬───────┬─────────────────┐
│ Strategy │ vs def │ vs crit │  avg  │   draw-split    │
├──────────┼────────┼─────────┼───────┼─────────────────┤
│ all-AGI  │  93.5% │   95.9% │ 94.7% │ 95.3% 💀 GOAT   │
│ random   │  55.2% │   51.1% │ 53.2% │      56.9% 🥈   │
│ STR+END  │  62.1% │   37.6% │ 49.8% │      53.6% 🥉   │
│ all-STR  │  35.6% │   45.9% │ 40.7% │         45.8%   │
│ all-POW  │  31.7% │   38.6% │ 35.2% │         39.3%   │
│ all-END  │  45.5% │   17.1% │ 31.3% │         34.2%   │
│ all-INT  │   8.4% │   48.6% │ 28.5% │         31.9%   │
└──────────┴────────┴─────────┴───────┴─────────────────┘
```

---

## 4. Marginal Value of Random Points @ L12

What happens when each class puts **all 4×L random points** into one stat
(vs opposing class with random rolls)?

```
┌────────────┬─────────┬─────────┬─────────┐
│  Stat dump │ DEF win │ CRIT win│ DODGE   │
├────────────┼─────────┼─────────┼─────────┤
│ all-AGI    │  41.5%  │  26.1%  │ 95.3% 💀│
│ all-STR    │  52.6%  │  37.7%  │ 45.8%   │
│ all-POW    │  45.6%  │ 62.4% 🥇│ 39.3%   │
│ all-INT    │ 60.2% 🥇│  46.4%  │ 31.9%   │
│ all-END    │  10.2% ☠│  45.1%  │ 34.2%   │
│ STR+END    │  27.9%  │  55.9%  │ 53.6%   │
│ random     │  31.3%  │  61.5%  │ 56.9%   │
└────────────┴─────────┴─────────┴─────────┘
```

**Per-class verdict:**
- **DEF best:** all-INT (60.2). Avoid all-END (it's DEAD for def — over-cap).
- **CRIT best:** all-POW (62.4). Surprisingly random (61.5) close to optimal.
- **DODGE best:** all-AGI (95.3) — game-breaking exploit.

---

## 5. Key Findings

### ✅ Wins

1. **L3 `crit>def` fixed** (40.9 → 42.5 in band). Was the most stubborn
   L3-L6 problem.
2. **L6 `crit>def` in band** (49.2 → 51.4).
3. **L6 `dodge>crit` essentially tied** (43/46 → 45/45). One small nudge
   would flip it.
4. **DEF lost over-dominance** at L6-L9. Triangle rotation now reads
   correctly: DEF early → CRIT mid → DODGE late.

### ❌ Remaining issues

1. **L3 `dodge>crit` still inverted** (dodge 42.9 / crit 45.3) — single
   suppression knob can't help dodge enough at L3 (intuition rounding
   kills the effect at low int values).
2. **L12 `crit>def` slipped slightly under band** (was 62.7 ✓, now 58.3 ~).
   The crit suppression at L12 (mult 1.088) gently caps crit overshoot
   but also drags `crit>def` under target.
3. **`all-AGI for dodge` exploit untouched** (95.3 %) — must be addressed
   structurally (cap on dodge probability or agi soft-cap).
4. **L9-L12 `def>dodge` still ~ under** — def at 47-55 % vs target 55-70.

---

## 6. Recommended Next Steps

1. **Hard cap on dodge probability** to neutralise the AGI exploit. Best
   single fix for the player-choice scenario.
2. **Tune slope split:** if we want `crit>def` to stay in band at L12,
   consider slope 0.015-0.02 for crit (was 0.024) — slightly less L12
   suppression.
3. **Address L3 `dodge>crit` structurally** — single-multiplier
   approaches don't help dodge enough at low intuition values (the
   rounding floor kills the delta). Options:
   - lower crit multiplier mean at low levels
   - boost AGI scaling at L1-L3
4. **Revisit `blocksLostPerAttackerStrength`** — currently 0.1 which
   weakens STR builds; might want to bump back to 0.15 or 0.2.

---

## 7. Trail / Other docs in this session

- `triangle-sweep-session2-sqrt-curve-2026-05-28.md` — mid-session triangle baseline
- `attribute-strategy-choice-2026-06-01.md` — player-choice exploration
- `blocks-lost-per-str-01-2026-06-01.md` — `blocksLost 0.2→0.1` experiment
- **THIS FILE** — dynamic crit+dodge suppression with base 0.8

---

## Files referenced

- `Packages/elf_Kit/Sources/DataLayer/Services/Constants/GameMechanicsConstants.swift`
- `Packages/elf_Kit/Sources/DataLayer/Services/Crit/CritDistributionStrategy.swift`
- `Packages/elf_Kit/Sources/DataLayer/Services/Crit/Implementation/ElfCritDistributionStrategy.swift`
- `Packages/elf_Kit/Sources/DataLayer/Services/Dodge/DodgeDistributionStrategy.swift`
- `Packages/elf_Kit/Sources/DataLayer/Services/Dodge/Implementation/ElfDodgeDistributionStrategy.swift`
- `Packages/elf_Kit/Sources/DataLayer/Services/Combat/Implementation/ElfSnapshotCombatCalculator.swift`
