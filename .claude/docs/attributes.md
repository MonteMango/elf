# Elfy — Character Attributes

Single source of truth for character attributes, fight styles, and the combat
math that consumes them. Combat resolution flow lives in `game-design.md` —
this doc focuses on the **stats** themselves: what each one does, how each
fight style scales them per level, and how the planned **Endurance / EP**
system fits in.

> **Status legend** — sections marked **(current)** describe shipped
> behaviour. Sections marked **(planned)** describe agreed design that is
> not yet in code. When implementing, prefer reading the source under
> `Packages/elf_Kit/Sources/DataLayer/Services/{Attributes,Crit,Dodge,Combat}`
> over relying on this doc — code wins on conflicts, then update this doc.

---

## Attribute Roster

Attributes are stored on `HeroAttributes` (see
`elf_Kit/Sources/DataLayer/Model/Hero/`) and on `CombatantSnapshot` for
combat. The numeric type is `Attribute` (a typed wrapper, not raw `Int16`)
— see `type-driven-design.md`.

### Core stats (current)

| Attribute       | Role                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **Strength**    | Adds to per-attack damage (rolled via `DamageService`).                  |
| **Agility**     | Dodge chance. *(Also reduces incoming crit multiplier — to be removed.)* |
| **Power**       | Critical-hit chance. Crits pierce blocks.                                |
| **Intuition**   | Suppresses opponent's dodge chance and crit chance.                      |
| **Hit Points**  | Health pool. 0 HP = defeat.                                              |
| **Mana Points** | Resource for abilities (not yet used).                                   |

### Planned stat

| Attribute       | Role                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **Endurance**   | Reduces EP cost paid per successful block (see *Endurance / EP* below). |

Endurance is a **global, equal-rank attribute** — equipment and crystals
can grant it like any other stat. It is not exclusive to the def style.

### Planned simplification

The "Agility reduces enemy crit multiplier" coupling will be removed. Goal:
**one attribute → one role**, so identities don't bleed:

| Attribute   | Role (planned)                       |
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

## Combat Math (current)

Resolution per body part (see `ElfSnapshotCombatCalculator`):

| Situation                | Rolls performed                                                                            |
|--------------------------|--------------------------------------------------------------------------------------------|
| Attacked **and** blocked | Crit roll only. Crit success → block pierced; otherwise → blocked.                         |
| Attacked, **not** blocked| Dodge roll first. If dodged → done. Otherwise crit roll → crit hit or normal hit.          |
| Not attacked             | Nothing.                                                                                   |

Both **dodge** and **crit** use the same two-stage triangular-distribution
pattern:

1. **Stage 1** — pick a chance value from a triangular distribution
   (low values weighted highest). Inputs:
   - Dodge: `defender.agility` vs `attacker.intuition`
   - Crit:  `attacker.power` vs `defender.intuition`
2. **Stage 2** — roll `1...100`, succeed if `roll ≤ chance`. Auto-fail at
   `chance ≤ 0`, auto-success at `chance ≥ 100`.

Crit then runs a **Stage 3** to pick a damage multiplier from a
distribution that is currently shifted down by `defender.agility`. This
agility-coupling is the part flagged for removal above.

**Distribution peaks** — see `GameMechanicsConstants`:

| Distribution | `peakPosition` | Effect |
|---|---|---|
| Dodge | `0.4` | Peak slightly below the middle of `[stat-instinct, stat]` |
| Crit  | `0.2` | Peak much closer to the minimum (instinct hits crit harder) |

**Crit multiplier distribution** — values `[0.75, 1.00, 1.25, 1.50, 2.00, 3.00]`,
weights `[0, 5, 15, 40, 30, 10]` → `E[multiplier | crit] = 1.74×`. So a
successful crit adds **+0.74×** of base damage on average.

**Important nuance** — when `instinct == 0` on the opponent side, the
distribution range collapses to a single value equal to the actor's stat.
So with no instinct, **1 agility = exactly 1% dodge** and **1 power =
exactly 1% crit**. Once instinct opens the range, the tent peak pulls the
expected chance well below the stat value (see *Per-Point Value* below).

Implementations:
- `ElfDodgeService.calculateDodge(agility:instinct:)`
- `ElfCritService.calculateCrit(power:instinct:defenderAgility:)`
- `ElfSnapshotCombatCalculator.calculatePointStatus(...)`

---

## Per-Point Value

Empirical coefficients derived from the actual code (distribution
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

### Strength → mean damage (per attack)

From `ElfStrengthDamageDistributionStrategy.predefinedDistributions`:

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

**1 endurance = +0.5 effective blocks** (universal across weapons by the
rule). For a typical-damage hit at lvl 12 (~5-10 base damage), one block
saves roughly that much HP, so **1 endurance ≈ 2.5-5 HP saved per
battle** — but only for a hero who actually allocates block points.

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

Effective triangle probabilities (mean of stage-1 distribution rolled
against stage-2):

| Edge | Mechanism | Effective rate |
|------|-----------|----------------|
| **dodge > crit** | dodge defender (agility 48) vs crit's intuition 12; range 36-48 peak 41 | **~41% dodge** |
| **crit > def**   | crit attacker (power 48) vs def's intuition 24; range 24-48 peak 29 | **~29% crit pierces blocks** |
| **def > dodge**  | dodge attacker (agility 48) vs def's intuition 24; range 24-48 peak 34 | **~34% dodge** (down from 41% baseline) |

This puts the natural triangle **close to the 60/30/10 design target** at
max level without any further tuning of distributions. Confirmation
requires win-rate simulation — see Open Balance Flags.

---

## Open Balance Flags

Things known or suspected to be off. Resolve via simulation, not
intuition.

1. **Triangle win-rates not yet measured.** The per-edge probabilities
   above are *individual rolls*, not *match outcomes*. A 60/30/10
   match-outcome target requires running ~10k auto-battles per pair of
   styles via `BattleRoundRunner`. Until that data exists, every other
   flag in this list is a guess.
2. **Endurance cap?** Linear scaling tops out at 36 endurance (lvl 12
   def), giving 24 (2H) or 30 (1H) blocks in a fight. That covers nearly
   every attack of a typical 10-15 round battle. **Do not cap until
   simulation shows the def style winning more than 60% vs dodge or
   draws are too frequent.**
3. **Crit-style strength may be undertuned.** With +1 strength/level,
   max strength 12 ≈ +1.6 damage/attack. Crit-style DPS leans heavily on
   the crit multiplier; against a high-intuition def (intuition 24, crit
   chance ~29%) the multiplier proc is rare. Possible swap: `+2 str / +3
   power` per level. Test only after triangle simulation.
4. **Agility/power asymmetry from peak positions.** Dodge peak `0.4` vs
   crit peak `0.2` makes the same numeric stat ~25% more effective on
   the dodge side. This is intentional asymmetry, but if the simulator
   shows dodge dominating crit by far more than the design's 60/30/10,
   moving both peaks to `0.3` is the simplest lever.
5. **Linear scaling assumed safe at lvl 12.** Max stat from levelling
   is 48 (crit power, dodge agility), so the 100% auto-success cap is
   not reachable through levels alone. Equipment can push past this and
   needs to be balanced separately.

### Per-level scaling

#### Current (in code)

| Style    | strength | agility | power   | intuition | endurance | hit points |
|----------|----------|---------|---------|-----------|-----------|------------|
| `crit`   | +1×lvl   | 0       | +4×lvl  | +1×lvl    | —         | 80 (flat)  |
| `dodge`  | +1×lvl   | +4×lvl  | 0       | +1×lvl    | —         | 80 (flat)  |
| `def`    | +2×lvl   | 0       | 0       | +2×lvl    | —         | 80 + 2×lvl |

#### Planned (with Endurance, no def-HP bonus)

| Style    | strength | agility | power   | intuition | endurance | hit points |
|----------|----------|---------|---------|-----------|-----------|------------|
| `crit`   | +1×lvl   | 0       | +4×lvl  | +1×lvl    | 0         | 80 (flat)  |
| `dodge`  | +1×lvl   | +4×lvl  | 0       | +1×lvl    | 0         | 80 (flat)  |
| `def`    | +1×lvl   | 0       | 0       | +2×lvl    | +3×lvl    | 80 (flat)  |

Notes on the planned table:
- def loses its passive HP bonus and `+1` strength (was `+2`). Its identity
  shifts from "fat HP bar" to "tactical staying power" via Endurance.
- The numbers are an opening proposal; expected to be tuned during balancing.

---

## Style Triangle: `def > dodge > crit > def`

A soft rock-paper-scissors. The intent is **slight** advantage (~60 / 10 /
30), not auto-win. Each edge is grounded in mechanics, not magic numbers:

- **dodge > crit** — A successful dodge cancels the attack. Crit's
  multiplier is never applied; power investment yields zero return on that
  swing.
- **crit > def** — Crit pierces the block. The def hero has no power and no
  agility, so cannot suppress crits or shrink them. EP also drains on
  crit-pierced blocks (see below), penalising tanks twice.
- **def > dodge** — High intuition trims the dodge hero's dodge chance, and
  Endurance lets def absorb the trickle of unblocked hits longer than
  dodge can keep offence going. Without Endurance this edge is the weakest
  of the three; Endurance is the load-bearing piece of the triangle.

---

## Endurance & EP (planned)

### Goal

Replace "blocks are essentially unlimited" with a **finite resource for
blocking**. Blocking trades EP instead of HP. When EP runs out, blocks no
longer protect — and (later) start damaging the equipment instead.

### Constants & rules

| Rule                          | Value (MVP)                                          |
|-------------------------------|------------------------------------------------------|
| Starting EP                   | **2500** for every hero, every level                 |
| Auto-regen per round          | **None.** EP is restored only via abilities/potions/scrolls. |
| Base block cost — 1H weapon   | 200 EP                                               |
| Base block cost — 2H weapon   | 400 EP                                               |
| Base block cost — shield      | TBD (lower than 1H, likely ≤ 100 EP)                 |
| Endurance effect              | Reduces actual EP paid per block (formula TBD).      |
| Block at 0 EP (MVP)           | Block input is accepted, but **no protection occurs** — incoming attack resolves as if unblocked (dodge/crit rolls run normally). |
| Crit pierces block            | Damage applies **and** EP is still spent. Tanks pay twice — this is the crit-vs-def edge of the triangle. |
| Dodge interaction             | Unchanged. Dodge only runs when the body part is **not** blocked. Choosing to block a part disables that part's dodge roll. |

### Endurance → block-cost formula

**Rule.** Every **+2 Endurance grants +1 effective block**, regardless of
weapon. The pool stays nominally at 2500; Endurance reduces the EP paid
per block such that one extra block fits.

**Formula (canonical).**

```
cost = pool / (pool / baseCost + endurance / 2)
```

**Equivalent implementation — bonus pool** (preferred in code, no
rounding drift):

```
effective_pool = 2500 + (baseCost × endurance / 2)
cost           = baseCost                  // unchanged
blocks         = floor(effective_pool / baseCost)
```

Both models yield the same block count. Display the *reduced cost* form
to the player (matches their mental model: "Endurance softens incoming
hits"); compute via the bonus-pool form internally.

**Reference tables.**

2H weapon (base 400 EP):

| Endurance | Effective pool | Blocks | Reduced cost |
|-----------|----------------|--------|--------------|
| 0  | 2500 | 6  | 400 |
| 2  | 2900 | 7  | 357 |
| 4  | 3300 | 8  | 312 |
| 6  | 3700 | 9  | 277 |
| 10 | 4500 | 11 | 227 |
| 36 (def lvl 12 max) | 9700 | 24 | 137 |

1H weapon (base 200 EP):

| Endurance | Effective pool | Blocks | Reduced cost |
|-----------|----------------|--------|--------------|
| 0  | 2500 | 12 | 200 |
| 2  | 2700 | 13 | 185 |
| 4  | 2900 | 14 | 172 |
| 10 | 3500 | 17 | 143 |
| 36 (def lvl 12 max) | 6100 | 30 | 81 |

**def style — blocks per level** (planned scaling `+3 × level`, max lvl 12):

| Level | Endurance | 2H blocks | 1H blocks |
|-------|-----------|-----------|-----------|
| 1  | 3  | 7  | 13 |
| 4  | 12 | 10 | 17 |
| 8  | 24 | 17 | 24 |
| 12 | 36 | **24** | **30** |

> **Balance flag.** At lvl 12 max, def hero blocks 24× (2H) or 30× (1H)
> over a battle. Typical fight length is ~10-15 rounds with up to 2 blocks
> per round → 20-30 blocks needed. Def can therefore *cover almost every
> attack with blocks* in a full fight. The triangle counter is crit
> piercing blocks (~29% pierce rate at lvl 12, see Triangle Snapshot
> below). Whether this is balanced depends on simulation results;
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
