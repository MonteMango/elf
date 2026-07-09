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

> **Legacy archive:** the pre-Session-2 combat math, the Round-39 win-rate
> sweeps, the per-point-value tables and the original EP design plan were
> moved to
> [`game-balance/attributes-legacy-archive.md`](game-balance/attributes-legacy-archive.md)
> (2026-07-09) to keep this doc focused on live behaviour. That archive is
> historical reference only — superseded values, do not tune against them.

---

## Current State (Session 2 — as of 2026-06-01)

This section describes shipped behaviour and is the live source of truth.
The pre-Session-2 combat math, "Secondary attribute mechanics" and the
hand-tuned distribution tables it replaced now live in
[`game-balance/attributes-legacy-archive.md`](game-balance/attributes-legacy-archive.md)
as historical reference — they were **superseded by the Session 2 refactors
documented here**.

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

**Crit multiplier scope.** On a crit the multiplier scales **only the weapon
component** (`attackDamage`), not the whole hit:
`final = max(0, round(attackDamage × mult) + strengthDamage − intReduction −
endReduction − armor)`. `strengthDamage`, the reductions and armour are all
applied flat, un-multiplied. (See `resolveWeakBlock` / `logBodyPartResult`
in `ElfSnapshotCombatCalculator+Resolvers.swift`.)

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
`elf_Kit/Sources/DataLayer/Model/RuntimeDomain/Hero/`) and on
`CombatantSnapshot` for combat. The numeric type is `Attribute` (a typed
wrapper, not raw `Int16`) — see `type-driven-design.md`.

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

## File Map

When working on attributes or related combat math, the relevant code is:

| Concern                                   | Location                                                                     |
|-------------------------------------------|------------------------------------------------------------------------------|
| `HeroAttributes` model                    | `elf_Kit/Sources/DataLayer/Model/RuntimeDomain/Hero/HeroAttributes.swift`   |
| `Attribute` value type                    | `elf_Kit/Sources/DataLayer/Model/ValueTypes/Attribute.swift`                |
| Per-level fight-style scaling             | `elf_Kit/Sources/DataLayer/Services/Attributes/Implementation/ElfAttributeService.swift` |
| Random per-level scaling (`+4` pool)      | same file, `getRandomLevelAttributes()`; roll source `Implementation/ElfAttributeRandomizer.swift` (`nextAttribute()`) |
| `FightStyle` enum                         | `elf_Kit/Sources/DataLayer/Model/RuntimeDomain/Hero/FightStyle.swift`        |
| Strength damage (`sqrt(str)×0.6`)         | `elf_Kit/Sources/DataLayer/Services/Damage/Implementation/ElfStrengthDamageDistributionStrategy.swift` (+ shared `Services/Damage/SqrtCurveDistribution.swift`) |
| Damage reduction (`sqrt(int)×0.12`, `sqrt(end)×0.18`) | `elf_Kit/Sources/DataLayer/Services/Damage/Implementation/ElfDamageReductionDistributionStrategy.swift`; consumed via `Services/Damage/Implementation/ElfDamageService.swift` |
| Block cost (Endurance/EP economy)         | `elf_Kit/Sources/DataLayer/Services/Endurance/Implementation/ElfEnduranceService.swift` (`calculateBlockCost`) |
| Dodge service & distribution              | `elf_Kit/Sources/DataLayer/Services/Dodge/Implementation/`                   |
| Crit service & distribution               | `elf_Kit/Sources/DataLayer/Services/Crit/Implementation/`                    |
| Dodge/crit chance shape (peak+linear-tail)| `elf_Kit/Sources/DataLayer/Services/Combat/PeakLinearTailDistribution.swift` |
| Round resolver (consumes all the above)   | `elf_Kit/Sources/DataLayer/Services/Combat/Implementation/ElfSnapshotCombatCalculator.swift` (+ `…+Resolvers.swift`) |
| Combat snapshot (immutable round input)   | `elf_Kit/Sources/DataLayer/Model/Combat/Combat/CombatantSnapshot.swift`     |
| Item attribute aggregation                | `ElfAttributeService.getAllItemsAttributes(for:)`                            |
| UI formatting of attributes               | `elf_Kit/Sources/UILayer/Inventory/ItemAttributesFormatter.swift`            |
