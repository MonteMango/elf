# Elfy — Character Attributes

Single source of truth for character attributes, fight styles, and the combat
math that consumes them. Combat resolution flow lives in `game-design.md` —
this doc focuses on the **stats** themselves: what each one does, how each
fight style scales them per level, and how the **Endurance / EP** system fits in.

> **Status legend** — sections marked **(current)** describe shipped
> behaviour. Sections marked **(planned)** describe agreed design that is
> not yet in code. When implementing, prefer reading the source under
> `Packages/elf_Kit/Sources/DataLayer/Services/{Attributes,Crit,Dodge,Combat}`
> over relying on this doc — code wins on conflicts, then update this doc.

> **Balance trail:** all simulation snapshots, decision logs and tuning
> experiments live under `.claude/docs/game-balance/`. Read the
> `README.md` there for the index. Source of truth for "what's the live
> state right now" = the **Current State** section below + the actual
> constants in
> `Packages/elf_Kit/Sources/DataLayer/Services/Constants/GameMechanicsConstants.swift`.

---

## Current State (Session 2 — as of 2026-06-01)

This section overrides anything below it. The legacy sections under
"Combat Math (current)", "Secondary attribute mechanics", and the
distribution-table values are kept as historical reference but were
**superseded by the Session 2 refactors documented here**.

### Live constants (verify against `GameMechanicsConstants.swift`)

| Constant | Value | Purpose |
|----------|------:|---------|
| `dodgeIntuitionSuppressionBaseMultiplier` | `0.8` | Base for level-scaled multiplier |
| `dodgeIntuitionSuppressionPerLevelDelta` | `0.04` | `mult = 0.8 + 0.04 × attackerLevel` (L12 = 1.28) |
| `critIntuitionSuppressionBaseMultiplier` | `0.8` | Base for level-scaled multiplier |
| `critIntuitionSuppressionPerLevelDelta` | `0.024` | `mult = 0.8 + 0.024 × attackerLevel` (L12 = 1.088) |
| `critPeakWeight` / `dodgePeakWeight` | `0.6` | Peak share of stage-1 distribution |
| `critPeakPosition` / `dodgePeakPosition` | `0.0` | Peak at the low end of the rolled range |
| `critMultiplierValues` | `[0.75, 1.00, 1.25, 1.5, 2.0, 3.0]` | Unblocked crit multipliers |
| `critMultiplierWeights` | `[0, 10, 25, 35, 20, 10]` | mean ≈ **1.6375×** — applied to blocked AND unblocked crits (`blockedCritMultiplierWeights` removed; blocked crits are taxed in EP instead) |
| `exhaustedBlockDamageMultiplier` | `0.6` | weak block soaks 40 % of post-armour damage |
| `startingEP` | `2400` | EP pool every combatant starts with |
| `blocksPerEndurancePoint` | `0.3` | each Endurance point grants 0.3 effective blocks |
| `blocksLostPerAttackerStrength` | `0.1` | each attacker Strength point burns 0.1 blocks |
| `intuitionReductionCoefficient` | `0.12` | `mean reduction = sqrt(int) × 0.12` (≈ 20 % of strength damage) |
| `enduranceReductionCoefficient` | `0.18` | `mean reduction = sqrt(end) × 0.18` (≈ 30 % of strength damage) |
| `critEPCostBonusRatio` | `1.0` | crit adds a flat EP tax (`baseCost × (mult − 1) × ratio`) to the block cost |

### Strength damage curve (Session 2)

The hand-tuned 52-row `predefinedDistributions` table was replaced with a
single sqrt formula:

```
mean_damage = sqrt(strength) × 0.6
```

Distribution shape per stat value: `[floor(mean), ceil(mean)]` with
weights summing to 10 (`ceilWeight = round(fraction × 10)`). Narrow
two-value distribution, predictable variance.

Worked examples:

| str | sqrt(str) × 0.6 | Range | Weights | Mean |
|----:|----------------:|-------|---------|-----:|
| 3 (L3) | 1.04 | 1 | [1] | 1.0 |
| 6 (L6) | 1.47 | 1–2 | [5, 5] | 1.5 |
| 9 (L9) | 1.80 | 1–2 | [2, 8] | 1.8 |
| 12 (L12) | 2.08 | 2–3 | [9, 1] | 2.1 |
| 24 | 2.94 | 2–3 | [1, 9] | 2.9 |
| 48 | 4.16 | 4–5 | [8, 2] | 4.2 |
| 100 | 6.00 | 6 | [1] | 6.0 |

**Diminishing returns** baked in: doubling strength multiplies mean
damage by `√2 ≈ 1.41×` (not 2×). Implemented in
`ElfStrengthDamageDistributionStrategy`.

### Damage reduction (Session 2 — Option C + Option A)

Damage reduction has two independent contributors, both rolled per strike
and summed:

```
intReduction = sqrt(intuition)  × 0.12   // 20 % of strength damage
endReduction = sqrt(endurance) × 0.18    // 30 % of strength damage
total_reduction_per_strike = intReduction_roll + endReduction_roll
```

Each contributor uses the same shape as the strength damage curve
(`[floor, ceil]` weights summing to 10). The historical 52-row hand-tuned
endurance table was **removed**.

Worked examples at L12:

| Defender stat | int | end | per-strike reduction (mean) |
|---------------|----:|----:|----------------------------:|
| def (1str + 2int + 3end) | 24 | 36 | `sqrt(24)·0.12 + sqrt(36)·0.18 = 0.59 + 1.08 = 1.67` |
| crit (1str + 4pow + 1int) | 12 | 0 | `sqrt(12)·0.12 = 0.42` |
| dodge (1str + 4agi + 1int) | 12 | 0 | `sqrt(12)·0.12 = 0.42` |

Per-fight contribution at L12 (def): ≈ 10–18 effective HP absorbed
(depends on incoming damage).

### Block cost formula (Session 2)

```
denom = pool/baseCost
      + defenderEndurance × blocksPerEndurancePoint   //  +blocks
      − attackerStrength × blocksLostPerAttackerStrength //  −blocks
blockCost = pool / max(1, denom)
```

With `pool = 2400`, `baseCost = 400` (Recruit's Spear, 2-handed),
`blocksPerEndurancePoint = 0.3`, `blocksLostPerAttackerStrength = 0.1`:

| Defender | endurance | denom @ L12 (att str 12) | blockCost | blocks per pool |
|----------|----------:|-------------------------:|----------:|----------------:|
| def | 36 | `6 + 10.8 − 1.2 = 15.6` | **154 EP** | **15.6 blocks** |
| dodge/crit (no random) | 0 | `6 + 0 − 1.2 = 4.8` | **500 EP** | **4.8 blocks** |

Endurance defines tank-class survival; classes with `endurance = 0` exhaust
quickly and rely on random rolls for survival in random-play scenarios.

### Dodge / Crit chance (Session 2 — dynamic suppression)

Both chance rolls use a peak+linear-tail distribution but the **intuition
suppression multiplier is now level-dependent**:

```
dodgeMultiplier(attackerLevel) = 0.8 + 0.04 × attackerLevel
critMultiplier(attackerLevel)  = 0.8 + 0.024 × attackerLevel

dodge_min = defenderAgility − round(attackerInstinct × dodgeMultiplier)
dodge_max = min(100, defenderAgility)

crit_min  = attackerPower  − round(defenderInstinct × critMultiplier)
crit_max  = min(100, attackerPower)
```

| Level | dodge mult | crit mult |
|------:|-----------:|----------:|
| L1 | 0.84 | 0.824 |
| L3 | 0.92 | 0.872 |
| L6 | 1.04 | 0.944 |
| L9 | 1.16 | 1.016 |
| L12 | **1.28** | **1.088** |

Low-level dodgers / criters are barely suppressed (helps `dodge>crit` and
`crit>def` at L3). High-level intuition crushes them harder
(helps `def>dodge` at L12 + caps `crit>def` overshoot).

Service signatures took the `attackerLevel: Int` argument added in
Session 2:
- `DodgeService.calculateDodge(agility:instinct:attackerLevel:)`
- `CritService.calculateCrit(power:instinct:attackerLevel:)`

### Combat resolution flow (Session 2 — dodge-first)

Per body part, in order:

1. **Dodge roll** runs first, regardless of whether the defender blocked
   this body part. A successful dodge cancels the attack outright
   (no EP spent, no damage).
2. If dodge failed and the body part is **blocked** with EP available,
   crit is rolled. On a crit, a flat EP tax is added to the block cost
   (`baseCost × (critMultiplier − 1) × critEPCostBonusRatio`) and the
   crit lands at its **full rolled multiplier** (same
   `critMultiplierWeights`, mean 1.6375×) → `.critHit`; no crit →
   `.blocked`. If EP only partially suffices → block lands at full
   effectiveness, EP → 0, next round the defender is `Exhausted`.
3. If dodge failed and the body part is **blocked but defender has
   0 EP** and is already Exhausted → weak-block path, no EP cost.
   No-crit branch: damage = post-armour ×
   `exhaustedBlockDamageMultiplier` (0.6). Crit branch: full multiplier;
   the 0.6 is NOT applied on top (no double-dip).
4. If dodge failed and the body part is **not blocked** → normal hit
   chain (crit roll → crit hit at full multiplier mean 1.6375× or normal
   hit).

Strength damage and reduction are computed in
`ElfSnapshotCombatCalculator.calculateDamageComponents`:

```
strengthDamage   = sqrt(strength) × 0.6   (rolled)
intReduction    = sqrt(intuition) × 0.12 (rolled)
endReduction    = sqrt(endurance) × 0.18 (rolled)
attackDamage    = profile.minimumAttack...maximumAttack  (weapon)
final = max(0, attackDamage + strengthDamage − intReduction − endReduction − armor)
```

### Crit EP amplification (Session 2)

When a crit lands on a defended body part, a flat **crit tax** is added
on top of the normal (endurance- and attacker-strength-adjusted) block
cost:

```
critEPTax       = profile.epBlockCost × (multiplier − 1) × critEPCostBonusRatio
actualBlockCost = max(1, blockCost + critEPTax)
```

Algebraically identical to the earlier "flat-reduction" formulation
(amplify baseCost, subtract the flat endurance saving). High-Endurance
defenders still save the same flat EP amount from their endurance, but
the crit tax doesn't shrink with it — so def actually feels the bite
when a crit lands. When attacker strength pushes `blockCost` above
`epBlockCost`, the tax still adds on top (no accidental discount).

### Exhausted debuff (Session 2 — universal −10 %)

Battle-scoped `Exhausted` buff fires the moment a combatant ends a round
at 0 EP. Effect was changed from `str −30 %, end −30 %` to `−10 % on
ALL five combat attributes` (str, agi, pow, int, end) — the asymmetry
intentionally punishes the always-Exhausted classes (crit/dodge run out
of EP 60–87 % of the time at L12) more than the rarely-Exhausted def
(2–9 % at L12).

`Buffs.json` schema unchanged; only the `value` dictionary on the
battle-scope entry was updated.

### Fight style attribute allocations (still 6 points / level)

| Style | str | agi | pow | int | end | HP | Mana |
|-------|----:|----:|----:|----:|----:|----|------|
| **crit** | 1×L | 0 | 4×L | 1×L | 0 | 80 + 5×L | 20 |
| **dodge** | 1×L | 4×L | 0 | 1×L | 0 | 80 + 5×L | 20 |
| **def** | 1×L | 0 | 0 | 2×L | 3×L | 80 + 5×L | 20 |

Per-style identity constraints (unchanged from Round-39):
- crit — no agility, no endurance
- dodge — no power, no endurance
- def — no agility, no power

### Random attribute pool (real-play noise)

On top of fight-style points, every level rolls **+4 random points**
distributed across the 5 combat stats via
`ElfAttributeRandomizer.nextAttribute()` (uniform 20 % chance per stat).
At L12 the expected per-stat random gain is ~9.6, but with significant
variance (σ ≈ 2.8). Critically — this **adds endurance to crit/dodge**,
softening the structural `end = 0` weakness their class allocations
otherwise have.

### Removed mechanics (no longer in code)

| Removed | Replaced with |
|---------|---------------|
| `intuitionEffectRatioOfStrength` (intuition → effective strength) | Removed; intuition no longer contributes to offensive damage |
| Two-tier "Intuition → endurance reduction" gate (def_endurance==0 + power≥12 path) | Replaced by sqrt-curve `intReduction` + `endReduction` (independent rolls) |
| `enduranceReductionRatioOfStrength` + `enduranceReductionDistributionDesignRatio` ratio-scaling | Replaced; the strategy now applies `sqrt × coefficient` directly |
| `intuitionDamageReductionMultiplier` | Replaced; intuition reduction coefficient lives in `intuitionReductionCoefficient` directly |
| 52-row hand-tuned strength damage table | `sqrt(str) × 0.6` formula |
| 52-row hand-tuned endurance reduction table | `sqrt(stat) × coefficient` formula |
| `blockedCritMultiplierWeights` + `CritService.selectBlockedCritMultiplier()` | Removed; blocked crits land at the full rolled multiplier — the block's compensation is the flat EP tax (`critEPCostBonusRatio`), not a damage downgrade |
| Global-scope `Exhausted` buff (`BuffCatalogID.exhaustedGlobal`, 3-day) | Removed from the catalog; only the battle-scoped variant remains. `GameSession.applyGlobalBuff*` entry points kept for planned global buffs |

### Open / known issues (see `.claude/docs/game-balance/balance-task-2026-05-26.md`)

- **`all-AGI for dodge` exploit (95 %+ wins in matrix)** — needs a hard
  cap on dodge probability or a sqrt curve on agi.
- **L3 `dodge>crit` inversion persists** — single suppression multipliers
  can't help dodge enough at low intuition values (rounding floor).
- **L12 random `def>dodge` inversion** (dodge wins ~61 % vs target def
  60–70 %) — closing gap but not yet fixed.
- **L12 random `crit>def` overshoot** (~75 % vs target ≤ 70 %).
- **`all-END for def` (~10 %)** — pure-END investment is anti-synergistic
  with def's existing endurance allocation (sqrt diminishing).

---

## Attribute Roster

Attributes are stored on `HeroAttributes` (see
`elf_Kit/Sources/DataLayer/Model/Hero/`) and on `CombatantSnapshot` for
combat. The numeric type is `Attribute` (a typed wrapper, not raw `Int16`)
— see `type-driven-design.md`.

### Core stats (current)

| Attribute       | Role                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **Strength**    | Adds to per-attack damage (sqrt curve); pressures the defender's block economy (`blocksLostPerAttackerStrength`). |
| **Agility**     | Dodge chance.                                                            |
| **Power**       | Critical-hit chance. Crits land through blocks at the **full rolled multiplier**; the defender pays a flat EP tax for blocking a crit (see "Crit EP amplification"). |
| **Intuition**   | Suppresses opponent's dodge chance and crit chance; contributes sqrt-curve damage reduction. |
| **Endurance**   | EP-efficient blocking (`blocksPerEndurancePoint`) + sqrt-curve damage reduction. |
| **Hit Points**  | Health pool. 0 HP = defeat.                                              |
| **Mana Points** | Resource for abilities (not yet used).                                   |

Endurance is a **global, equal-rank attribute** — equipment and crystals
can grant it like any other stat. It is not exclusive to the def style.

### One attribute → one role (done)

The "Agility reduces enemy crit multiplier" coupling has been removed
(2026-05-23). Each attribute now drives exactly one mechanic:

| Attribute   | Role                                 |
|-------------|--------------------------------------|
| Strength    | damage                               |
| Agility     | dodge chance                         |
| Power       | crit chance                          |
| Intuition   | suppress enemy dodge & crit          |
| Endurance   | EP-efficient blocking                |

### Level cap

**Max hero level is 12.** All scaling tables, balance flags, and
imbalance assessments in this doc assume that hard ceiling. Stats also
gain values from equipment, but base level scaling alone never pushes
any single stat above 50, which means the dodge/crit 100%-cap (auto-
success path in stage 2) is not reachable through levelling alone.

---

## Combat Math (LEGACY — superseded by "Current State" above)

> ⚠️ **Session 2 (2026-05-27 → 2026-06-07) replaced most of the math below.**
> The current resolution flow is **dodge-first** (not block-then-dodge),
> blocked crits land at the **full rolled multiplier** (the downgraded
> `blockedCritMultiplierWeights` distribution and the "blocked-crit mean <
> unblocked-crit mean" invariant were dropped — blocked crits pay a flat
> **EP tax** via `critEPCostBonusRatio` instead), and intuition suppression
> is **level-scaled**. See the "Current State" section at the top of this
> doc for live formulas. This section retained for trail/context only.

Resolution per body part (see `ElfSnapshotCombatCalculator`):

| Situation                | Rolls performed                                                                            |
|--------------------------|--------------------------------------------------------------------------------------------|
| Attacked **and** blocked | Crit roll only. On success → `.critHit` with multiplier rolled from `blockedCritMultiplierWeights` (mean **1.85×** — block downgrades crit damage but doesn't fully cancel it); on fail → `.blocked`. EP is spent in both branches. |
| Attacked **and** blocked **+ Exhausted defender** | Weak-block path. Crit branch: multiplier from `blockedCritMultiplierWeights` (no extra penalty); no-crit branch: post-armor damage × `exhaustedBlockDamageMultiplier` (0.6 — block soaks 40%). No EP cost (defender has none to spend). |
| Attacked, **not** blocked| Dodge roll first. If dodged → done. Otherwise crit roll → crit hit (full multiplier) or normal hit. |
| Not attacked             | Nothing.                                                                                   |

Both **dodge** and **crit** use the same two-stage peak+linear-tail
distribution:

1. **Stage 1** — pick a chance value from the peak+linear-tail
   distribution (the peak takes `peakWeight` of the total probability;
   the rest tapers linearly toward both ends with floor 1). Inputs:
   - Dodge: `defender.agility` vs `attacker.intuition`
   - Crit:  `attacker.power` vs `defender.intuition`
2. **Stage 2** — roll `1...100`, succeed if `roll ≤ chance`. Auto-fail at
   `chance ≤ 0`, auto-success at `chance ≥ 100`.

Crit then runs a **Stage 3** to pick a damage multiplier from the fixed
`CritMultiplierDistribution`. Defender stats no longer skew this roll —
agility's only effect on crit damage now is upstream, via the dodge
roll cancelling the attack entirely.

**Distribution shape — peak + linear tail** (was tent until 2026-05-23).
Two knobs in `GameMechanicsConstants` per side:

| Constant | Default | Meaning |
|---|---|---|
| `dodgePeakPosition` / `critPeakPosition` | `0.0` | Where the peak sits inside the range `[stat-instinct ... min(stat,100)]`. `0.0` = peak at minimum, `0.5` = middle, `1.0` = maximum. |
| `dodgePeakWeight`   / `critPeakWeight`   | `0.6` | Exact share of total probability the peak value takes — *independent of range size*. The remaining `1 − weight` is split among non-peak values with a linear falloff from the peak toward both ends (floor 1). |

**Example** (lvl 12 dodge agility 48 vs def intuition 24, range
`[24...48]`, peak at index 0):

| Rolled value | Probability |
|---|---|
| 24 (peak) | **60%** |
| 25 | 4.4% |
| 30 | 3.5% |
| 36 | 2.4% |
| 48 | 0.2% |

The peak share no longer depends on `rangeSize`. (Old integer-tent
weighting gave the peak only `2/(N+1)` ≈ 7.7% in this case.)

**Crit multiplier distribution** — values `[0.75, 1.00, 1.25, 1.50, 2.00, 3.00]`,
weights `[0, 15, 30, 40, 10, 5]` → `E[multiplier | crit] = 1.475×` for
unblocked crits.

Blocked crits use a separate downgraded distribution
`blockedCritMultiplierWeights = [5, 30, 40, 20, 5, 0]` → `E[multiplier
| blocked crit] = 1.2375×`.

**Invariant: `blocked-crit mean < unblocked-crit mean`** — damage that
passes through a block must always be less than damage from an unblocked
crit. Earlier balance iterations (2026-05-26 rounds 14-33) ran blocked-
crit mean at 1.74-1.95× to muscle the `crit > def` edge into the 60-70 %
L12 target, but that violated the invariant: blocked crits were dealing
*more* damage on average than unblocked ones, which is illogical from
a game-design standpoint. The fix relies on crit's `strength 2×lvl`
allocation (added in step 34) to keep the `crit > def` edge in the
target band without inverting the block-mitigation relationship.

**Important nuance** — when `instinct == 0` on the opponent side, the
distribution range collapses to a single value equal to the actor's stat.
So with no instinct, **1 agility = exactly 1% dodge** and **1 power =
exactly 1% crit**. Once instinct opens the range, the peak pulls the
expected chance well below the stat value (see *Per-Point Value* below).

Implementations:
- `ElfDodgeService.calculateDodge(agility:instinct:)`
- `ElfCritService.calculateCrit(power:instinct:defenderAgility:)`
- `ElfSnapshotCombatCalculator.calculatePointStatus(...)`

### Secondary attribute mechanics (LEGACY — REMOVED in Session 2)

> ⚠️ **Both mechanics described in this subsection have been replaced.**
> The two-tier `Intuition → endurance reduction` gate is gone — damage
> reduction now uses the **sqrt curve formula** with independent
> contributions from INT and END (see "Current State" → "Damage reduction").
> The `blocksLostPerAttackerStrength` mechanic is still active, but the
> default value is now **0.1** (was 0.2). Retained for historical context.

#### Intuition → endurance reduction (LEGACY two-tier gate — REMOVED)

The defender gets a flat bonus to `enduranceReduction` per hit when
**all three core conditions** hold:

1. `defenderEndurance == 0` — rules out the def style (Endurance
   already mitigates; doubling up made def crit-immune in sim step 9).
2. `defenderInstinct >= 3` — L3+ for dodge (where the edge starts
   widening).
3. **Attacker is "dangerous"** — see the two tiers below.

**Two-tier attacker classification:**

| Attacker profile           | Threshold                  | Bonus |
|----------------------------|----------------------------|------:|
| Crit-style (`power ≥ 12`)  | always (L3+ via power)     | scaling: `max(1, min(2, round(int/6)))` → +1 at L3-L6, +2 at L9-L12 |
| Heavy-strength (`str ≥ 10`)| L10+ for str=1×lvl styles  | flat **+1** |
| Neither                    | —                          | 0 |

**Why two tiers:**
- Crit attacks burst-damage via multipliers; needs more mitigation
  (scaling bonus, up to +2).
- Heavy-strength attacks land every swing but lack crit's burst, so a
  milder flat +1 suffices.
- Threshold `str ≥ 10` (not 6) prevents over-nerfing `def > dodge` at
  L6-L9 where small absolute weapon damage makes flat −1 endRed a
  large % cut. Sim step 41 with threshold 6 collapsed L9 def_vs_dodge
  def from 64.7 → 49.4.

Implemented in `ElfSnapshotCombatCalculator.calculateDamageComponents`.

#### Strength → blocks lost (offensive pressure on blockers)

Attacker's Strength burns "effective blocks" from the defender, mirror
of how Endurance grants them. Both modifiers live in the same "blocks"
abstraction (same units, same formula):

```
cost = pool / max(1, pool/baseCost
                  + endurance × blocksPerEndurancePoint        // +blocks
                  − attackerStrength × blocksLostPerStrength)  // −blocks
```

With defaults:
- `blocksPerEndurancePoint = 0.4` → +2 Endurance grants ~+0.8 block.
- `blocksLostPerAttackerStrength = 0.2` → +5 attacker Strength burns ~1 block.

At L12 an attacker with Strength = 12 (any style except crit) burns
2.4 effective blocks from the defender; crit (Strength = 24) burns
4.8 — substantially more pressure, which is what makes
`def vs crit` matchups bleed EP faster than `def vs dodge`.

**Why blocks-based (not flat EP):** earlier flat-additive variant
(`epCostPerAttackerStrength: Int = 10` adding +120 EP per block at L12)
gave tighter EP-reserve compression but pulled defender into Exhausted
state often, which the `exhaustedBlockDamageMultiplier` mitigation
softened — eroding the `crit > def` edge. The blocks-based form is
conceptually cleaner (same units as Endurance, easier to reason about)
at the cost of a higher defender EP reserve at L12.

Implemented in `ElfEnduranceService.calculateBlockCost(baseCost:defenderEndurance:attackerStrength:)`.

### Exhausted debuff (LEGACY — value changed in Session 2)

> ⚠️ **Current Exhausted = −10 % on ALL five combat attributes** (str, agi,
> pow, int, end). The `str −30 %, end −30 %` variant described below was
> the **prior** value; sim showed it barely touched dodge's AGI and
> crit's POW (their identity stats), so it was widened to all stats to
> actually punish exhausted crit/dodge. See "Current State" above.

The battle-scoped `Exhausted` buff (`BD000000-0000-4000-A000-000000000002`)
defines what happens when a combatant runs out of EP mid-fight. By
design the effects on this buff are **balancer-tunable** — sim runs
during `balance-task-2026-05-26.md` explored several variants:

| Variant tried           | Effect on triangle |
|-------------------------|--------------------|
| `str -30%, end -30%` (current) | original; minor late-game softening |
| `str -1.0` (zero strength) | small effect — Exhausted activates too late in fight |
| `power -0.5 / -0.8 / -1.0` | mostly nerfs crit; `-1.0` flipped `crit > def` to def-favoured |
| `endurance -1.0` | further weakens defender's late-game block window |

**Verdict from sims:** modifying Exhausted is a weak lever for win-rate
tuning because the debuff fires only when EP is fully drained — usually
in the last 1-3 rounds of an 18-23-round fight, after most damage has
already been dealt. The default `str -30%, end -30%` is kept.

Future tuning can extend `Buffs.json` for the battle-scope Exhausted
entry with any per-attribute percent delta (the schema accepts
`strength`, `agility`, `power`, `instinct`, `endurance`). Just remember
the timing constraint: anything you change here only affects the tail
of the fight.

---

## Per-Point Value

> ⚠️ **Numbers below predate Session 2.** The dodge/crit tables assume the
> old fixed suppression (no level scaling) and old peak parameters;
> strength uses the removed hand-tuned table; endurance assumes
> `blocksPerEndurancePoint = 0.5` (now **0.3**). Shapes and rules of thumb
> remain directionally useful; recompute before relying on exact values.

Empirical coefficients derived from the code as of Round-39 (distribution
strategies + damage tables). Use these instead of the naive 1:1
intuitions ("1 agility = 1% dodge"); the real numbers are conditional on
the opponent's intuition.

### Dodge (1 agility)

| Defender's agility | Attacker's intuition | Mean dodge chance |
|---|---|---|
| 40 | 0  | **40%** (single-value range) |
| 40 | 10 | ~33% |
| 40 | 20 | ~27% |
| 40 | 40 | ~17% |

Rule of thumb: **1 agility ≈ 1% dodge** vs zero-intuition opponent;
**~0.6%** vs an opponent with comparable intuition.

### Crit (1 power)

Same shape, but with peak `0.2` (more aggressive instinct cut):

| Attacker's power | Defender's intuition | Mean crit chance |
|---|---|---|
| 40 | 0  | **40%** |
| 40 | 10 | ~32% |
| 40 | 20 | ~24% |
| 40 | 40 | ~10% |

Rule of thumb: **1 power ≈ 1% crit** vs zero-intuition opponent;
**~0.5%** with comparable intuition.

### Strength → mean damage (LEGACY hand-tuned table — REPLACED by sqrt curve)

> ⚠️ **Current formula: `mean = sqrt(strength) × 0.6`.** The 52-row
> `predefinedDistributions` hand-tuned table was removed in Session 2.
> The values below are kept for trail context but DO NOT match the live
> values. See "Current State" → "Strength damage curve" above for the
> active table.

From the LEGACY `ElfStrengthDamageDistributionStrategy.predefinedDistributions`:

| Strength | Mean damage |
|---|---|
| 1  | 0.25 |
| 5  | ~0.6 |
| 10 | ~1.3 |
| 12 (max from levelling) | ~1.6 |
| 20 | ~3.4 |
| 30 | ~4.5 |
| 40 | ~6.7 |
| 50 | 8.4 |

Rule of thumb: **1 strength ≈ +0.17 mean damage per attack** in the
levelling range — much weaker than the naive "+1 per round". Strength
gains most of its weight from equipment, not levels.

### Endurance

**1 endurance = `blocksPerEndurancePoint` extra effective blocks**
(universal across weapons by the rule). The constant lives in
`GameMechanicsConstants.blocksPerEndurancePoint` and is currently `0.3`
(historical default was `0.5`, the canonical "+2 Endurance = +1 block");
tune it down to make Endurance scale slower, or up (`1.0`) to make every
point grant a full block. Endurance additionally grants sqrt-curve damage
reduction (`sqrt(end) × 0.18` per strike — see "Damage reduction" in
Current State). For a typical-damage hit at lvl 12 (~5-10 base damage),
one block saves roughly that much HP — but only for a hero who actually
allocates block points.

### Per-point HP-equivalent (rough, lvl 12, both heroes with equal intuition)

Assumes ~8 HP per attack base damage and 1 attack/round.

| 1 point of … | Defensive value | Offensive value |
|---|---|---|
| agility    | ~0.05 HP/round saved | — |
| power      | — | ~0.04 HP/round dealt (incl. multiplier) |
| strength   | — | **~0.17 HP/round dealt** |
| intuition  | ~0.05 HP/round saved (cuts crit + dodge equally) | — |
| endurance  | **~0.4 HP/round saved** (when blocking, 2H) | — |

> **Reading these numbers:** strength is the strongest *offensive* point
> per unit; endurance is the strongest *defensive* point per unit, but
> only when blocks are actually being set. Power and agility are the
> weakest per-point — but both exist primarily for the **triangle**, not
> raw DPS, so this is by design.

---

## Triangle Snapshot at Max Level (lvl 12)

Stat totals from levelling alone (no equipment), using the *planned*
scaling table:

| Style  | strength | agility | power | intuition | endurance |
|--------|----------|---------|-------|-----------|-----------|
| crit   | 12 | 0  | **48** | 12 | 0 |
| dodge  | 12 | **48** | 0 | 12 | 0 |
| def    | 12 | 0  | 0 | 24 | **36** |

Effective triangle probabilities (peak+linear-tail distribution, peak at
minimum, peak weight 0.6):

| Edge | Mechanism | Effective rate |
|------|-----------|----------------|
| **dodge > crit** | dodge defender (agility 48) vs crit's intuition 12; range 36-48 peak at 36 (60%) | **~37% dodge** |
| **crit > def**   | crit attacker (power 48) vs def's intuition 24; range 24-48 peak at 24 (60%) | **~28% crit lands** (full multiplier whether blocked or not; a blocked crit additionally costs the defender the flat EP tax) |
| **def > dodge**  | dodge attacker (agility 48) vs def's intuition 24; range 24-48 peak at 24 (60%) | **~28% dodge** (down from ~37% baseline) |

The peak-weight model concentrates roll outcomes near the minimum, so
effective rates are 5-15 pp below the old tent-shape baseline. Confirmed
by win-rate simulation — see Open Balance Flags.

---

## Open Balance Flags

> ⚠️ **Архив Round-39 (2026-05-24 → 2026-05-26).** Замеры и конфигурации
> ниже сняты ДО Session 2: старые crit-веса `[0,15,30,40,10,5]`,
> `blockedCrit`-механика (удалена), `startingEP = 2000` (сейчас 2400),
> ручные таблицы урона (заменены sqrt-кривыми). Актуальные свипы — в
> `.claude/docs/game-balance/` (Session 2 snapshots); актуальные открытые
> вопросы — в "Open / known issues" секции Current State выше.

Известные или предполагаемые проблемы. Решать симуляцией, не интуицией.

### Измеренные win-rate треугольника (lvl 12 vs lvl 12, 30 000 боёв, без экипировки)

Цель по дизайну: победитель 60-70% / ничья 0-10% / проигравший 30-40%.

**Текущая конфигурация** (2026-05-24):
- `peak+linear` распределение, `peakPosition = 0.0`, `peakWeight = 0.6`
- agility ↛ crit-multiplier связка удалена
- `critMultiplierWeights = [0,15,30,40,10,5]` (mean множителя 1.475×)
- `blockedCritMultiplier = 1.0` (блокированный крит = обычный урон, статус остаётся `.critHit`)
- HP всех стилей = `80 + 5×lvl` (140 на lvl 12)

Замеры — среднее из 3 прогонов × 30 000 боёв (разброс ≤ 0.5 pp на эдж,
выборка 30k достаточно репрезентативна).

| Эдж           | Win    | Draw | Lose  | Σ разброс | Вердикт |
|---------------|--------|------|-------|-----------|---------|
| dodge > crit  | 69.5%  | 8.3% | 22.2% | ±0.15 pp  | ✓ верхняя граница цели |
| crit > def    | 63.6%  | 9.8% | 26.7% | ±0.10 pp  | ✓ центр цели |
| def > dodge   | 59.4%  | 7.1% | 33.6% | ±0.25 pp  | ✓ нижняя граница цели (−0.6 pp) |

Разбивка по прогонам:

| Эдж | Run 1 | Run 2 | Run 3 |
|-----|-------|-------|-------|
| dodge > crit | 69.7 / 8.2 / 22.1 | 69.4 / 8.2 / 22.4 | 69.5 / 8.4 / 22.1 |
| crit > def   | 63.5 / 9.6 / 26.9 | 63.7 / 9.7 / 26.6 | 63.5 / 10.0 / 26.6 |
| def > dodge  | 59.1 / 7.1 / 33.8 | 59.4 / 7.1 / 33.5 | 59.6 / 7.1 / 33.4 |

**Все три эджа в дизайн-коридоре одновременно.** Триангл сбалансирован.

### Эволюция win-rate (для истории)

| Итерация | dodge>crit | crit>def | def>dodge |
|----------|------------|----------|-----------|
| Baseline (старый tent 0.4/0.2, crit weights `[0,5,15,40,30,10]`, agility-decreaser активен, blockedCrit = rolled) | 62/9/29 ✓ | 89/5/7 ⚠⚠ | 14/5/81 ✗ |
| + peak+linear `0.0/0.6` для dodge & crit | 60/9/31 ✓ | 84/6/10 ⚠ | 21/7/72 ✗ |
| + удалён agility→crit-multiplier + softer mults `[0,15,30,40,10,5]` + `blockedCrit = 1.0` | 54/10/36 ⚠ | 72/9/19 ⚠ | 21/7/72 ✗ |
| **+ HP `80 + 5×lvl` для всех стилей** (avg of 3 × 30k) | **69.5/8.3/22.2 ✓** | **63.6/9.8/26.7 ✓** | **59.4/7.1/33.6 ✓** |

### Почему +5HP/lvl сработал именно сейчас

Раньше (когда я тестировал +5HP/lvl поверх baseline-механик в самом начале)
он **ухудшал** баланс — длинные бои уменьшали дисперсию и дома убивали слабую
сторону ещё стабильнее. Сейчас он **исправил** баланс, потому что
предшествующие изменения уже выровняли DPS:
- удалённый agility-decreaser и softer multiplier weights дали crit-у нормальный, нечрезмерный урон
- `blockedCrit = 1.0` отнял у crit «двойную награду» против блока def
- HP +5/lvl растянул бои с ~10-15 раундов до ~18-25, что вскрыло **EP-bottleneck**
  у dodge: 86-88% пула расходуется, block coverage падает с 36% до 25% — dodge
  буквально не успевает блокировать в поздней игре. def с его endurance-discount-ом
  использует только 30-39% пула и держит coverage 40% всё битву.

### EP-диагностика на текущей конфигурации

| Матчап | Bot1 EP% / coverage | Bot2 EP% / coverage | Avg blocks (Bot1 / Bot2) | Avg battle length |
|---|---|---|---|---|
| dodge vs crit | 86.8% / 28.4% | 86.1% / 28.1% | 5.78 / 5.74 | ~20-21 раунд |
| dodge vs def  | 88.6% / 24.7% | 38.9% / 40.1% | 5.91 / 9.60 | ~24 раунда |
| crit vs def   | 84.3% / 30.1% | 30.2% / 39.9% | 5.62 / 7.47 | ~19 раундов |

(Bot1 = атакер первой колонки, Bot2 = атакер второй.)

**Endurance-asymmetry** — главный «балансер»: dodge/crit при endurance 0 не могут
сберечь EP в длинных боях, а def при endurance 36 платит 71-87 EP за блок
вместо 200-300 и сохраняет полное покрытие до конца.

(Методика: `BattleSetupScreen` → кнопка 1000x → `PerfTestConfig.multiBattleCount = 30000`. Bot AI выбирает атаку/блок равномерно случайно; loadout по умолчанию = Recruit's Spear, без прочей экипировки.)

### Корневые причины

1. **`def > dodge` инвертирован (несущая грань треугольника).**
   Под капотом на lvl 12:
   - Оба героя выбирают 1 атаку + 2 блока за раунд случайно из 5 частей
     тела. **Покрытие блоком = 2/5 = 40%** для обоих. То есть бюджет
     блоков симметричен — Endurance не даёт def *никакого* преимущества
     в этом матчапе.
   - dodge-защитник: agility 48 vs def's intuition 24 → шанс додж ~35%
     на 60% атак, попадающих по неблокированным частям.
   - dodge суммарное избегание ≈ 40% блок + (60% × 35%) = **~61%**.
   - def суммарное избегание ≈ 40% блок, ноль доджа, ноль крит-пирса =
     **~40%**.
   - При одинаковых 80 HP и одинаковой силе 12, у dodge эффективно
     ~1.5× HP при одинаковом уроне → выигрывает ~81%.
   - **Endurance структурно мёртв в этом матчапе.** У def 24 блока
     (2H) / 30 (1H); бот тратит за бой только ~5-6 блоков (≈14 раундов
     × 0.4 совпадения атака↔блок), поэтому EP никогда не кончается,
     поэтому Endurance ни на что не влияет.
   - Дополнительные удары по def: planned scaling убрал бонус HP
     (`80 + 2×lvl` → `80`) и срезал силу с `+2` до `+1`. По сравнению
     со старым кодом def потерял ~24 HP и ~12 силы, не получив ничего
     взамен в данном матчапе (EP в работу не вступает).

2. **`crit > def` перебивает цель (88.8% вместо ~65%).**
   - crit-атакер: power 48 vs def intuition 24 → шанс крита ~29-33%
     за удар. Крит пробивает блоки (блок + крит = полный урон).
   - Средний крит-множитель 1.74×, ожидаемый урон за атаку ≈ 0.98×
     base. Против атак def (нет крита, нет доджа) crit получает только
     ~0.60× base за атаку → crit наносит ~1.5× DPS от def.
   - При одинаковых 80 HP crit убивает def за ~9 раундов, получая
     60% урона. Измеренная средняя длительность 9.2 раунда — линейная
     гонка HP, которую def проигрывает.
   - У def ноль офенсивных инструментов против crit: 0 power (нет
     своих критов), 0 agility (не может уворачиваться), 24 intuition
     срезает шанс крита врага только до ~30% (всё ещё много).
   - **(исторически)** до 2026-05-23 крит пробивал блок с полным
     множителем, и EP всё равно тратился — «двойной налог» по тем
     цифрам. Сейчас правило изменено: блок снижает крит-множитель до
     `1.0×` (= обычный урон), EP по-прежнему расходуется. Двойного
     налога больше нет; конкретные win-rates на новой механике см.
     ниже («Crit + block downgrade»).

3. **`dodge > crit` укладывается в цель (62% / 9% / 29%).** Это
   единственный эдж, где текущая математика распределений и бюджет
   статов сходятся с дизайном. Обе стороны вкладываются симметрично
   (48 одной, 12 другой), а механика доджа естественно выигрывает,
   потому что додж отменяет всю крит-цепочку.

### Предложения по изменению механик (нужно тестировать)

Чтобы попасть в 60-70 / 0-10 / 30-40, нужно добавить новые источники
асимметрии для def. Эдж dodge > crit изменений не требует.

**A. Вернуть def бонус HP (откатить часть planned scaling).**
План передвинул def с `80 + 2×lvl` HP на `80` flat. На lvl 12 это
−24 HP (30% от пула). Вернуть как `80 + 3×lvl` → 116 HP на lvl 12.
Только эта правка стоит ~+15% win rate против dodge и ~+8% против
crit в линейной гонке урона. Самое дешёвое и наименее инвазивное.

**B. Сделать Endurance реально дефицитным ресурсом или пассивным
бафом (а не множителем количества блоков).**
Текущее правило `+0.5 эффективных блоков на endurance` даёт столько
блоков, что почти ни в одном бою они не расходуются, поэтому
endurance вносит ноль в симуляциях lvl 12. Варианты:
- *(B1) Уменьшить объём блоков.* Снизить базовый пул EP с 2000 до
  1000 и удвоить базовые стоимости (2H = 800, 1H = 400). Endurance
  по-прежнему даёт `+0.5 блока` за очко. Итог: у def ~2 базовых +
  ~9 эндюрансных = 11 блоков на 2H, что РЕАЛЬНО кончается к ~10-12
  раунду против crit, заставляя def отказываться от блоков в поздней
  стадии и вознаграждая инвестиции в endurance.
- *(B2) Endurance даёт пассивную митигацию урона на успешных блоках.*
  Когда блок оплачен, урон от крита, пробившего блок, снижается на
  `min(50%, endurance × 1%)`. На endurance 36 → 36% митигации на
  пробитых критах. Прямо бьёт по проблеме crit > def, не задевая
  другой матчап.

**C. Дать def инструмент против dodge.**
Сейчас у def нет отдельного стат-рычага, чтобы давить шанс доджа
противника помимо общей intuition. Два простых варианта:
- *(C1) Endurance также подавляет вражеский шанс доджа.* Считать его
  вторым `instinct`-эквивалентом только для додж-ролла, с
  коэффициентом 50% (то есть 36 endurance читается как +18
  додж-подавления). На lvl 12 dodge vs def шанс доджа защитника
  упадёт с ~35% до ~22%, суммарное избегание с 61% до ~53%. В
  сочетании с (A) должно привести def-vs-dodge к ~60/10/30.
- *(C2) Скейлинг силы для def.* Вернуть `+2×lvl` силы (план снизил
  до `+1`). На lvl 12 → strength 24 ≈ +3.4 урона/атаку против
  текущих ≈ +1.6. Чистый DPS-рычаг. Дешевле в реализации, но грубее
  — применяется во всех матчапах, в том числе в def vs crit, где
  def уже проигрывает гонку.

**D. Смягчить crit, понизив верхнюю границу множителя.**
Текущее распределение множителей `[0.75, 1.00, 1.25, 1.50, 2.00,
3.00]`, веса `[0, 5, 15, 40, 30, 10]` → mean 1.74×. Два рычага:
- *(D1) Убрать 3.00-уровень.* Новые веса `[0, 5, 15, 40, 30, 0]`
  плюс перераспределить 10% обратно в 2.00 → веса `[0, 5, 15, 40,
  40, 0]` → mean 1.59×. Простая правка в `GameMechanicsConstants`.
- *(D2) Сдвинуть peak шанса крита.* Peak crit = 0.2 (низко, делает
  шанс крита заметно меньше сырого power). Перевод на 0.3 повышает
  ожидаемый шанс против целей с нулевой intuition, но снижает против
  тех, кто вкладывается в intuition. Скорее всего, **не подходит**
  тут — ухудшит crit > def, а не поможет.

**Рекомендованная стартовая комбинация для теста:** A + C1 + D1.
Ожидаемый эффект: def-vs-dodge поднимется до ~55-65%, crit-vs-def
упадёт до ~70-80%, dodge-vs-crit останется на месте. После симуляции
итерировать численными константами B1/B2 только если A + C1 + D1
оставит crit > def выше ~75%.

### Дополнительная диагностика (EP / Block coverage, lvl 12, 30k батлов)

`MultiBattleViewModel.logBalanceDiagnostics` теперь печатает в unified
log (`NSLog`, тег `ELFBAL`) использование EP, число блоков (вызванных
и реально потраченных), покрытие блоком и количество боёв, где EP
полностью истощился. Захват: `xcrun simctl spawn booted log stream
--predicate 'eventMessage CONTAINS "ELFBAL"'`.

| Матчап         | EP-pool (Bot1/Bot2) | Avg EP spent (Bot1/Bot2)    | Avg blocks used (Bot1/Bot2) | Block coverage (Bot1/Bot2) | Battles EP exhausted |
|----------------|----------------------|-----------------------------|-----------------------------|----------------------------|----------------------|
| dodge vs crit  | 2000 / 2000          | 1407 (70%) / 1370 (69%)     | 4.69 / 4.57                  | 36.7% / 35.8%              | 0% / 0%              |
| dodge vs def   | 2000 / 2000          | 1495 (75%) / 466 (23%)      | 4.98 / 5.76                  | 34.7% / 40.1%              | 0% / 0%              |
| crit vs def    | 2000 / 2000          | 1078 (54%) / 299 (15%)      | 3.59 / 3.69                  | 38.9% / 40.0%              | 0% / 0%              |

Выводы из диагностики:
1. **EP-пул одинаковый = 2000 для всех** (см. `GameMechanicsConstants.startingEP`).
   Endurance НЕ увеличивает пул — он только снижает стоимость блока.
2. **Дефолтный Recruit's Spear имеет epBlockCost 300** (1H-цена выше
   докового базового 200). При endurance 0 → 6.67 max блоков (бой
   ~12-14 раундов ≈ 4-5 блоков используется → впритык). При
   endurance 36 → 81 EP/блок, 24.7 max блоков.
3. **У def 4-7× запас EP, который не нужен.** В матчапе dodge vs def
   def тратит 23% пула; в crit vs def — всего 15% (бой короткий).
   Endurance ни разу не становится bottleneck-ресурсом.
4. **dodge напротив на грани истощения EP** (74.7% пула в dodge vs def
   — 5 блоков из 6.67 максимума). Если бой удлинится, dodge не сможет
   блокировать в поздней игре.
5. **Block coverage ≈ 40%** для всех (= 2 блока / 5 частей тела при
   случайном выборе ботом). Кроме dodge, где coverage падает до
   35-36% из-за приближения к EP-границе.

### Эксперимент: +5 HP на уровень

Идея пользователя: «увеличить HP +5 за уровень, чтобы блоки эффективнее
работали в более длинном бою». Протестировано — результат **не такой,
как ожидалось**:

| Конфигурация            | dodge vs crit | def vs dodge | crit vs def |
|--------------------------|---------------|--------------|-------------|
| baseline (HP 80 всем)    | dodge 62% ✓   | def 14% ✗    | crit 89% ⚠ |
| +5HP/lvl всем (HP 140)   | dodge 82% ⚠   | def 20% ✗    | crit 92% ⚠ |
| +5HP/lvl только def (140 vs 80) | (не тест.) | def 85% ⚠⚠ | crit 23% ⚠⚠ |
| +3HP/lvl только def (116 vs 80) | (не тест.) | def 59% ✓  | crit 51% ⚠ |
| +2HP/lvl только def (104 vs 80) | (не тест.) | def 43% ✗  | crit 66% ✓ |

Ключевые выводы:
- **Универсальный +5/lvl УХУДШАЕТ баланс.** Длинные бои уменьшают
  дисперсию → доминирующая сторона побеждает ещё стабильнее. Слабая
  сторона теряет шанс на «выстрелить из ничего».
- **HP-буст только для def работает в нужном направлении**, но
  никакое одно значение не попадает в обе цели одновременно. +2HP/lvl
  для def фиксит crit vs def (66% ✓), но оставляет def vs dodge
  инвертированным (43%). +3HP/lvl фиксит def vs dodge (59% ✓), но
  опускает crit vs def слишком низко (51%).
- **Нужна комбинация HP + другого рычага.** Например: `def +2HP/lvl
  (старый scaling)` + `C1: endurance подавляет вражеский додж`
  должно дать `def vs dodge ~55-65%` и `crit vs def ~65%` одновременно.
  Или: `def +3HP/lvl` + `D1: уменьшить mean crit multiplier с 1.74×
  до 1.59×` — компенсирует «слишком мягкий crit vs def».

**Рекомендация по HP:** не идти на универсальный +5HP. Если двигаться
быстрым путём — `def-only +2HP/lvl` (восстанавливает старый scaling
из текущей реализации до planned-изменения) **плюс** второй рычаг
(C1 предпочтительнее — точечно бьёт по проблеме def vs dodge).

### Прочие известные флаги

4. **Agility/power асимметрия из-за позиций peak.** Dodge peak `0.4`
   vs crit peak `0.2` делает один и тот же численный стат на ~25%
   эффективнее со стороны доджа. Подтверждено симуляцией: dodge > crit
   попадает в цель *именно из-за* этой асимметрии; перевод обоих peak
   на `0.3` ослабит матчап доджа против крита и **не рекомендуется**,
   пока эдж dodge > crit не начнёт перебивать цель.
5. **Linear scaling assumed safe at lvl 12.** Максимум от левелинга —
   48 (crit power, dodge agility), поэтому 100% auto-success cap
   недостижим только за счёт уровней. Экипировка может выйти за
   границу — балансится отдельно.

### Per-level scaling

#### Round-39 allocation (superseded — see "Fight style attribute allocations" in Current State)

> Session 2 reverted crit to the canonical `str 1×L + pow 4×L + int 1×L`
> (the step-34 `str 2×L / int 0` experiment below was superseded by the
> level-scaled intuition suppression doing the `crit > def` work instead).

| Style    | strength | agility | power   | intuition | endurance | hit points |
|----------|----------|---------|---------|-----------|-----------|------------|
| `crit`   | +2×lvl   | 0       | +4×lvl  | 0         | 0         | 80 + 5×lvl |
| `dodge`  | +1×lvl   | +4×lvl  | 0       | +1×lvl    | 0         | 80 + 5×lvl |
| `def`    | +1×lvl   | 0       | 0       | +2×lvl    | +3×lvl    | 80 + 5×lvl |

#### Hard rule: **exactly 6 stat points per level, per style**

Each fight style allocates **6 stat points** at every level
(`strength + agility + power + intuition + endurance == 6`). HP and
Mana sit outside this budget and follow shared, **per-style-immutable**
scaling: HP = `80 + 5×lvl`, Mana = 20 flat. Per-style HP/Mana scaling
is forbidden by design.

When rebalancing a style, **any point removed from one stat must be
added to another** combat attribute — the 6-point invariant is
load-bearing for relative power between styles.

#### Per-style identity constraints (2026-05-26)

| Style | Forbidden stats     | Why                                          |
|-------|---------------------|----------------------------------------------|
| crit  | agility             | Agility is dodge's identity. Crit has 0.    |
| dodge | power               | Power is crit's identity. Dodge has 0.      |
| def   | agility, power      | Def neither dodges nor crits — it absorbs.  |

#### Worked example: crit's allocation

The canonical crit allocation `str 1, pow 4, int 1, end 0, agi 0 = 6`
ran into a balance constraint during the `balance-task-2026-05-26.md`
tuning. Zeroing `intuition` was the cleanest asymmetric `dodge > crit`
lever (sim step 3 added +10 pp dodge rate at L12), but the 6th point
then needed a home that:
- Satisfies the no-agility identity constraint.
- Doesn't break a different triangle edge.

Sim experiments tested every alternative:
- `end 1×L` (sim step 19) — crit longevity over-buff, win rate vs def → 77 %, vs dodge → 51 %.
- `pow 5×L` (sim step 28) — crit chance vs def jumped from 27 % to 40 %, win rate → 78 %.
- `mana scaling +1×L` (sim step 30) — works for balance but violates the "no per-style HP/Mana scaling" design rule.
- `str 2×L` (sim step 34, **final choice**) — raises crit's per-hit damage; combined with the logical fix (blocked-crit < unblocked-crit) lands `crit > def` cleanly in target.

Notes:
- All styles share the same `+5 HP/level` scaling. Battles are longer
  (more rolls per fight = lower variance) and EP discipline matters more,
  since blocks stretch over more rounds without the pool getting larger.
- def's identity is **tactical staying power** via Endurance, not a fat
  HP bar — every style now has the same HP pool.
- Numbers are tuned during balancing; see *Open Balance Flags* below for
  the latest measured triangle.

---

## Style Triangle: `def > dodge > crit > def`

A soft rock-paper-scissors. The intent is **slight** advantage (~60 / 10 /
30), not auto-win. Each edge is grounded in mechanics, not magic numbers:

- **dodge > crit** — A successful dodge cancels the attack. Crit's
  multiplier is never applied; power investment yields zero return on that
  swing.
- **crit > def** — Crit lands even on blocked parts at the **full rolled
  multiplier**, so def cannot fully cancel an attacker's swing the way
  dodge can. The def hero has no power and no agility, so cannot suppress
  crits (beyond intuition) or roll its own. On top of the damage, a
  blocked crit charges the defender a flat **EP tax**
  (`baseCost × (mult − 1) × critEPCostBonusRatio`) — crits drain def's
  block economy faster, accelerating Exhaustion.
- **def > dodge** — High intuition trims the dodge hero's dodge chance, and
  Endurance lets def absorb the trickle of unblocked hits longer than
  dodge can keep offence going. Without Endurance this edge is the weakest
  of the three; Endurance is the load-bearing piece of the triangle.

---

## Endurance & EP (LEGACY original design plan — implemented & since rebalanced)

> ⚠️ **This is the original design plan, kept as archive.** The system is
> implemented; several values and rules have since changed:
> `startingEP` **2400** (plan said 2000), `blocksPerEndurancePoint` **0.3**
> (plan said 0.5), attacker Strength now burns blocks
> (`blocksLostPerAttackerStrength = 0.1`), blocked crits keep the **full
> multiplier** + pay the EP tax (no `blockedCritMultiplier` damage cap),
> dodge rolls on **all** attacked parts (blocking no longer disables the
> dodge roll), and an Exhausted defender at 0 EP gets a **weak block**
> (0.6 of damage passes) instead of "no protection". See "Current State"
> at the top of this doc for the live rules.

### Goal

Replace "blocks are essentially unlimited" with a **finite resource for
blocking**. Blocking trades EP instead of HP. When EP runs out, blocks no
longer protect — and (later) start damaging the equipment instead.

### Constants & rules

| Rule                          | Value (MVP)                                          |
|-------------------------------|------------------------------------------------------|
| Starting EP                   | **2000** for every hero, every level (see `GameMechanicsConstants.startingEP`) |
| Auto-regen per round          | **None.** EP is restored only via abilities/potions/scrolls. |
| Base block cost — 1H weapon   | 200 EP                                               |
| Base block cost — 2H weapon   | 400 EP                                               |
| Base block cost — shield      | TBD (lower than 1H, likely ≤ 100 EP)                 |
| Endurance effect              | Reduces actual EP paid per block (formula TBD).      |
| Insufficient EP (MVP)         | Whenever `currentEP < cost` (including 0), the block input is accepted but **no protection occurs** — incoming attack resolves as if unblocked (dodge/crit rolls run normally). EP is **not** spent because no successful block happened. |
| Crit on blocked part          | Crit success is preserved (UI marks the hit as a crit, stats record a crit success), but damage is scaled by `GameMechanicsConstants.blockedCritMultiplier` (default `1.0×` = normal-hit damage) instead of the rolled multiplier. EP is still spent for the block. |
| Dodge interaction             | Unchanged. Dodge only runs when the body part is **not** blocked. Choosing to block a part disables that part's dodge roll. |
| Strike order (dual-wield)     | The **right-hand (primary) weapon** strikes first; **left-hand (secondary)** strikes second. EP is drained in this order — the primary's block check happens before the secondary's. If EP runs out between strikes, the secondary's block fails (resolves as undefended). |
| Strike → body-part mapping    | Among the body parts the attacker selected to hit, the i-th in enum order `[head, body, leftHand, rightHand, legs]` is hit by the i-th strike. Strike 0 (primary) → top-most attacked body part; strike 1 (secondary) → next. |

### Endurance → block-cost formula

**Rule.** Each `+1 Endurance` grants `+blocksPerEndurancePoint` effective
blocks, regardless of weapon. At the default `blocksPerEndurancePoint = 0.5`,
that's the canonical **+2 Endurance = +1 effective block** rule. The pool
stays nominally at `startingEP` (currently 2000); Endurance reduces the
EP paid per block such that the extra blocks fit.

**Formula (canonical).**

```
cost = pool / (pool / baseCost + endurance × blocksPerEndurancePoint)
```

**Equivalent implementation — bonus pool** (preferred in code, no
rounding drift):

```
effective_pool = startingEP + (baseCost × endurance × blocksPerEndurancePoint)
cost           = baseCost                  // unchanged
blocks         = floor(effective_pool / baseCost)
```

Both models yield the same block count. Display the *reduced cost* form
to the player (matches their mental model: "Endurance softens incoming
hits"); compute via the bonus-pool form internally.

**Reference tables** (using `startingEP = 2000`).

2H weapon (base 400 EP):

| Endurance | Effective pool | Blocks | Reduced cost |
|-----------|----------------|--------|--------------|
| 0  | 2000 | 5  | 400 |
| 2  | 2400 | 6  | 333 |
| 4  | 2800 | 7  | 286 |
| 6  | 3200 | 8  | 250 |
| 10 | 4000 | 10 | 200 |
| 36 (def lvl 12 max) | 9200 | 23 | 87 |

1H weapon (base 200 EP):

| Endurance | Effective pool | Blocks | Reduced cost |
|-----------|----------------|--------|--------------|
| 0  | 2000 | 10 | 200 |
| 2  | 2200 | 11 | 182 |
| 4  | 2400 | 12 | 167 |
| 10 | 3000 | 15 | 133 |
| 36 (def lvl 12 max) | 5600 | 28 | 71 |

**def style — blocks per level** (planned scaling `+3 × level`, max lvl 12):

| Level | Endurance | 2H blocks | 1H blocks |
|-------|-----------|-----------|-----------|
| 1  | 3  | 6  | 11 |
| 4  | 12 | 11 | 16 |
| 8  | 24 | 17 | 22 |
| 12 | 36 | **23** | **28** |

> **Balance flag.** At lvl 12 max, def hero blocks 23× (2H) or 28× (1H)
> over a battle. Typical fight length is ~10-15 rounds with up to 2 blocks
> per round → 20-30 blocks needed. Def can therefore *cover almost every
> attack with blocks* in a full fight. The triangle counter is the crit
> chance landing on unblocked parts (~28% at lvl 12 — see Triangle
> Snapshot above); on blocked parts the crit is preserved but its damage
> is forced to normal-hit value, so the block still does work.
> Whether this is balanced depends on simulation results;
> **do not add an Endurance cap until a simulator confirms it's needed**.

### Future iterations (not MVP)

- **Equipment durability.** Each item has its own HP. When an attack
  lands on a body part covered by an item (no EP left, or unblocked hit),
  the item loses HP.
- **Equipment states:** `full` → armor + stat bonuses, `damaged` → stat
  bonuses only (armor lost), `broken` → nothing.
- **EP-restoring resources:** abilities, potions, scrolls.
- **Weapon block-cost variants** — heavier/2H weapons may charge more EP
  to defenders that block them, beyond the wielder's own block cost.

---

## File Map

When working on attributes or related combat math, the relevant code is:

| Concern                                   | Location                                                                     |
|-------------------------------------------|------------------------------------------------------------------------------|
| `HeroAttributes`, `Attribute` value type  | `elf_Kit/Sources/DataLayer/Model/Hero/`                                      |
| Per-level fight-style scaling             | `elf_Kit/Sources/DataLayer/Services/Attributes/Implementation/ElfAttributeService.swift` |
| Random per-level scaling (non-style NPCs) | same file, `getRandomLevelAttributes()`                                      |
| `FightStyle` enum                         | `elf_Kit/Sources/DataLayer/Model/Hero/FightStyle.swift`                      |
| Dodge service & distribution              | `elf_Kit/Sources/DataLayer/Services/Dodge/Implementation/`                   |
| Crit service & distribution               | `elf_Kit/Sources/DataLayer/Services/Crit/Implementation/`                    |
| Round resolver (consumes all the above)   | `elf_Kit/Sources/DataLayer/Services/Combat/Implementation/ElfSnapshotCombatCalculator.swift` |
| Combat snapshot (immutable round input)   | `elf_Kit/Sources/DataLayer/Model/Combat/CombatantSnapshot.swift`             |
| Item attribute aggregation                | `ElfAttributeService.getAllItemsAttributes(for:)`                            |
| UI formatting of attributes               | `elf_Kit/Sources/UILayer/Inventory/ItemAttributesFormatter.swift`            |
