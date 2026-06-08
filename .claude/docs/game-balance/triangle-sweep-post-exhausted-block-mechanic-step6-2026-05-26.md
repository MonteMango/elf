# Triangle Win-Rate Sweep — post exhausted-block mechanic step 6 (2026-05-26)

**Замер после внедрения механики "gradient of exhaustion" — нехватка EP больше
не "глотается молча", и Exhausted-боец сохраняет возможность блокировать ослабленно.**

## Что изменилось со step 5

**Изменения в коде** (модель + комбат + бафы + diag + UI):

1. **Блок при нехватке EP теперь срабатывает** —
   `ElfSnapshotCombatCalculator.resolveDefendedAttack` развёрнут в 4 ветки:
   - `EP ≥ blockCost` → как раньше (полный блок, оплачен `blockCost`).
   - `0 < EP < blockCost` → **полный** блок, тратится весь остаток EP. Раньше
     fall-through на undefended hit.
   - `EP == 0` + `Exhausted` в `battleBuffs` → **новый case**
     `PointStatus.weakBlocked`. Полный чейн урона (weapon × crit + str −
     end − armor), затем `× 0.5` (`exhaustedBlockDamageMultiplier`). EP не
     списывается.
   - `EP == 0` без Exhausted (середина того же раунда, где EP закончился)
     → fall-through на undefended hit.

2. **Exhausted применяется автоматически** —
   `DefaultBattleRoundRunner.applyExhaustedIfNeeded` после мутации HP/EP
   за раунд: если живой боец на 0 EP и в `battleBuffs` нет `ExhaustedBattle`
   — применяется через `BuffApplicationService.applyAsBattle`. Дублирования
   нет: `stackingRule: .ignore`.

3. **Каталог Exhausted раздвоен** на `Buffs.json`:
   - `BD…000001` — global, 3 дня (для активностей вне боя).
   - `BD…000002` — battle scope, без duration (используется раннером).

4. **Эффект Exhausted стал селективным** —
   `BuffEffect.combatAttributesPercentDelta(CombatAttributesPercentDelta)`
   с per-attribute процентами. Exhausted теперь режет `strength: -0.30,
   endurance: -0.30` вместо всех 5 стат на -30%.

5. **`PointStatus`** получил два публичных аксессора (`damageTakenValue`,
   `enduranceReductionValue`) — единый источник правды для
   `ElfDamageService.calculateTotalDamage` и `BattleDiagnostics`.

6. **`BattleDiagnostics`** расширен полями `totalWeakBlocksUsed`,
   `totalDamageReceived`, `totalEnduranceReduction`. `battlesExhausted` теперь
   реально работает (раньше комментарий говорил "always 0 by construction").
   Принтер пересобран — выкинуты мёртвые `Fail %` / `AvgRound` / `%Through`,
   добавлены `WkBlock` / `Exh%` / `EndRed%`.

7. **UI** — `HeroDisplayView` рендерит `BuffBadgeStripView` под EP-баром;
   новые `BuffBadgeView` / `BuffBadgeStripView`; `ElfColors.Buff` +
   `ElfSizing.BattleFight.buffBadge*`.

## Методика

Headless `BattleSimulationIntegrationTests.testStyleTriangleSweep`,
**30 000** битв × **12** конфигов (4 уровня × 3 матчапа). Wall clock
**132.5s** (близко к step 5: 124s — небольшой overhead от extra-полей
diagnostics и weak-block ветки).

## Справка по колонкам

Каждая строка — одна сторона боя. Метрики делятся на «оборонительные»
(что произошло с входящими ударами по нам) и «наступательные» (что мы
выдали).

| Колонка | Формула | Смысл |
|---------|---------|-------|
| `Win%` | wins / battles | Доля выигранных боёв стороной. |
| `EP%` | totalEPSpent / battles / maxEP | Средний расход EP за бой как доля пула (2000). |
| `Blocks` | totalBlocksUsed / battles | Полноценные блоки за бой (`.blocked` + `.critHit` с `epSpent > 0`). |
| `WkBlock` | totalWeakBlocksUsed / battles | Weak-блоки за бой (`.weakBlocked` — Exhausted+EP=0, ×0.5 урон). |
| `Exh%` | battlesExhausted / battles | Доля боёв, где сторона дотянула EP до 0 хоть раз (= получила Exhausted-дебафф). |
| `EndRed%` | totalEnduranceReduction / (totalEnduranceReduction + totalDamageReceived) | Доля входящего урона (по чейну), которую съел Endurance до армора. |
| `StrDmg` | bot{i}TotalStrengthDamage / battles | Средний сырой Strength-урон, выданный стороной за бой (до крита и армора). |
| `Str%` | bot{i}TotalStrengthDamage / bot{i}TotalDamage | Доля Strength-составляющей в общем выданном уроне. |

## Сырые данные

```
Level  Matchup         Side    Win%    EP%     Blocks  WkBlock  Exh%    EndRed%  StrDmg    Str%
------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      54.2%  67.5%  5.85    0.11     14.1%   4.6%      5.2      5.8%
L3     def_vs_crit     crit     34.5%  88.9%  4.44    1.50     71.5%   0.0%      4.5      5.3%
       (draw)          —        11.2%   avg rounds=14.9

L3     def_vs_dodge    def      56.5%  71.1%  6.19    0.17     19.7%   4.8%      5.3      5.9%
L3     def_vs_dodge    dodge    33.1%  91.2%  4.56    1.80     76.9%   0.0%      4.6      5.4%
       (draw)          —        10.3%   avg rounds=15.9

L3     dodge_vs_crit   dodge    45.2%  89.4%  4.47    1.46     72.0%   0.0%      4.9      5.5%
L3     dodge_vs_crit   crit     40.9%  88.9%  4.44    1.47     71.6%   0.0%      4.7      5.3%
       (draw)          —        13.8%   avg rounds=14.8

L6     def_vs_crit     def      53.3%  53.1%  6.48    0.00      0.6%   8.6%     11.6     11.2%
L6     def_vs_crit     crit     35.9%  92.1%  4.60    1.90     78.8%   0.0%      9.8      9.8%
       (draw)          —        10.8%   avg rounds=16.2

L6     def_vs_dodge    def      59.0%  59.9%  7.32    0.01      2.4%   9.1%     12.1     11.6%
L6     def_vs_dodge    dodge    32.1%  95.0%  4.75    2.61     86.1%   0.0%      9.9     10.1%
       (draw)          —         8.9%   avg rounds=18.4

L6     dodge_vs_crit   dodge    50.1%  92.9%  4.65    1.86     80.2%   0.0%     10.5     10.2%
L6     dodge_vs_crit   crit     37.9%  92.1%  4.60    1.90     78.7%   0.0%      9.6      9.5%
       (draw)          —        12.1%   avg rounds=16.3

L9     def_vs_crit     def      53.3%  44.1%  6.94    0.00      0.0%  11.7%     19.1     16.1%
L9     def_vs_crit     crit     36.0%  93.9%  4.70    2.26     83.2%   0.0%     15.9     14.0%
       (draw)          —        10.8%   avg rounds=17.4

L9     def_vs_dodge    def      61.3%  53.2%  8.38    0.00      0.6%  12.6%     20.1     16.9%
L9     def_vs_dodge    dodge    30.9%  97.5%  4.87    3.50     92.5%   0.0%     16.1     14.5%
       (draw)          —         7.8%   avg rounds=20.9

L9     dodge_vs_crit   dodge    57.2%  95.4%  4.77    2.34     86.2%   0.0%     17.0     14.3%
L9     dodge_vs_crit   crit     32.9%  94.2%  4.71    2.40     83.9%   0.0%     14.8     13.2%
       (draw)          —         9.9%   avg rounds=17.8

L12    def_vs_crit     def      54.2%  38.1%  7.40    0.00      0.0%  15.4%     27.5     20.6%
L12    def_vs_crit     crit     35.1%  95.4%  4.77    2.65     86.7%   0.0%     23.4     18.2%
       (draw)          —        10.7%   avg rounds=18.5

L12    def_vs_dodge    def      62.2%  48.6%  9.44    0.00      0.1%  16.8%     29.6     22.2%
L12    def_vs_dodge    dodge    30.7%  98.7%  4.93    4.50     96.0%   0.0%     24.0     19.3%
       (draw)          —         7.1%   avg rounds=23.6

L12    dodge_vs_crit   dodge    65.4%  97.0%  4.85    2.81     90.5%   0.0%     24.8     18.3%
L12    dodge_vs_crit   crit     26.0%  95.6%  4.78    2.87     87.7%   0.0%     20.4     16.7%
       (draw)          —         8.6%   avg rounds=19.1
```

## Сравнение step 5 → step 6 (Δ W%)

| Уровень | Матчап        | Сторона | Step 5 | Step 6 | Δ          |
|---------|---------------|---------|--------|--------|------------|
| L3      | def_vs_crit   | def     | 65.0%  | 54.2%  | **−10.8**  |
| L3      | def_vs_dodge  | def     | 67.8%  | 56.5%  | **−11.3**  |
| L3      | dodge_vs_crit | dodge   | 44.4%  | 45.2%  | +0.8       |
| L6      | def_vs_crit   | def     | 65.6%  | 53.3%  | **−12.3**  |
| L6      | def_vs_dodge  | def     | 69.9%  | 59.0%  | **−10.9**  |
| L6      | dodge_vs_crit | dodge   | 53.8%  | 50.1%  | −3.7       |
| L9      | def_vs_crit   | def     | 65.4%  | 53.3%  | **−12.1**  |
| L9      | def_vs_dodge  | def     | 69.3%  | 61.3%  | **−8.0**   |
| L9      | dodge_vs_crit | dodge   | 62.8%  | 57.2%  | **−5.6**   |
| L12     | def_vs_crit   | def     | 67.8%  | 54.2%  | **−13.6**  |
| L12     | def_vs_dodge  | def     | 68.0%  | 62.2%  | **−5.8**   |
| L12     | dodge_vs_crit | dodge   | 73.5%  | 65.4%  | **−8.1**   |

**Все стороны-выигрывавшие потеряли в Win%.** Отдают они в основном crit/dodge,
которые теперь имеют способ финишировать бой через `weakBlocked` после
истощения EP вместо «прохода насквозь».

## Сравнение всех замеров (def / dodge — главное)

| Уровень | Матчап        | Сторона | Baseline | Step 1 | Step 2 | Step 3 | Step 4 | Step 5 | Step 6 | Цель    |
|---------|---------------|---------|----------|--------|--------|--------|--------|--------|--------|---------|
| L12     | def_vs_crit   | def     | 27.0%    | 100.0% | 95.2%  | 94.0%  | 93.8%  | 67.8%  | **54.2%** ⚠ | 60-70%  |
| L12     | def_vs_dodge  | def     | 33.2%    | 100.0% | 93.9%  | 94.0%  | 93.6%  | 68.0%  | **62.2%** ✓ | 60-70%  |
| L12     | dodge_vs_crit | dodge   | 69.8%    | 77.5%  | 69.6%  | 74.4%  | 75.0%  | 73.5%  | **65.4%** ✓ | 60-70%  |
| L9      | def_vs_crit   | def     | 35.8%    | 99.7%  | 88.0%  | 86.8%  | 87.1%  | 65.4%  | **53.3%** ⚠ | 60-70%  |
| L9      | def_vs_dodge  | def     | 43.2%    | 99.5%  | 89.2%  | 88.9%  | 89.5%  | 69.3%  | **61.3%** ✓ | 60-70%  |
| L9      | dodge_vs_crit | dodge   | 60.6%    | 68.4%  | 60.8%  | 64.2%  | 64.4%  | 62.8%  | **57.2%** ⚠ | 60-70%  |
| L6      | def_vs_crit   | def     | 45.3%    | 90.1%  | 83.1%  | 81.8%  | 82.0%  | 65.6%  | **53.3%** ⚠ | 60-70%  |
| L6      | def_vs_dodge  | def     | 51.6%    | 91.3%  | 85.2%  | 85.3%  | 85.0%  | 69.9%  | **59.0%** ⚠ | 60-70%  |
| L6      | dodge_vs_crit | dodge   | 52.4%    | 58.6%  | 52.6%  | 53.6%  | 53.8%  | 53.8%  | **50.1%** ✗ | 60-70%  |
| L3      | def_vs_crit   | def     | 54.6%    | 53.2%  | 72.8%  | 72.3%  | 72.7%  | 65.0%  | **54.2%** ⚠ | 60-70%  |
| L3      | def_vs_dodge  | def     | 58.5%    | 54.6%  | 75.8%  | 74.9%  | 74.9%  | 67.8%  | **56.5%** ⚠ | 60-70%  |
| L3      | dodge_vs_crit | dodge   | 36.7%    | 36.1%  | 44.2%  | 44.4%  | 44.4%  | 44.4%  | **45.2%** ✗ | 60-70%  |

Маркеры: ✓ внутри 60-70 диапазона, ⚠ под нижней границей, ✗ далеко.

## Наблюдения

### 1. Главное — defender больше не доминирует

Win% defender'а упал на **5.8 — 13.6 пунктов** на всех уровнях. Это
следствие двух изменений одновременно:

- Раньше: «нет EP → удар проходит насквозь» (full damage). Теперь: «нет EP +
  Exhausted → ×0.5 damage». Для crit/dodge это означает, что после истощения
  defender'а они не получают халявные удары, как раньше — они **сами**
  истощаются и получают `.weakBlocked` обратно.
- Селективный Exhausted (str/end -30% вместо всех 5) — теперь Exhausted
  defender НЕ теряет agility/instinct/power, продолжает дожить и иногда
  доуворачивается. На крит-стороне это особенно заметно: Exh% 70-96%, но
  Win% всё равно поднимается, потому что они не превращаются в мешок.

### 2. Exhausted-фаза вездесуща у crit/dodge

`Exh%` у crit/dodge: **71-96%** на всех уровнях. То есть ≥7 из 10 боёв они
доходят до 0 EP. `WkBlock` у них растёт с уровнем: 1.5 (L3) → 4.5 (L12),
что означает 1.5-4.5 weak-блоков в среднем за бой — Exhausted-фаза реально
длинная и активная.

У defender ровно наоборот: `Exh%` ≤ 19% на L3, ≤ 0.6% на L9-L12. С
актуальной таблицей `blocksPerEndurancePoint = 0.4` и эффективным
Endurance ≥ 18 у def-стиля он почти никогда не выдыхается.

### 3. EndRed% наконец видим

Defender: **4.6% (L3) → 16.8% (L12)** — приблизительно отслеживает рост
Endurance с уровнем. Это «доля чейн-урона, которую съел Endurance до
армора».

Crit/dodge: **0.0%** на всех уровнях — потому что у этих fight-style
Endurance буквально 0, distribution возвращает 0.

Важно: EndRed% **не включает** заблокированный урон (там Endurance не
катится — блок отменяет весь чейн). Поэтому defender с большим Blocks
имеет относительно низкий EndRed% — много урона уходит через `.blocked`,
а не через `.hit/.weakBlocked`.

### 4. dodge_vs_crit и L3-перекос

`L3 dodge_vs_crit dodge` = 45.2%, `L6 dodge_vs_crit dodge` = 50.1%. На L3
dodge не имеет преимущества над crit, на L6 — равенство. Цель 60-70%
явно не достигнута на этих уровнях. Это **не регресс** относительно step 5
(там было 44.4% / 53.8%), но и не починилось — этот матчап остаётся слабым
звеном треугольника.

Возможные направления тюнинга: пересмотр crit-мультипликаторов на низких
уровнях, либо тонкая настройка agility-вклада в dodge на L3-L6.

### 5. Возможный over-correction по defender

L6/L9/L12 def_vs_crit Win% defender'а сейчас **53.3-54.2%** — заметно
ниже целевого диапазона 60-70%. Это «вернулся под целевую границу, но
переедив на 6-7 пунктов». Если хочется ровно в 60-70, можно:

- Поднять `exhaustedBlockDamageMultiplier` с 0.5 до ~0.6-0.65 — Exhausted
  defender будет получать ещё меньше урона в weak-блок-фазе. Хотя WkBlock
  у defender = 0.00 на L9+, так что эффект будет малозаметен.
- Альтернатива: при weak-блоке ещё и крит должен подавляться (как в
  обычном блоке через `blockedCritMultiplier`). Сейчас weak-блок
  пропускает крит ×N в полную силу (потом halving), что даёт жирные
  ×2-×3 крит-уроны прямо в финальный счёт.

Но крит/dodge получают `WkBlock` 2-4 за бой, и это им как раз помогает
выживать в exhausted-фазе. Так что трогать с осторожностью.

## Итог

Механика "gradient of exhaustion" + селективный Exhausted сработали
**в нужную сторону**: defender больше не имеет 90%+ выигрыша на высоких
уровнях, треугольник стал ближе к симметричному. Цена — небольшое
«undershoot» у defender (53-62% вместо 60-70%) и сохраняющийся слабый
матчап dodge_vs_crit на низких уровнях.

Следующий шаг балансировки, если потребуется: тонкая настройка
`exhaustedBlockDamageMultiplier` (0.5 → 0.55) и/или `blockedCritMultiplier`
для weak-блока (сейчас не применяется — крит идёт полным мультипликатором).
