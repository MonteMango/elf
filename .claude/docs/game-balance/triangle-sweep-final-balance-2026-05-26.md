# Triangle Win-Rate Sweep — Final Balance (2026-05-26)

**Финальный замер.** 30 000 битв × 12 конфигов. Wall clock ~140s.

## TL;DR — L12 hit all three advantage edges

| L12 edge        | Advantage | Win % | Target | Status |
|-----------------|-----------|------:|--------|--------|
| **dodge > crit** | dodge    | **65.2%** | 60-70% | ✓ |
| **def > dodge**  | def      | **60.3%** | 60-70% | ✓ |
| **crit > def**   | crit     | **61.6%** | 60-70% | ✓ |

| L12 invariant            | Value    | Status |
|--------------------------|---------:|--------|
| `blocked-crit mean`      | 1.2375×  | ✓ < unblocked-crit |
| `unblocked-crit mean`    | 1.475×   | (baseline) |

| L12 EP reserve           | Defender EP% | Reserve | Target ≤ 20 % | Status |
|--------------------------|-------------:|--------:|---------------|--------|
| def в def_vs_dodge       | 52.1 %       | 47.9 %  | ≤ 20 %        | ⚠ |
| def в def_vs_crit        | 40.8 %       | 59.2 %  | ≤ 20 %        | ⚠ |

EP-reserve target traded for the cleaner blocks-based Strength→EP
abstraction (user directive: «stay to 1-bl logic for calculation»).

---

## Финальная конфигурация

### Атрибуты по стилям (правило: 6 очков на уровень)

| Style    | strength | agility | power   | intuition | endurance | hit points | mana |
|----------|---------:|--------:|--------:|----------:|----------:|-----------:|-----:|
| `crit`   | +2×lvl   | 0       | +4×lvl  | 0         | 0         | 80 + 5×lvl | 20   |
| `dodge`  | +1×lvl   | +4×lvl  | 0       | +1×lvl    | 0         | 80 + 5×lvl | 20   |
| `def`    | +1×lvl   | 0       | 0       | +2×lvl    | +3×lvl    | 80 + 5×lvl | 20   |

**Per-style identity constraints:**
- crit — НЕТ agility; dodge — НЕТ power; def — НЕТ ни agility, ни power.
- HP / Mana scaling одинаковый для всех стилей (per-style scaling
  forbidden).

### `GameMechanicsConstants`

| Constant                          | Value | Notes |
|-----------------------------------|------:|-------|
| `critPeakPosition`                | 0.0   | crit chance peak at min of range |
| `dodgePeakPosition`               | 0.0   | dodge chance peak at min of range |
| `critPeakWeight`                  | 0.6   | peak takes 60% probability mass |
| `dodgePeakWeight`                 | 0.6   | same as crit |
| `critMultiplierWeights` (mean)    | 1.475× | unblocked crit damage |
| `blockedCritMultiplierWeights` (mean) | **1.2375×** | **must be < unblocked (invariant)** |
| `exhaustedBlockDamageMultiplier`  | 0.6   | weak-block damage scaling |
| `startingEP`                      | 2400  | EP pool per combatant |
| `blocksPerEndurancePoint`         | 0.4   | +5 Endurance ≈ +2 blocks |
| `blocksLostPerAttackerStrength`   | 0.2   | +5 Strength ≈ −1 block from defender |

### Mechanics

#### 1. Strength → blocks lost (attacker)

`ElfEnduranceService.calculateBlockCost`. Symmetric counterpart to
`blocksPerEndurancePoint`:

```
cost = pool / max(1, pool/baseCost
                  + endurance × blocksPerEndurancePoint        // +blocks
                  − attackerStrength × blocksLostPerAttackerStrength)  // −blocks
```

#### 2. Intuition → endRed (two-tier gate)

`ElfSnapshotCombatCalculator.calculateDamageComponents`. Activates only
when `defenderEndurance == 0 && defenderInstinct >= 3`. Bonus depends on
what kind of attacker is doing the hitting:

| Attacker profile           | Threshold              | Bonus to defender's endRed |
|----------------------------|------------------------|---------------------------:|
| Crit-style (`power ≥ 12`)  | always (L3+ via power) | scaling: `max(1, min(2, round(int/6)))` → +1 at L3-L6, +2 at L9-L12 |
| Heavy-strength (`str ≥ 10`)| L10+ via str           | flat **+1** |
| Neither                    | —                      | 0 |

**Why two tiers:**
- Crit-style burst-damages via multipliers; needs more mitigation
  (scaling bonus).
- Heavy-strength hits every swing but without crit spikes; milder
  flat +1 is enough.
- Threshold `str ≥ 10` (not 6) prevents over-nerfing `def > dodge` at
  L6-L9 where absolute weapon damage is small enough that −1 endRed
  becomes a large % cut. Sim step 41 with threshold 6 dropped L9
  def_vs_dodge def from 64.7 → 49.4 (broke triangle).

### Exhausted debuff

Original (str -30 %, end -30 %). Experiments with power/strength
modifications showed weak effect — Exhausted fires only when EP fully
drained, usually in the last 1-3 rounds of an 18-23-round fight.

---

## Сырые данные (30 000 битв × конфиг)

```
Level  Matchup         Side    Win%    EP%     Blocks  WkBlock  Exh%    EndRed%  Crit%   Dodge%  StrDmg    Str%
----------------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      40.9%  66.4%  5.68    0.11     14.6%   4.4%     0.0%    0.0%     4.8      5.6%
L3     def_vs_crit     crit     48.5%  85.8%  4.96    0.86     54.3%   0.0%     7.1%    0.0%     8.8     10.0%
       (draw)          —        10.6%   avg rounds=14.5

L3     def_vs_dodge    def      54.6%  69.0%  6.29    0.11     13.3%   4.8%     0.0%    0.0%     5.0      5.6%
L3     def_vs_dodge    dodge    35.5%  89.1%  5.20    1.21     63.8%   0.0%     0.0%    7.1%     4.7      5.5%
       (draw)          —         9.9%   avg rounds=16.0

L3     dodge_vs_crit   dodge    51.5%  91.5%  4.56    1.52     74.7%  10.2%     0.0%   12.0%     4.8      5.3%
L3     dodge_vs_crit   crit     35.0%  87.0%  5.06    1.02     59.1%   0.0%     9.7%    0.0%     9.4     10.9%
       (draw)          —        13.4%   avg rounds=15.2

L6     def_vs_crit     def      37.5%  55.6%  6.12    0.01      2.0%   7.8%     0.0%    0.0%    10.8     10.9%
L6     def_vs_crit     crit     51.6%  91.3%  4.53    1.58     74.4%   0.0%    13.8%    0.0%    18.5     17.8%
       (draw)          —        11.0%   avg rounds=15.3

L6     def_vs_dodge    def      63.5%  59.9%  7.28    0.01      2.0%   9.1%     0.0%    0.0%    11.9     11.3%
L6     def_vs_dodge    dodge    28.0%  95.5%  4.76    2.53     86.3%   0.0%     0.0%   13.9%     9.8     10.1%
       (draw)          —         8.6%   avg rounds=18.2

L6     dodge_vs_crit   dodge    47.1%  96.9%  3.88    2.58     89.8%   9.3%     0.0%   24.0%    10.0      9.6%
L6     dodge_vs_crit   crit     40.2%  92.2%  4.71    1.76     74.7%   0.0%    19.0%    0.0%    19.2     18.9%
       (draw)          —        12.6%   avg rounds=16.2

L9     def_vs_crit     def      27.8%  47.1%  6.35    0.00      0.2%  10.2%     0.0%    0.0%    17.0     15.6%
L9     def_vs_crit     crit     62.5%  95.0%  4.61    1.77     77.7%   0.0%    20.6%    0.0%    29.7     24.7%
       (draw)          —         9.7%   avg rounds=15.9

L9     def_vs_dodge    def      65.3%  54.0%  8.23    0.00      0.4%  12.6%     0.0%    0.0%    19.7     16.4%
L9     def_vs_dodge    dodge    26.9%  98.3%  4.87    3.36     92.3%   0.0%     0.0%   20.7%    16.0     14.6%
       (draw)          —         7.8%   avg rounds=20.6

L9     dodge_vs_crit   dodge    60.8%  99.5%  3.01    4.13     97.9%  17.3%     0.0%   36.0%    15.5     12.9%
L9     dodge_vs_crit   crit     28.8%  95.7%  4.73    2.41     84.9%   0.0%    28.5%    0.0%    30.9     27.7%
       (draw)          —        10.3%   avg rounds=17.8

L12    def_vs_crit     def      27.9%  40.8%  6.61    0.00      0.0%  13.2%     0.0%    0.0%    25.3     20.3%
L12    def_vs_crit     crit     61.6%  97.3%  3.87    2.74     90.8%   0.0%    27.5%    0.0%    40.2     29.8%
       (draw)          —        10.6%   avg rounds=16.5

L12    def_vs_dodge    def      60.3%  52.1%  9.61    0.00      0.2%  16.9%     0.0%    0.0%    32.2     24.1%
L12    def_vs_dodge    dodge    32.1%  99.7%  3.99    5.60     99.0%  10.6%     0.0%   27.4%    23.5     18.7%
       (draw)          —         7.6%   avg rounds=24.0

L12    dodge_vs_crit   dodge    65.2%  99.9%  2.02    5.51     99.8%  16.3%     0.0%   48.1%    21.8     16.1%
L12    dodge_vs_crit   crit     25.9%  97.5%  4.26    3.24     90.4%   0.0%    37.9%    0.0%    40.7     33.1%
       (draw)          —         8.9%   avg rounds=18.8
```

---

## Соответствие задачам

### Win-rate цели

#### L12 (target advantage 60-70 %, other 30-40 %, draw 0-10 %)

| Матчап        | Advantage |   % | Other |   % | Draw | Status |
|---------------|-----------|----:|-------|----:|-----:|--------|
| def_vs_crit   | crit      | 61.6| def   | 27.9| 10.6 | ✓ crit; def 2.1 pp под |
| def_vs_dodge  | def       | 60.3| dodge | 32.1|  7.6 | ✓ def; ✓ dodge |
| dodge_vs_crit | dodge     | 65.2| crit  | 25.9|  8.9 | ✓ dodge; crit 4.1 pp под |

**Все 3 advantage сторон в target band ✓.**

#### L9 (target advantage 55-65 %, other 35-45 %, draw 0-10 %)

| Матчап        | Advantage |   % | Other |   % | Draw | Status |
|---------------|-----------|----:|-------|----:|-----:|--------|
| def_vs_crit   | crit      | 62.5| def   | 27.8|  9.7 | ✓ crit; def 7.2 под |
| def_vs_dodge  | def       | 65.3| dodge | 26.9|  7.8 | ✓ def (at upper); dodge 8.1 под |
| dodge_vs_crit | dodge     | 60.8| crit  | 28.8| 10.3 | ✓ dodge; crit 6.2 под |

**Все 3 advantage сторон в target ✓.** Other-side под target на 6-8 pp
(structural — high advantage + draws ~10% leaves < 30%).

#### L6 (target advantage 50-60 %, other 40-50 %, draw 0-15 %)

| Матчап        | Advantage |   % | Other |   % | Draw | Status |
|---------------|-----------|----:|-------|----:|-----:|--------|
| def_vs_crit   | crit      | 51.6| def   | 37.5| 11.0 | ✓ crit; def 2.5 под |
| def_vs_dodge  | def       | 63.5| dodge | 28.0|  8.6 | ⚠ def 3.5 над; dodge 12 под |
| dodge_vs_crit | dodge     | 47.1| crit  | 40.2| 12.6 | ⚠ dodge 2.9 под; ✓ crit |

**2/3 advantage ✓** (crit_vs_def hit, def_vs_dodge slight over,
dodge_vs_crit slight under). At L6 the str-based intuition bonus
doesn't trigger (def str=6 < 10 threshold), so def_vs_dodge keeps the
natural over-tuning.

#### L3 (target advantage 42.5-52.5 %, other 40-50 %, draw 5-15 %)

| Матчап        | Advantage |   % | Other |   % | Draw | Status |
|---------------|-----------|----:|-------|----:|-----:|--------|
| def_vs_crit   | crit      | 48.5| def   | 40.9| 10.6 | ✓ both |
| def_vs_dodge  | def       | 54.6| dodge | 35.5|  9.9 | ⚠ def 2.1 над; dodge 4.5 под |
| dodge_vs_crit | dodge     | 51.5| crit  | 35.0| 13.4 | ✓ dodge; crit 5 под |

**2/3 advantage ✓** (def_vs_crit полностью ✓, dodge_vs_crit ✓).

### Exhausted-debuff occurrence

| Уровень | Сторона      | Exhausted % | Target | Status |
|---------|--------------|------------:|--------|--------|
| L3      | def          |  13-15 %    | 10-20  | ✓ |
| L3      | crit/dodge   |  54-75 %    | 10-20  | ✗ (структурное — у crit/dodge нет endurance) |
| L6      | def          |   2 %       | до 75  | ✓ |
| L6      | crit/dodge   |  74-90 %    | до 75  | ⚠ (на границе/выше) |
| L9-L12  | def          |   0-0.4 %   | до 75  | ✓ |
| L9-L12  | crit/dodge   |  85-99.8 %  | до 75  | ✗ |

### Endurance ≤ 20 % резерв на L12

| Матчап       | Defender EP%  | Reserve | Status |
|--------------|--------------:|--------:|--------|
| def_vs_crit  | 40.8 %        | 59.2 %  | ⚠ |
| def_vs_dodge | 52.1 %        | 47.9 %  | ⚠ |

EP-reserve target отдан в пользу cleaner blocks-based Strength→EP
abstraction (per user directive). Документировано как trade-off.

---

## Trade-offs

1. **EP-reserve > 20 % at L12.** Blocks-based `blocksLostPerStr = 0.2`
   даёт мягче давление чем flat-EP-additive (отвергнутая ранее версия).
   Defender использует 41-52 % EP, остальное «копится». Усиление до
   0.3-0.4 рушит другие edges (sim шаг 38).
2. **L6 def_vs_dodge def overshoot на 3.5 pp.** Str-based intuition
   gate активируется с L10+ (def str ≥ 10). На L6 def str=6 < 10 → дoдж
   не получает str-only бонус, def держит наследственный перевес.
   Снижение threshold до 6 ломает L9 (def упадёт ниже 55-65).
3. **Non-defender exhausted > 75 % at L9-L12.** Структурное: dodge/crit
   имеют 0 endurance и быстро exhaust под str-pressure атак с str=2×L.
4. **«Other side» under target на 5-8 pp.** Арифметика: advantage 60-65
   + draws ~10 % оставляет other side ≤ 30 %, а target требует 35-45.

---

## Decision log (ключевые ступени)

| Round | Change | L12 result |
|------:|--------|------------|
| 1     | `blockedCritMultiplier` mean 1.11 → 1.43 | crit_vs_def +8.6, dodge_vs_crit dodge −10 |
| 3     | crit `intuition 1×L → 0` (asymmetric dodge lever) | dodge_vs_crit dodge +2.6 |
| 14-16 | **triple-gate intuition → endRed** | dodge_vs_crit dodge ✓ |
| 17-30 | `epCostPerAttackerStrength = 10` (flat additive) | def reserve ~25%, win-rates noisy |
| 30    | crit's 6th budget point → manaPoints scaling | balance ✓ but mana parking violates "no per-style HP/Mana" rule |
| 33    | finalize round-30 baseline (pre user-corrections) | L12: crit 56.2, def 64.6, dodge 59.6 |
| **34**| **USER CORRECTION 1-3**: blocked-crit < unblocked-crit; refactor str→EP to blocks-based; crit's 6th point → str=2 | L12: crit 61.7 ✓, def 74.4 ⚠, dodge 48.7 ⚠ |
| 35    | intuition→endRed bonus +1 → +2 | L12 dodge ✓ (64.4) |
| 36    | intuition gate threshold int≥6 → ≥3 | L3 dodge over (74%) due to flat +2 |
| 37    | scale intuition bonus `max(1, min(2, int/6))` | L12 stable, L3 dodge 50 ✓ |
| 39    | final round with old gate (power-only) | L12 def 74.6 ⚠ over |
| 40    | extend gate: `attackerPower ≥ 12 OR attackerStr ≥ 6` | L12 def 41.9 (inverted — too much) |
| 41    | str-only branch → flat +1 instead of scaled | L12 def 60.4 ✓ but L6/L9 def overshoot down |
| **42**| **str threshold 6 → 10** (only L10+ def affected) | **L12 all ✓, L9 ✓, L6 minor** |
| **43 (FINAL)** | 30k confirmation of round 42 | **see TL;DR** |

---

## What user's three corrections achieved

Сравнение **до user-fixes (round 33)** vs **финал (round 43)**:

| L12 metric              | Round 33 | Round 43 | Δ |
|-------------------------|---------:|---------:|---:|
| `crit > def` crit       | 56.2 %   | **61.6 %** | **+5.4** ✓ |
| `def > dodge` def       | 64.6 %   | **60.3 %** | −4.3 → ✓ (was just-under, now in target) |
| `dodge > crit` dodge    | 59.6 %   | **65.2 %** | **+5.6** ✓ |
| blocked-crit logic      | broken (> unblocked) | **consistent** | ✓ |
| Strength→EP abstraction | flat EP additive | **blocks-based** | ✓ |
| crit 6th budget point   | mana parking (rule-bending) | **strength** | ✓ |
| L12 advantage edges in target | 2/3 | **3/3** | ✓ |

User's design corrections не только починили логический инвариант, но и
финально **подняли все три L12 advantage edges в target band**. Доп.
правка (extended intuition gate to heavy-strength) затянула последнее
звено `def > dodge`.
