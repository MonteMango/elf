# Attribute Strategy Choice — Player-Choice Analysis (2026-06-01)

**Question:** if players could CHOOSE how to spend the `+4 points/level`
random pool instead of getting random rolls, what's the optimal strategy
per fight style? Are pure-stat builds viable? Does STR+END always win?

**Test:** `testAttributeStrategiesPerClass` — 3 fight styles × 7 strategies
× 2 opponent classes = 42 cells × 5 000 battles, L12, opponents always
built with random rolls (canonical baseline).

**Code state at test time** (Session 2 / late):
- def `1str + 2int + 3end`, crit `1str + 4pow + 1int`, dodge `1str + 4agi + 1int`
- Strength damage: sqrt curve `mean = sqrt(str) × 0.6`
- INT reduction: `sqrt(int) × 0.12` (20 % of strength)
- END reduction: `sqrt(end) × 0.18` (30 % of strength) — independent roll, summed with INT
- `dodgeIntuitionSuppressionMultiplier = 1.2`, crit suppress 1.0
- `blocksPerEndurancePoint = 0.3`, `blocksLostPerAttackerStrength = 0.2`
- Exhausted: −10 % all combat attrs
- Crit EP amplification (flat-reduction, `critEPCostBonusRatio = 1.0`)

---

## Results — per class

### DEF — best: **all-STR (72.3 %)** ‼️ unexpected

| Strategy | vs crit | vs dodge | avg win % | draw-split |
|----------|--------:|---------:|----------:|-----------:|
| **all-STR** | **61.3** | **74.1** | 67.7 | **72.3** 🥇 |
| all-INT | 55.6 | 63.6 | 59.6 | 63.9 🥈 |
| STR+END | 38.9 | 56.6 | 47.7 | 52.5 🥉 |
| all-POW | 38.7 | 47.9 | 43.3 | 47.5 |
| all-AGI | 38.0 | 48.1 | 43.0 | 46.4 |
| random | 23.7 | 44.7 | 34.2 | 38.3 |
| all-END | 4.8 | 12.8 | 8.8 | **10.4** ☠️ DEAD |

### CRIT — best: **STR+END (63.9 %)**

| Strategy | vs def | vs dodge | avg win % | draw-split |
|----------|-------:|---------:|----------:|-----------:|
| **STR+END** | **79.1** | **42.3** | 60.7 | **63.9** 🥇 |
| random | 68.1 | 34.4 | 51.2 | 55.1 🥈 |
| all-POW | 84.8 | 15.3 | 50.1 | 53.0 🥉 |
| all-END | 68.8 | 21.6 | 45.2 | 47.9 |
| all-INT | 14.8 | 44.7 | 29.8 | 34.5 |
| all-STR | 39.3 | 16.7 | 28.0 | 32.8 |
| all-AGI | 21.5 | 9.1 | 15.3 | 17.7 |

### DODGE — best: **all-AGI (91.9 %)** 💀 BROKEN

| Strategy | vs def | vs crit | avg win % | draw-split |
|----------|-------:|--------:|----------:|-----------:|
| **all-AGI** | **87.7** | **94.2** | **90.9** | **91.9** 💀 GOAT |
| STR+END | 64.0 | 65.0 | 64.5 | 68.7 🥈 |
| random | 47.8 | 58.6 | 53.2 | 57.0 🥉 |
| all-STR | 23.6 | 60.7 | 42.1 | 47.2 |
| all-END | 49.0 | 22.7 | 35.9 | 39.0 |
| all-POW | 20.7 | 33.9 | 27.3 | 31.2 |
| all-INT | 4.6 | 33.1 | 18.8 | 21.8 |

---

## Key findings

### 1. Optimal strategy is **class-specific**, NOT universal STR+END

| Class | Optimal | 2nd | 3rd |
|-------|---------|-----|-----|
| def | all-STR (72.3) | all-INT (63.9) | STR+END (52.5) |
| crit | STR+END (63.9) | random (55.1) | all-POW (53.0) |
| dodge | **all-AGI (91.9)** | STR+END (68.7) | random (57.0) |

### 2. `all-AGI for dodge` is broken (91.9 %)

With 48 base agi + 48 bonus = **96 agi**, hard-cap 100:
- vs def (int 24): `dodge_min = 96 − round(24×1.2) = 67`. Mean dodge ≈ **82 %**.
- vs crit (int 12): `dodge_min = 96 − 14 = 82`. Mean dodge ≈ **89 %**.

Dodge becomes near-untouchable. No defensive stat compensates because the
dodge-first resolution avoids 80-89 % of incoming attacks outright. Weapon
damage from dodge slowly grinds the opponent down — they can't even hit back.

### 3. `all-STR for def` exploits LINEAR block-erosion

`blocksLostPerAttackerStrength = 0.2` is linear. With str 60 (1×L + 4×L bonus),
opponent loses `60 × 0.2 = 12` blocks from the EP-cost denominator. dodge/crit
with 0 base endurance now block at extreme cost — exhaust almost immediately.
Combined with def's existing END/INT defence, def becomes
high-damage-AND-tank.

### 4. `all-CORE-STAT` strategies behave wildly differently

| Class | all-CORE result | Why |
|-------|----------------|-----|
| def all-END (3×L → 7×L) | **10.4 %** ☠️ | sqrt diminishing on already-high END; no offense → can't kill |
| crit all-POW (4×L → 8×L) | 53.0 % ✓ | POW cap'd by INT suppression; crit multiplier fixed |
| dodge all-AGI (4×L → 8×L) | **91.9 %** 💀 | AGI hard-cap doesn't bite at 96; dodge chance scales linearly |

### 5. `all-END for def` is paradoxically the WORST strategy (10.4 %)

Even though END is generally valuable, **over-investing past 3×L** gives
basically nothing. def loses to opponents that random-roll 9-10 STR/POW
because she can't deal damage.

### 6. Random is **mediocre** for every class

| Class | Random rank | Score |
|-------|------------:|------:|
| def | #6 / 7 | 38.3 % |
| crit | #2 / 7 | 55.1 % |
| dodge | #3 / 7 | 57.0 % |

Random rolls protect balance by preventing min-max exploits — but no class
actually *wants* random over the optimal targeted strategy.

---

## Implications for design

### If players keep getting random rolls

✅ Current balance approximately holds (random distribution prevents
extreme builds).
✅ No urgent action needed — random is the auto-balancer.
❌ Players lose **agency** — feel of "my choice matters" missing.

### If players gain attribute choice

🚨 **`all-AGI for dodge` must be fixed first** — 91.9 % is game-breaking.
🚨 **`all-STR for def` is also problematic** — 72.3 % avg vs random
opponents means optimal-build def beats random-build def **2× as often as
it loses**.
✅ Crit's optimal STR+END at 63.9 % is closer to acceptable.

### Suggested fixes for player-choice mode

1. **AGI soft-cap on dodge chance** — formula change:
   - Option A: `dodge_effective_max = min(agi, 50)` — anything past 50 wasted
   - Option B: `dodge_chance = sqrt(agi) × k` — true diminishing returns
   - Option C: hard ceiling on dodge probability (e.g., max 60 % regardless
     of agi)
2. **STR block-erosion diminishing** — `blocksLost = sqrt(attackerStr) × 0.6`
   (mirrors strength damage curve). Removes the linear pile-on.
3. **POW reduction-pierce mechanic** — give crit a unique role that scales
   well past 48 POW (otherwise crit is permanently middling).
4. **Consider per-stat caps** — many ARPGs cap individual stat investment to
   prevent dump-strategies.

---

## Connection to other findings

- **Attribute matrix** (2026-05-28): identified STR+END as GOAT combo for
  any-class. This test refines that: STR+END is best ONLY for crit; def
  prefers all-STR; dodge prefers all-AGI.
- **L12 def>dodge inversion (random)**: makes more sense now — random
  dodge's slight endurance roll + base 48 agi is enough to beat random def.
  In choice-mode, dodge would dominate even harder via all-AGI.
- **Hidden stat triangle (STR > INT > AGI > STR)**: this matrix-level
  triangle still exists but is less relevant when class identity + bonus
  strategy interact.

---

## Files referenced

- Test method: `testAttributeStrategiesPerClass` in
  `Packages/elf_Kit/Tests/battle_simulation_IntegrationTests/BattleSimulationIntegrationTests.swift`
- Raw output: `/tmp/.../bbc1ge6rp.output` (ephemeral, regenerate by
  re-running the test).
