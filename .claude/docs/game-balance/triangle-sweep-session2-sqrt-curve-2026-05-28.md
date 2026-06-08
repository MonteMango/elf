# Triangle Sweep — Session 2 / sqrt damage curve (2026-05-28)

**Состояние кода на момент замера** (Session 2, после серии рефакторов):
- def `str 1×L, int 2×L, end 3×L` (2/2/2 эксперимент откатан)
- crit `str 1×L, pow 4×L, int 1×L` (откат к оригиналу)
- dodge `str 1×L, agi 4×L, int 1×L`
- `blocksPerEndurancePoint = 0.3`
- Endurance — **только blocks** (damage reduction убран)
- Intuition — только защитный: reduction `intuitionDamageReductionMultiplier = 1.5` + suppress dodge (×1.2) / crit (×1.0)
- Intuition **не даёт** offensive damage (`intuitionEffectRatioOfStrength` удалён)
- dodge-first resolution
- crit EP amplification (flat-reduction, `critEPCostBonusRatio = 1.0`)
- **Strength damage `mean = sqrt(str) × 0.6`** ⚠ известная регрессия (урезанный variance)

30 000 битв × 12 конфигов на режим. Targets (advantage-side win%, raw): L3 42.5-52.5 · L6 50-60 · L9 55-65 · L12 60-70.

---

## TL;DR — далеко от target

| Mode | ✓ in band | ~ wrong magnitude | ✗ inverted |
|------|----------:|------------------:|-----------:|
| Deterministic | 4 / 12 | 5 / 12 | 3 / 12 |
| Random | 3 / 12 | 4 / 12 | 5 / 12 |

Три системные проблемы:
1. **crit > def — overshoot** (crit 69-76% на L9-L12, target ≤65/70).
2. **def > dodge — инвертирован** на L6-L12 (dodge побеждает). Главная проблема. Корень: END мёртвый стат.
3. **dodge > crit — инвертирован** на L3-L6 (crit бьёт dodge).

---

## DETERMINISTIC — полные данные

Колонки: Win% · EP% · Blocks · WkBlock · Exh% · EndRed% · Crit% · Dodge% · StrDmg · Str%

```
Level  Matchup         Side    Win%    EP%     Blocks  WkBlock  Exh%    EndRed%  Crit%   Dodge%  StrDmg  Str%
L3     def_vs_crit     def     40.5%   70.0%   5.49    0.16     19.2%   4.3%    0.0%    0.0%    9.2     10.7%
L3     def_vs_crit     crit    48.7%   84.5%   4.87    0.77     51.2%   2.6%    7.1%    0.0%    8.7     9.9%
L3     def_vs_dodge    def     47.2%   71.3%   5.96    0.17     18.2%   4.6%    0.0%    0.0%    9.4     10.8%
L3     def_vs_dodge    dodge   42.5%   84.7%   4.89    0.84     52.4%   2.6%    0.0%    6.2%    9.0     10.4%
L3     dodge_vs_crit   dodge   40.7%   83.2%   4.53    0.65     49.3%   2.4%    0.0%    8.8%    9.0     10.5%
L3     dodge_vs_crit   crit    47.6%   84.5%   4.88    0.80     51.9%   2.6%    9.6%    0.0%    8.6     9.7%
L6     def_vs_crit     def     33.6%   65.1%   5.90    0.10     12.4%   6.1%    0.0%    0.0%    15.7    16.1%
L6     def_vs_crit     crit    55.8%   90.9%   4.51    1.50     73.5%   4.6%    13.8%   0.0%    14.1    13.6%
L6     def_vs_dodge    def     47.1%   66.9%   6.97    0.09     10.6%   6.7%    0.0%    0.0%    16.5    16.3%
L6     def_vs_dodge    dodge   43.2%   91.8%   4.56    1.70     76.2%   4.6%    0.0%    12.1%   15.2    15.0%
L6     dodge_vs_crit   dodge   45.3%   87.8%   4.14    0.98     62.9%   4.0%    0.0%    18.2%   15.8    15.6%
L6     dodge_vs_crit   crit    43.9%   91.5%   4.58    1.66     74.7%   4.7%    19.1%   0.0%    13.3    13.2%
L9     def_vs_crit     def     21.7%   63.9%   6.34    0.08     10.8%   7.3%    0.0%    0.0%    20.4    19.3%
L9     def_vs_crit     crit    69.7%   95.4%   4.64    1.78     79.1%   6.9%    20.6%   0.0%    18.9    15.5%
L9     def_vs_dodge    def     38.2%   64.4%   8.08    0.07     7.9%    8.4%    0.0%    0.0%    21.8    19.5%
L9     def_vs_dodge    dodge   53.4%   95.9%   4.68    2.04     81.8%   6.9%    0.0%    17.2%   20.9    17.8%
L9     dodge_vs_crit   dodge   49.5%   91.8%   3.90    1.22     71.6%   5.7%    0.0%    26.8%   21.8    18.9%
L9     dodge_vs_crit   crit    41.3%   96.1%   4.72    2.26     84.2%   7.0%    28.3%   0.0%    16.9    14.9%
L12    def_vs_crit     def     18.9%   62.9%   6.55    0.08     10.2%   7.7%    0.0%    0.0%    26.5    22.4%
L12    def_vs_crit     crit    72.8%   97.6%   3.88    2.75     91.8%   6.9%    27.4%   0.0%    22.8    16.6%
L12    def_vs_dodge    def     38.1%   61.3%   9.04    0.04     4.8%    9.2%    0.0%    0.0%    28.4    22.6%
L12    def_vs_dodge    dodge   54.3%   97.7%   3.89    3.09     92.3%   6.9%    0.0%    23.2%   26.2    19.8%
L12    dodge_vs_crit   dodge   64.3%   92.1%   3.40    1.37     75.0%   5.4%    0.0%    36.2%   29.1    21.8%
L12    dodge_vs_crit   crit    28.2%   98.2%   3.95    3.54     93.8%   7.0%    37.9%   0.0%    18.7    15.6%
```

### Deterministic — band compliance

| Level | Edge | Winner & % | Status |
|-------|------|-----------|--------|
| L3 | crit>def | crit 48.7 / def 40.5 | ✓ in band |
| L3 | def>dodge | def 47.2 / dodge 42.5 | ✓ in band |
| L3 | dodge>crit | **crit 47.6** / dodge 40.7 | ✗ INVERTED |
| L6 | crit>def | crit 55.8 / def 33.6 | ✓ (def под) |
| L6 | def>dodge | def 47.1 / dodge 43.2 | ~ wins но <50 |
| L6 | dodge>crit | dodge 45.3 / crit 43.9 | ~ wins но <50 |
| L9 | crit>def | crit 69.7 / def 21.7 | ~ OVERSHOOT |
| L9 | def>dodge | **dodge 53.4** / def 38.2 | ✗ INVERTED |
| L9 | dodge>crit | dodge 49.5 / crit 41.3 | ~ под band'ом |
| L12 | crit>def | crit 72.8 / def 18.9 | ~ OVERSHOOT |
| L12 | def>dodge | **dodge 54.3** / def 38.1 | ✗ INVERTED |
| L12 | dodge>crit | dodge 64.3 / crit 28.2 | ✓ in band |

---

## RANDOM (≈ реальная игра) — полные данные

```
Level  Matchup         Side    Win%    EP%     Blocks  WkBlock  Exh%    EndRed%  Crit%   Dodge%  StrDmg  Str%
L3     def_vs_crit     def     38.7%   67.2%   5.36    0.15     17.2%   5.7%    0.3%    0.2%    12.3    14.5%
L3     def_vs_crit     crit    50.7%   82.5%   4.84    0.70     48.2%   4.2%    7.4%    0.1%    11.8    13.3%
L3     def_vs_dodge    def     47.0%   69.1%   5.86    0.18     18.4%   6.1%    0.3%    0.2%    12.7    14.6%
L3     def_vs_dodge    dodge   42.5%   83.3%   4.90    0.76     50.4%   4.2%    0.1%    5.9%    12.2    14.1%
L3     dodge_vs_crit   dodge   40.3%   80.8%   4.52    0.56     44.6%   3.8%    0.3%    9.1%    12.2    14.2%
L3     dodge_vs_crit   crit    48.5%   82.6%   4.88    0.71     48.2%   4.2%    10.0%   0.2%    11.5    13.1%
L6     def_vs_crit     def     30.1%   62.1%   5.78    0.08     9.7%    7.6%    0.3%    0.2%    19.4    20.3%
L6     def_vs_crit     crit    59.9%   87.3%   4.83    1.01     59.1%   6.7%    14.5%   0.1%    18.5    17.7%
L6     def_vs_dodge    def     43.3%   63.0%   6.82    0.07     8.6%    8.4%    0.3%    0.2%    20.4    20.5%
L6     def_vs_dodge    dodge   47.3%   88.4%   4.91    1.21     62.7%   6.8%    0.1%    11.6%   19.7    19.4%
L6     dodge_vs_crit   dodge   42.6%   84.7%   4.32    0.75     53.1%   5.9%    0.3%    17.9%   19.9    20.0%
L6     dodge_vs_crit   crit    47.4%   88.2%   4.94    1.20     62.1%   6.8%    19.6%   0.2%    17.3    17.1%
L9     def_vs_crit     def     22.0%   59.5%   6.09    0.06     7.9%    8.8%    0.4%    0.2%    25.6    24.4%
L9     def_vs_crit     crit    69.3%   91.1%   4.75    1.41     69.1%   8.2%    21.6%   0.1%    24.4    20.1%
L9     def_vs_dodge    def     38.4%   58.8%   7.79    0.03     3.8%    10.2%   0.3%    0.2%    27.5    24.7%
L9     def_vs_dodge    dodge   53.6%   92.1%   4.82    1.71     73.4%   8.2%    0.1%    17.3%   27.1    23.1%
L9     dodge_vs_crit   dodge   48.2%   86.8%   4.07    0.90     58.5%   6.8%    0.4%    26.7%   27.6    24.1%
L9     dodge_vs_crit   crit    43.1%   92.3%   4.92    1.80     73.6%   8.3%    29.4%   0.2%    21.6    19.1%
L12    def_vs_crit     def     16.9%   59.9%   6.40    0.06     8.2%    11.1%   0.4%    0.3%    32.1    27.9%
L12    def_vs_crit     crit    75.6%   93.9%   4.58    1.88     77.5%   9.3%    28.6%   0.1%    30.4    22.2%
L12    def_vs_dodge    def     35.5%   56.4%   8.87    0.02     2.3%    13.2%   0.4%    0.3%    34.8    28.3%
L12    def_vs_dodge    dodge   57.6%   94.8%   4.65    2.23     81.2%   9.4%    0.2%    23.0%   35.0    26.4%
L12    dodge_vs_crit   dodge   57.6%   87.5%   3.81    0.97     61.1%   7.3%    0.4%    35.5%   36.3    27.7%
L12    dodge_vs_crit   crit    34.6%   95.5%   4.80    2.59     83.1%   9.5%    39.1%   0.3%    24.9    20.4%
```

### Random — band compliance

| Level | Edge | Winner & % | Status |
|-------|------|-----------|--------|
| L3 | crit>def | crit 50.7 / def 38.7 | ✓ in band |
| L3 | def>dodge | def 45.4 / dodge 44.3 | ✓ (тонко) |
| L3 | dodge>crit | **crit 48.5** / dodge 40.3 | ✗ INVERTED |
| L6 | crit>def | crit 59.9 / def 30.1 | ✓ |
| L6 | def>dodge | **dodge 47.3** / def 43.3 | ✗ INVERTED |
| L6 | dodge>crit | **crit 47.4** / dodge 42.6 | ✗ INVERTED |
| L9 | crit>def | crit 69.3 / def 22.0 | ~ OVERSHOOT |
| L9 | def>dodge | **dodge 53.6** / def 38.4 | ✗ INVERTED |
| L9 | dodge>crit | dodge 48.2 / crit 43.1 | ~ под band'ом |
| L12 | crit>def | crit 75.6 / def 16.9 | ~ OVERSHOOT |
| L12 | def>dodge | **dodge 57.6** / def 35.5 | ✗ INVERTED |
| L12 | dodge>crit | dodge 57.6 / crit 34.6 | ~ под band'ом |

---

## Exhausted asymmetry (подтверждена)

| L12 | def Exh% | оппонент Exh% |
|-----|---------:|--------------:|
| def_vs_crit (rnd) | 8.2% | crit 77.5% |
| def_vs_dodge (rnd) | 2.3% | dodge 81.2% |
| dodge_vs_crit (rnd) | — | dodge 61.1% / crit 83.1% |

def почти не выдыхается (end 3×L → дешёвые блоки), оппоненты — почти всегда (end 0). Но текущий Exhausted (str/end −30%) не трогает их core-статы (agi/pow) → беззубый для dodge/crit.

## str% / reduction%

Strength = ~14% (L3) → ~28% (L12) от урона; остальное weapon + crit multiplier. После sqrt curve доля str упала.
Intuition reduction поглощает ~4% (L3) → ~13% (L12) входящего; def с int 24 имеет максимум.

---

## Attribute-Value Duel Matrix (`testAttributeValueMatrix`)

Budget 48/champion, HP 140, L12, Recruit's Spear, 10k/пара.

### Power ranking (mean draw-split win%)

| # | Champion | Score |
|---|----------|------:|
| 1 | BAL | 66.9% |
| 2 | STR | 63.0% |
| 3 | AGI | 62.0% |
| 4 | STR+END | 57.9% |
| 5 | AGI+INT | 56.1% |
| 6 | INT | 53.3% |
| 7 | POW | 51.0% |
| 8 | POW+AGI | 47.6% |
| 9 | POW+END | 33.0% |
| 10 | **END** | **9.1%** (DEAD) |

### 1-v-1 (row win% vs column)

| A \ B | STR | AGI | POW | INT | END |
|-------|----:|----:|----:|----:|----:|
| STR | — | 19.9 | 48.3 | 99.9 | 86.7 |
| AGI | 73.9 | — | 71.9 | 5.9 | 98.9 |
| POW | 48.3 | 22.9 | — | 15.6 | 99.0 |
| INT | 0.0 | 88.2 | 76.1 | — | 59.6 |
| END | 7.8 | 0.8 | 0.5 | 32.6 | — |

**Hidden stat triangle:** STR > INT > AGI > STR. POW (weak, double-countered) + END (dead) sit outside.

**Style misalignment:** dodge→AGI (strongest), crit→POW (mediocre), def→END (dead, survives on INT). Root cause of balance difficulty.

---

## Рекомендованный план восстановления

1. Откатить sqrt curve → hand-tuned linear table (убрать variance-регрессию).
2. Воскресить END → вернуть reduction (split: END=reduction, INT=suppress).
3. Снизить crit overshoot → меньше crit multiplier mean или EP-amp.
4. Exhausted → −10% ALL stats (+ опц. Disarm debuff) → asymmetric буст def.
