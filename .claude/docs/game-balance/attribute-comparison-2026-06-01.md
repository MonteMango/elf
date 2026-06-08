# Attribute Comparison — Solo Power vs Marginal Value (2026-06-01)

Comprehensive cross-check of all 5 combat attributes (STR, AGI, POW, INT, END)
combining three data sources:
1. **Mechanical summary** — what each attribute does in the rules
2. **Solo power** — `testAttributeValueMatrix` (48 points in one stat,
   vs all other pure & combo champions at L12)
3. **Marginal value** — derived per-point HP / damage contribution at L12
4. **Class strategy fit** — `testAttributeStrategiesPerClass` (which
   fight style benefits most from each)

**Code state at snapshot:**
- def `1str + 2int + 3end`, crit `1str + 4pow + 1int`, dodge `1str + 4agi + 1int`
- Strength damage: `sqrt(str) × 0.6`
- INT reduction: `sqrt(int) × 0.12` (20 % of strength)
- END reduction: `sqrt(end) × 0.18` (30 % of strength)
- `blocksPerEndurancePoint = 0.3`
- `blocksLostPerAttackerStrength = 0.1`
- Dynamic suppression: dodge `0.8 + 0.04·attLvl`, crit `0.8 + 0.024·attLvl`
- Exhausted: −10 % all combat attrs
- Crit EP amplification (`critEPCostBonusRatio = 1.0`)

---

## 1. Mechanical Summary

```
┌──────┬────────────────────────────────────────────────────────┐
│ Attr │ Effects                                                │
├──────┼────────────────────────────────────────────────────────┤
│ STR  │ Damage: sqrt(str) × 0.6 per strike                     │
│      │ Block-erosion: 0.1 × attackerStr disrupts opp blocks   │
├──────┼────────────────────────────────────────────────────────┤
│ AGI  │ Dodge chance: range [agi − int×mult, min(100, agi)]    │
│      │ Linear scaling, capped at 100                          │
├──────┼────────────────────────────────────────────────────────┤
│ POW  │ Crit chance: range [pow − int×mult, min(100, pow)]     │
│      │ Crit multiplier: 1.64× mean (separate distribution)    │
├──────┼────────────────────────────────────────────────────────┤
│ INT  │ Reduction: sqrt(int) × 0.12 per strike                 │
│      │ Suppress dodge: int × dodgeMultiplier reduces enemy    │
│      │ Suppress crit: int × critMultiplier reduces enemy      │
│      │ Triple-dipper                                          │
├──────┼────────────────────────────────────────────────────────┤
│ END  │ Blocks: cheaper, +0.3 effective blocks per point       │
│      │ Reduction: sqrt(end) × 0.18 per strike                 │
│      │ Double-dipper                                          │
└──────┴────────────────────────────────────────────────────────┘
```

---

## 2. Solo Power Ranking

From `testAttributeValueMatrix` — pure-stat champions at L12 with 48-point
budget into one attribute, round-robin vs all opposing champions.

```
┌────┬──────────┬───────┬────────────────────────────────┐
│ #  │ Champion │ Score │            Verdict             │
├────┼──────────┼───────┼────────────────────────────────┤
│ 1  │ BAL      │ 72.4% │ Best — no hard counter         │
│ 2  │ AGI      │ 62.7% │ 🟢 Top solo stat (linear cap)  │
│ 3  │ STR+END  │ 60.8% │ 🟢 Top combo (offense+tank)    │
│ 4  │ STR      │ 55.4% │ 🟡 Generalist offense          │
│ 5  │ POW      │ 53.1% │ 🟡 Mediocre (countered by INT) │
│ 6  │ POW+END  │ 50.1% │ ⚪ Average                     │
│ 7  │ AGI+INT  │ 47.2% │ 🟠 INT drag down               │
│ 8  │ POW+AGI  │ 46.7% │ 🟠 No defense                  │
│ 9  │ INT      │ 33.0% │ 🔴 Solo weak (can't kill)      │
│ 10 │ END      │ 20.0% │ 🔴 Solo terrible (no offense)  │
└────┴──────────┴───────┴────────────────────────────────┘
```

---

## 3. Marginal Value per Point at L12

Effective HP / damage contribution per single attribute point when paired
with a "fundamental offense" baseline (≈ def's stat profile).

```
┌──────┬─────────────┬─────────────────────────────────────────┐
│ Attr │ Per point   │ Why                                     │
│      │ contribution│                                         │
├──────┼─────────────┼─────────────────────────────────────────┤
│ END  │ ~1.8 HP/btl │ Blocks (~10 dmg each) + reduction       │
├──────┼─────────────┼─────────────────────────────────────────┤
│ INT  │ ~0.83 HP/btl│ Reduction + suppression of opponent     │
├──────┼─────────────┼─────────────────────────────────────────┤
│ STR  │ ~2.1 dmg/btl│ Sqrt diminishing returns                │
├──────┼─────────────┼─────────────────────────────────────────┤
│ POW  │ ~1% chance  │ Linear, but capped by opponent INT      │
├──────┼─────────────┼─────────────────────────────────────────┤
│ AGI  │ ~1% chance  │ Linear, capped at 100 — НО hard cap     │
└──────┴─────────────┴─────────────────────────────────────────┘
```

**Key paradox:** **END has WORST solo power (20 %) but HIGHEST per-point
effective HP (1.8 eHP).** END is the classic support stat: useless alone,
multiplies anything it's paired with.

---

## 4. Strategy Fit per Class @ L12 (vs random opponents)

```
┌────────────┬─────────┬─────────┬─────────┐
│ Strategy   │ DEF win │ CRIT win│ DODGE   │
│ (all bonus │   %     │   %     │   win % │
│  into X)   │         │         │         │
├────────────┼─────────┼─────────┼─────────┤
│ all-STR    │  52.6%  │  37.7%  │  45.8%  │
│ all-AGI    │  41.5%  │  26.1%  │ 95.3% 💀│
│ all-POW    │  45.6%  │ 62.4% 🥇│  39.3%  │
│ all-INT    │ 60.2% 🥇│  46.4%  │  31.9%  │
│ all-END    │  10.2% ☠│  45.1%  │  34.2%  │
│ STR+END    │  27.9%  │  55.9%  │  53.6%  │
│ random     │  31.3%  │  61.5%  │  56.9%  │
└────────────┴─────────┴─────────┴─────────┘
```

**Per-class tier list:**

- **DEF:** `all-INT > all-STR > all-POW > random > STR+END > all-END (☠)`
- **CRIT:** `all-POW ≈ random > STR+END > all-INT > all-END > all-STR`
- **DODGE:** `all-AGI (💀) >>> random > STR+END > all-STR`

---

## 5. Per-Attribute Verdict

### 🟢 STR — Reliable Generalist
- **Solo:** #4 (55 %)
- **Marginal:** ~2.1 dmg/battle per point
- **Class fit:** def #2 (52.6 %), dodge #4 (45.8 %)
- ✅ Damage + block-erosion
- ✅ Useful for all classes as secondary
- ⚠ sqrt diminishing returns at high values
- ⚠ Hard-countered by AGI (dodge avoids the damage)

### 🟢 AGI — Top Solo (but broken for dodge)
- **Solo:** #2 (62.7 %)
- **Marginal:** ~1 % dodge per point (linear)
- **Class fit:** dodge GOAT (95.3 % 💀)
- ✅ Linear scaling, no diminishing
- ✅ 100 % damage avoidance when triggers
- ❌ **EXPLOIT** for dodge in player-choice mode
- ❌ Useless against AGI=0 enemies (every other class)
- ❌ Countered by INT suppression

### 🟡 POW — Niche, mediocre solo
- **Solo:** #5 (53 %)
- **Marginal:** ~1 % crit chance per point (capped)
- **Class fit:** crit #1 (62.4 %)
- ✅ Crit's class identity stat
- ✅ Amplifier mechanic (1.64× multiplier)
- ❌ Countered by INT
- ❌ Mediocre solo
- ❌ Sqrt-diminished damage even when triggers

### 🔴 INT — Strong for def, weak solo
- **Solo:** #9 (33 %)
- **Marginal:** ~0.83 eHP per point
- **Class fit:** def #1 (60.2 %)
- ✅ Triple-dipper (reduction + 2 suppress)
- ✅ Best stat for def-class at L12
- ✅ Hard counter to dodge/crit chance
- ❌ No offense — can't kill solo
- ❌ Low absolute reduction value

### 🔴 END — Worst Solo, GREAT in combo
- **Solo:** #10 (20 % ☠)
- **Marginal:** ~1.8 eHP per point (HIGHEST!)
- **Class fit:** crit/dodge fill 0-end weakness
- ✅ Highest per-point eHP contribution
- ✅ Best in STR+END combo (60.8 %)
- ❌ Solo: provably worst (20 %)
- ❌ Over-cap for def → `all-END for def = 10 % ☠`
- ❌ Sqrt diminishing on reduction

---

## 6. Solo Power vs Marginal Value Plot

```
                      SOLO POWER
                          ▲
                          │
                       AGI│
                          │ 60%+
                          │
                          ├─── STR ─── BAL/STR+END
                          │ 55%
              random      ├─── POW ─── 50%
              opponents   │
                          ├─── INT ─── 33% (weak solo)
                          │
                          ├─── END ─── 20% (terrible solo)
                          │
                          ▼
              LOW────────────────────────HIGH
                       MARGINAL VALUE

        STR: mid-mid    | POW: mid-low | END: low-HIGH (combo king)
        AGI: high-high  | INT: low-mid | (only for dodge)
```

---

## 7. Headline Statements

| Metric | Top stat |
|--------|----------|
| **Solo power** | AGI (62.7 %) |
| **GOAT combo** | STR+END (60.8 %) |
| **Best for def** | INT (60.2 %) |
| **Best for crit** | POW (62.4 %) |
| **Best for dodge** | AGI (95.3 % 💀 broken) |
| **Highest per-point eHP** | END (1.8 eHP) |
| **Worst solo** | END (20 % ☠) |
| **Most underrated** | END (matrix #10, but fills crit/dodge gaps) |
| **Most overrated** | AGI (#2 solo, but exploit-tier for dodge) |

---

## 8. Implications for Balance

1. **END's paradox** (worst solo + highest marginal) means END is a **support
   multiplier**, not a primary attribute. Players who pick END solo will
   struggle; players who pair END with offense (STR+END) get goat results.
2. **AGI exploit unresolved.** Player choice would let dodge pick all-AGI
   for 95.3 % wins. Requires structural cap.
3. **INT's role is class-specific.** Triple-dipper INT carries def-class
   (60.2 %) but fails any class that needs offense.
4. **POW is permanently mediocre.** It's crit's only real option, but
   countered by INT and capped by sqrt-diminished crit damage. Worth
   considering structural buff (e.g., POW providing minor reduction-pierce).
5. **STR remains universal default** offensive pick despite sqrt curve —
   reliable damage + block-erosion still beats most defensive stats.

---

## 9. Trail / Related docs

- `triangle-sweep-session2-sqrt-curve-2026-05-28.md` — mid-session triangle baseline
- `attribute-strategy-choice-2026-06-01.md` — original player-choice exploration (base 1.2)
- `blocks-lost-per-str-01-2026-06-01.md` — `blocksLost 0.2→0.1` experiment
- `dynamic-suppression-08-2026-06-01.md` — dynamic crit+dodge suppression (this state)
- **THIS FILE** — attribute comparison synthesis

---

## Files referenced

- Tests: `Packages/elf_Kit/Tests/battle_simulation_IntegrationTests/BattleSimulationIntegrationTests.swift`
- Constants: `Packages/elf_Kit/Sources/DataLayer/Services/Constants/GameMechanicsConstants.swift`
- Strategies: `Packages/elf_Kit/Sources/DataLayer/Services/Damage/Implementation/Elf{Strength,EnduranceDamageReduction}DistributionStrategy.swift`
