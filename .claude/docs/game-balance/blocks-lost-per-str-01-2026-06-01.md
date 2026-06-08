# `blocksLostPerAttackerStrength: 0.2 → 0.1` — Full Test Run (2026-06-01)

**Change:** halve the strength block-erosion coefficient. Attacker's STR
burns fewer of defender's effective blocks via
`ElfEnduranceService.calculateBlockCost`:
```
denom = pool/baseCost + defEnd × 0.3 − attStr × 0.1   // was 0.2
```

**Hypothesis:** softer block-erosion would nerf STR-stacking exploits
(esp. `all-STR for def`) without harming the triangle.

**Code state:**
- def `1str + 2int + 3end`, crit `1str + 4pow + 1int`, dodge `1str + 4agi + 1int`
- Strength damage: `sqrt(str) × 0.6`
- INT reduction: `sqrt(int) × 0.12`
- END reduction: `sqrt(end) × 0.18` (independent roll, summed)
- `blocksPerEndurancePoint = 0.3`, **`blocksLostPerAttackerStrength = 0.1`** (changed)
- `dodgeIntuitionSuppressionMultiplier = 1.2`, `critIntuitionSuppressionMultiplier = 1.0`
- Exhausted: −10 % all combat attrs
- Crit EP amplification (`critEPCostBonusRatio = 1.0`)

---

## TL;DR — mixed verdict, mostly worse for random play

✅ **Fixed**: `all-STR for def` exploit (72.3 % → 49.0 %). Best fix of the change.
✅ **Improved**: Det L9–L12 `crit > def` edge moved into target band.
❌ **Worsened**: Random L12 `def > dodge` inversion (47.6 → 61.0 % dodge wins).
❌ **Worsened**: Random L12 `crit > def` overshoot (68.5 → 79.2 %).
❌ **Worsened**: `all-AGI for dodge` exploit (91.9 % → **96.8 %**).
🟰 Det scorecard: 3 ✓ → 4 ✓ (marginal +1).
🔴 Rnd scorecard: 5 ✓ → 3 ✓ (2 ✓ lost; +2 ❌ inversions).

**Net:** wrong direction for real-play (random) balance. Recommend revert
or try `0.15` as a compromise.

---

## 1. Triangle Sweep — Det

| Level | Edge | DET adv/other/draw | Status |
|------:|------|--------------------|:------:|
| L3 | crit>def | crit 40.3 / def 48.9 / 10.8 | ❌ def wins |
| L3 | def>dodge | def 57.0 / dodge 32.7 / 10.3 | ⚠ over |
| L3 | dodge>crit | dodge 42.2 / crit 45.8 / 12.0 | ❌ crit wins |
| L6 | crit>def | crit 49.4 / def 40.5 / 10.1 | ~ just under 50 |
| L6 | def>dodge | def 52.3 / dodge 38.2 / 9.5 | ✓ |
| L6 | dodge>crit | dodge 43.3 / crit 46.6 / 10.1 | ❌ crit wins |
| L9 | crit>def | crit 61.2 / def 29.3 / 9.5 | ✓ |
| L9 | def>dodge | def 49.1 / dodge 42.2 / 8.7 | ~ under |
| L9 | dodge>crit | dodge 46.7 / crit 44.2 / 9.1 | ~ under |
| L12 | crit>def | crit 62.4 / def 28.2 / 9.4 | ✓ |
| L12 | def>dodge | def 50.5 / dodge 41.7 / 7.8 | ~ under |
| L12 | dodge>crit | dodge 62.5 / crit 30.2 / 7.3 | ✓ |

**Det scorecard:** 4 ✓ · 4 ~ · 1 ⚠ · 3 ❌ (was 3 ✓ at 0.2; +1)

## 2. Triangle Sweep — Random

| Level | Edge | RND adv/other/draw | Status |
|------:|------|--------------------|:------:|
| L3 | crit>def | crit 47.9 / def 41.9 / 10.2 | ✓ |
| L3 | def>dodge | def 50.1 / dodge 39.9 / 10.0 | ✓ |
| L3 | dodge>crit | dodge 40.4 / crit 48.4 / 11.2 | ❌ crit wins |
| L6 | crit>def | crit 58.6 / def 32.1 / 9.3 | ✓ |
| L6 | def>dodge | def 45.7 / dodge 45.4 / 8.9 | ~ tied |
| L6 | dodge>crit | dodge 40.7 / crit 49.7 / 9.6 | ❌ crit wins |
| L9 | crit>def | crit 69.7 / def 22.3 / 8.0 | ⚠ over |
| L9 | def>dodge | def 39.1 / dodge 53.2 / 7.7 | ❌ dodge wins |
| L9 | dodge>crit | dodge 45.0 / crit 47.0 / 8.0 | ❌ crit wins |
| L12 | crit>def | crit 79.2 / def 14.7 / 6.1 | ⚠ extreme over |
| L12 | def>dodge | def 32.4 / dodge 61.0 / 6.6 | ❌ deep inv |
| L12 | dodge>crit | dodge 52.6 / crit 40.1 / 7.3 | ~ under |

**Rnd scorecard:** 3 ✓ · 2 ~ · 2 ⚠ · 5 ❌ (was 5 ✓ at 0.2; −2)

### Biggest random shifts

| Edge | Prior (0.2) | NEW (0.1) | Δ |
|------|------------:|----------:|---:|
| L12 crit>def | crit 68.5 (✓) | **crit 79.2** ⚠ | +10.7 overshoot |
| L12 def>dodge | dodge 47.6 (❌ tied) | **dodge 61.0** ❌ | +13.4 deeper inv |
| L9 def>dodge | def 48.2 (~) | **dodge 53.2** ❌ | flipped |
| L6 def>dodge | def 51.0 (✓) | **tied 45.7/45.4** ~ | dropped |

---

## 3. Attribute Value Matrix — STR cluster lost ~10 pp

| Rank | Champion | Prior (0.2) | NEW (0.1) | Δ |
|-----:|----------|------------:|----------:|---:|
| 1 | BAL | 68.6 | **71.6** | +3.0 |
| 2 | AGI | 58.5 | **62.7** | **+4.2** |
| 3 | STR+END | **71.1** 🥇→🥉 | 60.6 | **−10.5** |
| 4 | STR | **65.6** | 55.5 | **−10.1** |
| 5 | POW | 49.1 | 53.0 | +3.9 |
| 6 | POW+END | 46.4 | 50.5 | +4.1 |
| 7 | POW+AGI | 43.5 | 47.0 | +3.5 |
| 8 | AGI+INT | 44.8 | 46.6 | +1.8 |
| 9 | INT | 32.5 | 32.5 | 0 |
| 10 | END | 19.9 | 20.2 | +0.3 |

**Headline:** STR-cluster (STR, STR+END) lost ~10 pp each — block-erosion
was carrying much of their value. AGI/POW/BAL inherited the slack.
STR+END dropped from GOAT to #3.

---

## 4. Strategy Choice Test (per class) — meta flipped

### DEF (was: all-STR dominant)

| Rank | Strategy | Prior | NEW | Δ |
|-----:|----------|------:|----:|---:|
| 1 | **all-INT** | 63.9 (#2) | **59.2** | -4.7 |
| 2 | **all-STR** | **72.3** (#1) | 49.0 | **−23.3** ‼️ |
| 3 | all-POW | 47.5 | 45.8 | -1.7 |
| 4 | all-AGI | 46.4 | 41.3 | -5.1 |
| 5 | random | 38.3 | 26.9 | -11.4 |
| 6 | STR+END | 52.5 | 25.3 | **−27.2** |
| 7 | all-END | 10.4 | 8.4 | -2.0 |

**all-STR for def exploit FIXED** (72 → 49). New leader: **all-INT (59 %)**.
STR+END dropped hardest because half its value (STR) lost the erosion bonus.

### CRIT (was: STR+END dominant)

| Rank | Strategy | Prior | NEW | Δ |
|-----:|----------|------:|----:|---:|
| 1 | **all-POW** | 53.0 (#3) | **63.3** | **+10.3** |
| 2 | random | 55.1 (#2) | 62.9 | +7.8 |
| 3 | STR+END | **63.9** (#1) | 57.2 | -6.7 |
| 4 | all-INT | 34.5 | 50.1 | +15.6 |
| 5 | all-END | 47.9 | 46.3 | -1.6 |
| 6 | all-STR | 32.8 | 40.3 | +7.5 |
| 7 | all-AGI | 17.7 | 32.1 | +14.4 |

**all-POW becomes best for crit.** Crit's natural identity (POW + crit
multiplier) shines when STR doesn't carry block-erosion as much.

### DODGE — `all-AGI` got MORE broken

| Rank | Strategy | Prior | NEW | Δ |
|-----:|----------|------:|----:|---:|
| 1 | **all-AGI** | **91.9** | **96.8** 💀💀 | **+4.9** |
| 2 | random | 57.0 | 60.3 | +3.3 |
| 3 | STR+END | 68.7 | 56.1 | -12.6 |
| 4 | all-STR | 47.2 | 48.2 | +1.0 |
| 5 | all-POW | 31.2 | 45.9 | +14.7 |
| 6 | all-END | 39.0 | 37.0 | -2.0 |
| 7 | all-INT | 21.8 | 33.7 | +11.9 |

**Dodge's all-AGI exploit deepened** — 92 % → 97 %. Dodge survives even
longer when block-erosion is softer, dodges 90 %+ of incoming damage.

---

## Diagnosis — `squeeze the balloon` tradeoff

Lowering block-erosion shifts power **from STR builds to AGI builds**:
- STR-stacking lost its primary mechanism (block-erosion was linear, the
  one part of STR that wasn't sqrt-diminished).
- Defenders block longer → high-AGI defenders survive longer → AGI builds
  benefit disproportionately.
- AGI was already the most exploitable single stat (dodge_max scales
  linearly to 100). Less erosion = even more AGI value.

**Result:** the change traded one exploit (`all-STR def`) for a worse
one (`all-AGI dodge` worsened, random `def > dodge` inversion deepened).

---

## Recommendations

### Short-term

1. **Revert to 0.2** — Random balance worse with 0.1; only Det gained.
2. **OR try 0.15** as a compromise. Predicted: STR exploit partially
   fixed, AGI exploit slightly worsened but less so than 0.1.

### Structural

The right way to fix both exploits is **per-stat caps**, not a global
erosion knob:
1. **Cap dodge probability** (e.g., `dodge_max = min(agi, 50)` or `sqrt`
   curve on dodge chance) → fixes `all-AGI for dodge`.
2. **Cap STR block-erosion contribution** (e.g.,
   `blocksLost = sqrt(attStr) × 0.6 × C`) → fixes `all-STR for def`.

These two structural fixes would let `blocksLostPerAttackerStrength`
stay at any value without enabling exploits.

---

## Files referenced

- Constants: `Packages/elf_Kit/Sources/DataLayer/Services/Constants/GameMechanicsConstants.swift`
- Block cost formula: `Packages/elf_Kit/Sources/DataLayer/Services/Endurance/Implementation/ElfEnduranceService.swift`
- Triangle sweeps: `testStyleTriangleSweep` / `testStyleTriangleSweepWithRandomAttributes`
- Strategy test: `testAttributeStrategiesPerClass`
- Attribute matrix: `testAttributeValueMatrix`
- Prior baseline (0.2): `triangle-sweep-session2-sqrt-curve-2026-05-28.md`,
  `attribute-strategy-choice-2026-06-01.md`
