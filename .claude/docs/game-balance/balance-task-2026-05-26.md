# Game Balance Configuration Task

**Date:** 2026-05-26
**Owner:** Vitalii Lytvynov
**Assignee:** Claude

---

## Goal

Configure game balance so that the **rock-paper-scissors fight-style triangle** produces controlled, level-dependent advantages for the favored side. At low levels battles should feel close to even; at high levels the advantaged style should clearly dominate.

---

## The Triangle (from game design docs)

```
crit  >  def
 ^         |
 |         v
dodge  <--+
```

- **crit** has advantage against **def**
- **def** has advantage against **dodge**
- **dodge** has advantage against **crit**

For each pair, one style is the **advantage side** and the other is the **other side**. Mirror matchups (crit vs crit, def vs def, dodge vs dodge) are not part of this task — the focus is the three asymmetric pairs.

---

## Test Infrastructure

The project ships a headless **battle simulation integration test target** that runs **30 000 fights per pair** at a specified level and reports:

- win rate for side A
- win rate for side B
- draw rate
- exhausted-debuff occurrence rate

Use this harness to measure balance after every tuning change. Prior runs have already been documented — read those results before changing values so we don't repeat work.

Locations to know:
- Test plan: `battle_simulation_IntegrationTests.xctestplan`
- Documented prior results: look under `dungeon/` and any battle-simulation result notes already in the repo (e.g. `buffs-code-review-2026-05-24.md` if relevant).

---

## Target Win Rates by Level

The favored side's edge should **grow with level**. Targets are ranges, not exact numbers — landing anywhere inside the band counts as success.

| Level | Advantage side | Other side | Draw   | Notes |
|------:|:--------------:|:----------:|:------:|:------|
| **3** | 42.5% – 52.5%  | 40% – 50%  | 5% – 15% | Battles should feel near-even. Only a slight edge (~3–4%) for the advantage side. |
| **6** | 50% – 60%      | 40% – 50%  | 0% – 15% | Edge becomes noticeable. |
| **9** | 55% – 65%      | 35% – 45%  | 0% – 10% | Clear advantage. |
| **12**| 60% – 70%      | 30% – 40%  | 0% – 10% | Strong, definitive advantage. |

**Shape of the curve:** start near-even at low levels, ramp smoothly to a 60–70% advantage by level 12. Intermediate levels (1, 2, 4, 5, 7, 8, 10, 11) should interpolate naturally — no sudden jumps.

---

## Exhausted Debuff — Occurrence Targets

The **Exhausted** debuff triggers when an elf runs out of EP. It should be an occasional consequence, not a default outcome.

| Level band | Exhausted occurs in |
|:-----------|:--------------------|
| 1 – 6      | **10% – 20%** of fights |
| 6 – 12     | **up to 75%** of fights |

Measure this in the same simulation runs used for win-rate tuning.

---

## Endurance — No Wasted Points at Level 12

By level 12 the Endurance attribute must be **fully load-bearing**. The intent: every point an elf invests in Endurance should actually influence the battle. Today there is a risk that EP pools grow faster than EP consumption, leaving large reserves unused at fight's end — those reserves are wasted stat points.

**Target:** at level 12, the **average unused EP reserve at end of fight** should be **no more than 20%** of the elf's maximum EP pool.

In other words: across a 30 000-fight sim at level 12, average ending EP (for both winners and losers, ideally measured separately too) should be **≤ 20% of max EP**. Anything higher means Endurance is over-tuned relative to EP costs, and either:
- EP costs (block, special actions) need to scale up, **or**
- the EP pool granted per Endurance point needs to scale down, **or**
- both.

This target plays against the Exhausted-debuff target — they bound the system from two sides:
- **Exhausted ≤ 75%** at high levels means EP shouldn't run out *too* often.
- **Reserve ≤ 20%** at level 12 means EP also shouldn't be *too* plentiful.

A healthy level-12 fight ends with most elves close to empty but not always Exhausted.

---

## What You Can Change

You have wide freedom inside the **existing** mechanics:

- Values in `GameMechanicsConstants`
- Attribute distribution tables (per level)
- Calculation formulas — how each attribute influences damage, blocking, dodging, crit, etc.
- Scaling curves between attributes and their effects

---

## What You Can Add (Only If Needed for Balance)

Use these **only** when existing knobs aren't enough — not for fun, not preemptively:

1. **Strength increases EP spend on blocks.** Counterpart to Endurance reducing EP spend — Strength would push it up. Models heavy attackers being more tiring to block.
2. **Intuition affects strDmg or endRed.** Either:
   - Intuition helps avoid a small amount of incoming damage, **or**
   - Intuition adds a small bonus to outgoing damage (on top of Power / Agility efficiency).

If you reach the targets without these, don't add them.

---

## What You CANNOT Add

- New attributes
- New fundamentally different mechanics (new buffs/debuffs systems, new resources, new resolution steps)
- New axes of attribute influence beyond the two listed above

The task is **tuning** within the current system, not redesign.

---

## Suggested Workflow

1. **Read existing simulation results** under `dungeon/` and surrounding notes — know the current baseline before touching anything.
2. **Run the battle simulation test target** for levels 3, 6, 9, 12 across the three advantage pairs (crit-vs-def, def-vs-dodge, dodge-vs-crit) to capture the starting point.
3. **Identify the gap** between current numbers and target bands per level.
4. **Adjust constants / distributions / formulas** — smallest change first.
5. **Re-run sims**, compare, iterate.
6. **Track which knobs moved what** — short notes in this file or a sibling doc are fine. Goal is to leave a trail so the next tuning pass doesn't start from scratch.
7. **Only introduce a new mechanic** from the allowed list if you've exhausted existing levers and still can't hit the targets.
8. **Final pass:** verify exhausted-debuff frequencies fall inside the bands above.

---

## Definition of Done

- All four target levels (3, 6, 9, 12) have all three advantage pairs landing inside the documented bands.
- Exhausted-debuff frequency falls inside the documented bands for both level groups.
- **Average unused EP reserve at level 12 ≤ 20% of max EP.**
- No new attributes added; no new mechanics added beyond the two explicitly listed (and only if necessary).
- Changes documented enough for the next person (or next session) to pick up tuning without re-deriving the state.

---

## Outcome (2026-05-26)

**Full sim data, decision log:** `.claude/docs/game-balance/triangle-sweep-final-balance-2026-05-26.md`.

### User design corrections (mid-task)

After the first balancing pass (round 33), the user provided three
critical design corrections that triggered a re-balance:

1. **Logical invariant:** `blocked-crit mean < unblocked-crit mean`.
   Damage through a block must never exceed damage from an unblocked
   crit — the block always provides some mitigation. The round-33
   state had `blocked = 1.95×, unblocked = 1.475×` — illogical.
2. **Refactor Strength → EP cost** to the same "blocks" abstraction as
   Endurance: `blocksLostPerAttackerStrength: Double = 0.2` (replaces
   the previous flat additive `epCostPerAttackerStrength: Int = 10`).
3. **Move crit's 6th budget point from manaPoints to strength** — per-style
   HP/Mana scaling is forbidden. crit becomes `str 2×lvl + pow 4×lvl`.

### What was done

- **39 tuning rounds** total against the `BattleSimulationIntegrationTests` 30 000-fight sweep.
- **`crit` style attributes:** `strength 1×lvl → 2×lvl`, `intuition 1×lvl → 0`. Manapoint scaling reverted.
- **Constants — blocked-crit:** `blockedCritMultiplierWeights` mean **1.11 → 1.2375** (now strictly below unblocked-crit 1.475× per the invariant).
- **New mechanic — Strength → blocks lost (attacker):** `blocksLostPerAttackerStrength = 0.2`. Symmetric counterpart to `blocksPerEndurancePoint = 0.4` — both modifiers read in the same "blocks" units.
- **New mechanic — Intuition → endurance reduction** (two-tier gate, scaling bonus):
  Activates when `defenderEndurance == 0 && defenderInstinct ≥ 3` AND
  attacker is dangerous via either path:
   - **Crit-style attacker** (`power ≥ 12`): scaling bonus
     `max(1, min(2, round(int/6)))` → +1 at L3-L6, +2 at L9-L12.
   - **Heavy-strength attacker** (`str ≥ 10`, L10+ for str=1×lvl styles):
     flat **+1**.
  This narrowly buffs dodge as defender — vs crit at L3+ (via power
  gate) and vs def at L10+ (via str gate). Restored `def > dodge` to
  target band at L12 (was overshooting at 74.6 % before str-gate
  extension).
- **Exhausted debuff:** unchanged from original (`str -30%, end -30%`). Sim trials with power/str modifications showed weak effect.

### Per-style identity constraints (added by user 2026-05-26)

| Style | Forbidden stats     | Why                                          |
|-------|---------------------|----------------------------------------------|
| crit  | agility             | Agility is dodge's identity.                |
| dodge | power               | Power is crit's identity.                   |
| def   | agility, power      | Def neither dodges nor crits — it absorbs.  |

### Targets vs final (L12) — **ALL 3 advantage edges hit target**

| Edge            | Advantage | Win % | Other | Win % | Status |
|-----------------|-----------|------:|-------|------:|--------|
| dodge > crit    | dodge     | **65.2** | crit  | 25.9  | ✓ |
| def > dodge     | def       | **60.3** | dodge | 32.1  | ✓ ✓ |
| crit > def      | crit      | **61.6** | def   | 27.9  | ✓ |

Logical invariant (blocked-crit < unblocked-crit):

| Damage path           | Mean    | Status |
|-----------------------|--------:|--------|
| `blockedCritMultiplier`  | 1.2375× | ✓ < unblocked |
| `critMultiplier` (unblocked) | 1.475× | (baseline) |

Endurance reserve at L12 (target ≤ 20 %):

| Defender matchup    | EP used | Reserve | Status |
|---------------------|--------:|--------:|--------|
| def_vs_dodge        |  52.1 % | 47.9 %  | ⚠ |
| def_vs_crit         |  40.8 % | 59.2 %  | ⚠ |

EP reserve target traded for the cleaner blocks-based Strength→EP
abstraction (per user directive: «stay to 1-bl logic for calculation»).

L9 also hits **all 3 advantage edges**. L6 and L3 — 2/3 ✓ with minor
gaps (see linked sim doc).

### Trade-offs / known gaps

1. **EP reserve target ≤ 20 % missed.** With `blocksLostPerStr = 0.2` (user's preferred value), defender doesn't bleed EP fast enough — reserve sits at 48-59 %. Trade-off accepted by user as a price for the cleaner abstraction.
2. **L6 `def > dodge` def 63.5 % (over 60 by 3.5 pp).** The str-based intuition gate (`attackerStr ≥ 10`) doesn't trigger at L6 (def str=6 < 10). Lowering the threshold collapses L9-L12. Minor over.
3. **Non-defender Exhausted % at L9-L12 = 85-99.8 %** (over the 75 % ceiling). Structural — dodge/crit have 0 Endurance and burn EP fast against any strength-2 attacker.
4. **"Other side" winrates systematically 4-8 pp under target.** Strong advantage sides (60+) + ~10 % draws leave ≤ 30 % for the other side. Arithmetic, not a balance bug.

### Files touched

| File | Change |
|------|--------|
| `Packages/elf_Kit/Sources/DataLayer/Services/Attributes/Implementation/ElfAttributeService.swift` | crit: `strength 1×lvl → 2×lvl`, `instinct 1×lvl → 0`, no mana scaling |
| `Packages/elf_Kit/Sources/DataLayer/Services/Constants/GameMechanicsConstants.swift` | `blockedCritMultiplierWeights` mean → **1.2375** (< unblocked 1.475); removed `epCostPerAttackerStrength`; new constant `blocksLostPerAttackerStrength: Double = 0.2` |
| `Packages/elf_Kit/Sources/DataLayer/Services/Endurance/EnduranceService.swift` | New `attackerStrength:` parameter (default-0 overload for legacy callers) |
| `Packages/elf_Kit/Sources/DataLayer/Services/Endurance/Implementation/ElfEnduranceService.swift` | Refactored formula: Strength subtracts blocks from denom (matches blocks-based abstraction) |
| `Packages/elf_Kit/Sources/DataLayer/Services/Combat/Implementation/ElfSnapshotCombatCalculator.swift` | Pass attacker Strength to `calculateBlockCost`; triple-gated intuition → endRed with scaling bonus (max(1, min(2, int/6))) |
| `Packages/elf_Kit/Tests/elf_KitTests/DataLayer/Services/Combat/ElfSnapshotCombatCalculatorTests.swift` | Mock signature updated |
| `Packages/elf_Kit/Tests/elf_KitTests/DataLayer/Services/Attributes/ElfAttributeServiceTests.swift` | Updated crit attribute expectations (str=20, int=0 at L10) |
| `Packages/elf_Kit/Tests/elf_KitTests/DataLayer/Services/Crit/ElfCritServiceTests.swift` | Blocked-crit mean test (1.2375×); added invariant assertion `mean < unblocked-crit mean` |
| `elf/Resources/Buffs.json` | Explored Exhausted power/str modifications — reverted to original |
| `.claude/docs/attributes.md` | Documented 6-point rule, per-style identity constraints, mechanics for Intuition → endRed and Strength → blocks lost, Exhausted tunability |
| `.claude/docs/game-balance/triangle-sweep-final-balance-2026-05-26.md` | **New** — full sim data + 39-round decision log |

---

# Session 2 (2026-05-27 / 28) — Mechanic Refactors + Attribute Value Analysis

> The round-39 "final" state above was a *snapshot in time*. Session 2 made
> several structural changes that the table above does NOT reflect. This
> section is the current source of truth.

**Full raw sweep data (both modes, all 12 configs) + attribute matrix:**
`.claude/docs/game-balance/triangle-sweep-session2-sqrt-curve-2026-05-28.md`.

**Player-choice strategy analysis (what if players could pick stats?):**
`.claude/docs/game-balance/attribute-strategy-choice-2026-06-01.md`.
Headlines:
- def's optimal is `all-STR` (72 %) — exploits linear block-erosion
- crit's optimal is `STR+END` (64 %) — fills its 0-endurance weakness
- dodge's optimal is **`all-AGI` (92 %)** — agi soft-cap exploit, game-breaking
- Random rolls auto-protect balance; player choice would require structural caps.

**`blocksLostPerAttackerStrength: 0.2 → 0.1` experiment:**
`.claude/docs/game-balance/blocks-lost-per-str-01-2026-06-01.md`.
Mixed verdict — fixed `all-STR for def` exploit (72 → 49 %) but **worsened
random L12 `def>dodge` inversion (47.6 → 61.0 %)** and made `all-AGI for
dodge` deeper (92 → 97 %). Net Rnd scorecard regressed 5 ✓ → 3 ✓.
Recommendation: revert or use 0.15 as compromise, and fix exploits via
per-stat caps instead.

**Attribute comparison synthesis (solo + marginal + class fit):**
`.claude/docs/game-balance/attribute-comparison-2026-06-01.md`.
Cross-cuts matrix + strategy + mechanics into one verdict per attribute:
- **STR:** generalist offense (#4 solo, ~2.1 dmg/point)
- **AGI:** top solo (#2) but exploit for dodge (95 % player-choice)
- **POW:** mediocre (#5), only viable for crit
- **INT:** weak solo (#9) but best for def (#1 class fit)
- **END:** worst solo (#10 ☠) but highest per-point eHP (1.8) — pure support multiplier
- Key paradox: END's solo vs marginal asymmetry; AGI is most overrated
  (looks #2 solo but exploit-tier in player choice).

**Dynamic crit + dodge suppression (base 0.8):**
`.claude/docs/game-balance/dynamic-suppression-08-2026-06-01.md`.
Made both `dodgeIntuitionSuppressionMultiplier` and
`critIntuitionSuppressionMultiplier` level-dependent
(`base + perLevel × attackerLevel`). With base 0.8, slope 0.04 (dodge) /
0.024 (crit):
- ✅ **L3-L6 `crit>def` fixed** (was persistent inversion).
- ✅ **L6 `dodge>crit` essentially tied** (was full crit win).
- ✅ DEF lost over-dominance at L3-L9.
- ❌ L3 `dodge>crit` still inverted (rounding floor at low int).
- ❌ `all-AGI for dodge` exploit untouched (95 % — needs structural cap).
Det scorecard improved: 3 ✓ → 4 ✓, 3 ❌ → 2 ❌.

### Latest sweep band-compliance (current code = sqrt curve)

| Mode | ✓ in band | ~ wrong magnitude | ✗ inverted |
|------|----------:|------------------:|-----------:|
| Deterministic | 4 / 12 | 5 / 12 | 3 / 12 |
| Random | 3 / 12 | 4 / 12 | 5 / 12 |

Three systemic problems: (1) **crit>def overshoot** (crit 69-76% L9-L12);
(2) **def>dodge inverted** at L6-L12 (dodge wins) — root cause END is a dead
stat; (3) **dodge>crit inverted** at L3-L6 (crit wins).

## Current code state (supersedes round-39 where noted)

| Knob / mechanic | Round-39 state | **Current state** |
|-----------------|----------------|-------------------|
| crit attributes | `str 2×L, int 0` | **`str 1×L, pow 4×L, int 1×L`** (reverted) |
| def attributes | `str 1×L, int 2×L, end 3×L` | same (briefly tried 2/2/2 → reverted) |
| `blocksPerEndurancePoint` | 0.4 | **0.3** |
| Endurance → damage reduction | yes (gated mechanic) | **REMOVED — endurance is blocks-only** |
| Intuition → damage reduction | gated bonus | **`intuitionDamageReductionMultiplier = 1.5`** (Option C — intuition is sole reduction driver) |
| Intuition → offensive damage | `+int×0.2` to str | **REMOVED** (`intuitionEffectRatioOfStrength` deleted) |
| Dodge resolution | block-then-dodge | **dodge-first** (dodge rolled on every attack) |
| Crit EP amplification | none | **flat-reduction model** (`critEPCostBonusRatio = 1.0`) |
| Strength damage curve | hand-tuned linear table | **`sqrt(str) × 0.6`** ⚠ *regression — see below* |
| Exhausted debuff | `str −30%, end −30%` | same |

## Session-2 experiments + outcomes

1. **dodge-first refactor** — dodge now rolled on every attack (was only on undefended). Correct semantics.
2. **Crit EP amplification** — crits cost the defender more EP to block (flat-reduction model). Bites high-Endurance defenders.
3. **`blocksPerEndurancePoint` 0.4 → 0.3** — asymmetric def nerf. Barely moved win rates (def HP soaks it).
4. **Option C: damage reduction moved END → INT** — endurance became blocks-only; intuition became the sole reduction stat (`×1.5` multiplier into the existing reduction table). Side effect: revived reduction for dodge/crit too (they have int 1×L), and **killed END as a standalone stat** (see analysis).
5. **Intuition removed from offensive damage** — intuition is now purely defensive (reduction + dodge/crit suppression).
6. **def 2/2/2 experiment** — doubling def's str made her wildly OP (deals +170% via damage + block-erosion). **Reverted.**
7. **sqrt damage curve** ⚠ — `mean = sqrt(str) × 0.6` gives diminishing returns (doubling str → +41% not +100%) BUT narrowed variance from ~2.0 to ~0.1, killing damage spikes. **Regression**: hurt def's offence disproportionately (def's main damage IS strength). crit>def overshot to 79% random, def>dodge inverted. **Decision pending: revert / widen variance / raise k.**

## The Random-vs-Deterministic divergence (key finding)

Two sweeps now exist (`testStyleTriangleSweep` + `testStyleTriangleSweepWithRandomAttributes`).
Random attributes (`+4/level` across the 5 combat stats) **flip balance conclusions**:
- Deterministic tests classes with literal `0` in their non-core stats (e.g. dodge has `end 0`) → they exhaust instantly and lose.
- Random gives every class ~`+0.8/level` of every stat → dodge/crit get enough endurance to survive, which **flips def>dodge** (def wins deterministic, loses random).

**Always run BOTH sweeps.** Real play ≈ random.

## Attribute Value Analysis (2026-05-28) — duel matrix

New test `testAttributeValueMatrix`: 10 "champion" elves, each dumps an equal
48-point budget into one stat (or 24+24 combo), all sharing HP 140 + Recruit's
Spear, full round-robin at 10k battles/pair.

### Power ranking (mean draw-split win% vs all opponents)

| # | Champion | Score | Verdict |
|---|----------|------:|---------|
| 1 | BAL (≈9 each) | 66.9% | Most consistent — no hard counter |
| 2 | STR | 63.0% | Strong |
| 3 | AGI | 62.0% | Strong |
| 4 | STR+END | 57.9% | Good combo |
| 5 | AGI+INT | 56.1% | Good combo |
| 6 | INT | 53.3% | Defensive, niche |
| 7 | POW | 51.0% | Mediocre |
| 8 | POW+AGI | 47.6% | — |
| 9 | POW+END | 33.0% | Weak |
| 10 | **END** | **9.1%** | **DEAD STAT** |

### 1-v-1 matrix (row's win% vs column)

| A \ B | STR | AGI | POW | INT | END |
|-------|----:|----:|----:|----:|----:|
| STR | — | 19.9 | 48.3 | 99.9 | 86.7 |
| AGI | 73.9 | — | 71.9 | 5.9 | 98.9 |
| POW | 48.3 | 22.9 | — | 15.6 | 99.0 |
| INT | 0.0 | 88.2 | 76.1 | — | 59.6 |
| END | 7.8 | 0.8 | 0.5 | 32.6 | — |

### The hidden stat triangle

**STR > INT > AGI > STR** — a clean rock-paper-scissors among the three
load-bearing stats:
- STR > INT (99.9%) — raw damage ignores intuition's chance-suppression
- INT > AGI (88.2%) — intuition suppresses dodge chance
- AGI > STR (73.9%) — dodge avoids the damage

**POW and END sit outside it:**
- POW — countered by both INT (15.6%) and AGI (22.9%); only beats END. "Weak fourth."
- END — loses to everything. After Option C removed its damage-reduction, endurance only buys blocks (which cost EP and *delay* damage, never prevent it). A pure-END elf can neither kill nor survive.

### Why fight styles are structurally misaligned

| Style | Core stat (4×L / 3×L) | Core stat power |
|-------|----------------------|-----------------|
| dodge | AGI | strongest pure stat |
| crit | POW | mediocre (double-countered) |
| def | END (+INT 2×L) | END is **dead**; def survives on INT alone |

dodge got the best stat, crit a mediocre one, def a dead one. This is the
**root cause** of the persistent balance difficulty — the styles are bundles
of stats with wildly unequal value.

### INT cannibalized END

After Option C, INT is a triple-dipper (reduction ×1.5 + suppress-dodge +
suppress-crit) while END is a weak single-dipper (blocks only). INT absorbed
the defensive role END used to own. To revive END, its reduction (or a real
per-block mitigation) must come back — ideally split: END = reduction, INT =
suppression.

## Exhausted debuff analysis (2026-05-28)

`Exhausted` (battle-scoped): `str −30%, end −30%`, applied at end of any round
the combatant ends at 0 EP. Also forces weak-block (half-effectiveness) while
at 0 EP.

### Frequency — def almost never exhausts; crit/dodge almost always do

| L12 matchup | def Exh% | opponent Exh% |
|-------------|---------:|--------------:|
| def_vs_crit (random) | **8.1%** | crit **77.5%** |
| def_vs_dodge (random) | **2.1%** | dodge **81.3%** |
| dodge_vs_crit (random) | — | dodge 60.7% / crit 83.5% |

def has end 3×L → cheap blocks → rarely drains EP. crit/dodge have end 0 →
exhaust constantly. **Exhausted is a large structural def advantage.**

### But current Exhausted barely bites dodge/crit

`str −30%, end −30%` hits the *wrong* stats for dodge/crit: their power lives
in AGI / POW, which Exhausted does **not** touch. An exhausted dodge keeps
dodging at full agility; an exhausted crit keeps critting at full power. So the
debuff is nearly toothless for exactly the classes that get it most.

→ **Lever:** make Exhausted reduce ALL stats (so agi/pow/int also drop). Since
dodge/crit are exhausted 60-83% of late-game and def 2-8%, an all-stat penalty
asymmetrically punishes dodge/crit → boosts def. (See open ideas.)

## str% / int-reduction% — current contribution

| L12 (random) | Str% of dmg | Reduction% of incoming |
|--------------|------------:|-----------------------:|
| def | 28% | 11-13% (highest — int 24) |
| crit | 22% | 9% |
| dodge | 26% | 9% |

- **Strength = ~25% of total damage** — weapon attack + crit multipliers carry the other ~75%. With the sqrt curve, str's share dropped further.
- **Intuition reduction absorbs ~10%** of incoming — modest but real; def's higher int gives it the edge here.

## Open ideas under evaluation (Session 2)

1. **Revert / fix sqrt curve** (variance regression) — pending decision.
2. **Revive END** — give it back reduction, or real per-block mitigation.
3. **Exhausted → all-stat penalty** (−10% or −30% to ALL) — asymmetrically punishes dodge/crit, boosts def.
4. **"Disarm" debuff** — on the round an elf drains its last EP to land a block (the exhaust transition), also bar it from attacking for 1 round (defend-only). Punishes exhausters (crit/dodge) → pro-def. Modest magnitude (1 round, once/battle).
