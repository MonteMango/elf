# Triangle Win-Rate Sweep — post blocked-crit weighted dist + blocksPerEndurance 0.3 step 8 (2026-05-26)

**Замер после двух одновременных изменений: (а) blocked-crit multiplier
теперь катится из взвешенного распределения вместо константы 1.0×;
(б) `blocksPerEndurancePoint` понижен 0.4 → 0.3.**

## Что изменилось со step 7

**Изменение 1 — blocked-crit multiplier из распределения.**
`GameMechanicsConstants.swift`:

```swift
static let blockedCritMultiplierWeights: [Int] = [5, 50, 40, 5, 0, 0]
// Парные значения: [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]
// Mean = 0.05·0.75 + 0.5·1.0 + 0.4·1.25 + 0.05·1.5 = 1.1125×
```

Раньше каждый крит после блока скейлился ровно `× 1.0`. Теперь катится
из распределения: 50% случаев — 1.0×, 40% — 1.25×, по 5% — 0.75× и 1.5×;
2.0× и 3.0× закрыты (вес 0). Среднее **+11.25 %** урона по чейну на
blocked-критах.

Реализовано через:
- Новый метод `CritService.selectBlockedCritMultiplier()`.
- `ElfCritService` переиспользует приватный `selectMultiplier(critSuccess:from:)`
  с `CritMultiplierDistribution(values: critMultiplierValues, weights:
  blockedCritMultiplierWeights)`.
- `ElfSnapshotCombatCalculator.resolveSuccessfulBlock` дёргает сервис
  вместо чтения константы.

**Изменение 2 — `blocksPerEndurancePoint: 0.4 → 0.3`.**
Endurance теперь даёт меньше «бесплатных блоков»: каждый поинт прибавляет
0.3 эффективных блока к пулу вместо 0.4. Формула:

```
cost = pool / (pool/baseCost + endurance × blocksPerEndurancePoint)
```

При неизменных `startingEP = 2400` и `baseCost = 200` нерф особенно
заметен у высоко-Endurance defender'а: блок дороже → меньше абсолютных
блоков за бой при том же EP пуле.

**Изменение 3 — новые колонки в принтере** (`Crit%`, `Dodge%`).
См. секцию «Справка по колонкам» ниже.

## Методика

Headless `BattleSimulationIntegrationTests.testStyleTriangleSweep`,
**30 000** битв × **12** конфигов. Wall clock **134.3s** — в пределах
шума relativaly to step 7 (133.5s).

## Справка по колонкам

Каждая строка — одна сторона боя.

| Колонка | Формула | Смысл |
|---------|---------|-------|
| `Win%` | wins / battles | Доля выигранных боёв стороной. |
| `EP%` | totalEPSpent / battles / maxEP | Средний расход EP за бой как доля пула (2400). |
| `Blocks` | totalBlocksUsed / battles | Полноценные блоки за бой (`.blocked` + `.critHit` с epSpent > 0). |
| `WkBlock` | totalWeakBlocksUsed / battles | Weak-блоки за бой (Exhausted+EP=0, ×0.5 урон). |
| `Exh%` | battlesExhausted / battles | Доля боёв, где сторона хоть раз исчерпала EP → получила Exhausted. |
| `EndRed%` | totalEnduranceReduction / (totalEnduranceReduction + totalDamageReceived) | Доля чейн-урона, поглощённая Endurance до армора. |
| **`Crit%`** | bot{i}CritSuccesses / bot{i}CritAttempts | *Оффенсивная* доля успешных критов этой стороны. |
| **`Dodge%`** | bot{i}DodgeSuccesses / bot{i}DodgeAttempts | *Дефенсивная* доля успешных уворотов этой стороны. |
| `StrDmg` | bot{i}TotalStrengthDamage / battles | Средний сырой Strength-урон выданный стороной за бой. |
| `Str%` | bot{i}TotalStrengthDamage / bot{i}TotalDamage | Доля Strength-составляющей в выданном уроне. |

## Сырые данные

```
Level  Matchup         Side    Win%    EP%     Blocks  WkBlock  Exh%    EndRed%  Crit%   Dodge%  StrDmg    Str%
----------------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      49.5%  61.8%  5.97    0.05      7.8%   4.6%     0.0%    0.0%     5.0      5.7%
L3     def_vs_crit     crit     39.7%  83.7%  5.02    0.97     56.9%   0.0%     7.1%    0.0%     4.6      5.3%
       (draw)          —        10.8%   avg rounds=15.0

L3     def_vs_dodge    def      52.2%  65.6%  6.34    0.09     11.7%   4.8%     0.0%    0.0%     5.1      5.7%
L3     def_vs_dodge    dodge    37.6%  86.4%  5.18    1.24     63.3%   0.0%     0.0%    7.1%     4.7      5.5%
       (draw)          —        10.2%   avg rounds=16.1

L3     dodge_vs_crit   dodge    45.0%  84.1%  5.05    0.94     57.4%   0.0%     0.0%    9.6%     4.8      5.5%
L3     dodge_vs_crit   crit     43.0%  83.5%  5.01    0.95     56.5%   0.0%     9.6%    0.0%     4.6      5.2%
       (draw)          —        12.0%   avg rounds=15.0

L6     def_vs_crit     def      46.9%  49.6%  6.54    0.00      0.3%   8.5%     0.0%    0.0%    11.1     10.9%
L6     def_vs_crit     crit     42.6%  87.8%  5.27    1.30     65.7%   0.0%    13.8%    0.0%    10.1     10.0%
       (draw)          —        10.5%   avg rounds=16.4

L6     def_vs_dodge    def      53.7%  56.4%  7.45    0.01      1.3%   9.1%     0.0%    0.0%    11.5     11.2%
L6     def_vs_dodge    dodge    37.4%  91.9%  5.51    1.92     76.2%   0.0%     0.0%   13.9%    10.4     10.5%
       (draw)          —         8.9%   avg rounds=18.6

L6     dodge_vs_crit   dodge    47.9%  88.5%  5.31    1.28     66.5%   0.0%     0.0%   19.2%    10.5     10.2%
L6     dodge_vs_crit   crit     41.4%  87.6%  5.26    1.33     65.7%   0.0%    19.1%    0.0%     9.6      9.5%
       (draw)          —        10.7%   avg rounds=16.5

L9     def_vs_crit     def      45.4%  41.7%  7.00    0.00      0.0%  11.6%     0.0%    0.0%    18.1     15.6%
L9     def_vs_crit     crit     43.9%  90.1%  5.41    1.57     71.6%   0.0%    20.6%    0.0%    16.6     14.3%
       (draw)          —        10.7%   avg rounds=17.5

L9     def_vs_dodge    def      54.4%  50.4%  8.46    0.00      0.3%  12.6%     0.0%    0.0%    19.3     16.5%
L9     def_vs_dodge    dodge    37.7%  95.3%  5.72    2.75     85.4%   0.0%     0.0%   20.6%    17.0     15.0%
       (draw)          —         7.9%   avg rounds=21.2

L9     dodge_vs_crit   dodge    53.1%  91.8%  5.51    1.67     74.4%   0.0%     0.0%   28.5%    17.0     14.5%
L9     dodge_vs_crit   crit     37.1%  90.5%  5.43    1.73     72.8%   0.0%    28.5%    0.0%    14.8     13.1%
       (draw)          —         9.8%   avg rounds=17.9

L12    def_vs_crit     def      45.4%  36.7%  7.46    0.00      0.0%  15.1%     0.0%    0.0%    26.2     20.1%
L12    def_vs_crit     crit     44.1%  92.1%  5.53    1.92     76.4%   0.0%    27.4%    0.0%    24.3     18.5%
       (draw)          —        10.5%   avg rounds=18.6

L12    def_vs_dodge    def      55.2%  47.1%  9.57    0.00      0.0%  16.7%     0.0%    0.0%    28.2     21.5%
L12    def_vs_dodge    dodge    37.4%  97.7%  5.86    3.74     92.2%   0.0%     0.0%   27.6%    25.2     19.8%
       (draw)          —         7.4%   avg rounds=24.0

L12    dodge_vs_crit   dodge    59.6%  94.4%  5.67    2.05     81.0%   0.0%     0.0%   37.8%    24.6     18.5%
L12    dodge_vs_crit   crit     31.9%  92.6%  5.56    2.15     78.4%   0.0%    37.9%    0.0%    20.4     16.5%
       (draw)          —         8.5%   avg rounds=19.3
```

## Сравнение step 7 → step 8 (Δ W%)

| Уровень | Матчап        | Сторона | Step 7 | Step 8 | Δ        |
|---------|---------------|---------|--------|--------|----------|
| L3      | def_vs_crit   | def     | 50.5%  | 49.5%  | −1.0     |
| L3      | def_vs_dodge  | def     | 52.8%  | 52.2%  | −0.6     |
| L3      | dodge_vs_crit | dodge   | 45.5%  | 45.0%  | −0.5     |
| L6      | def_vs_crit   | def     | 48.9%  | 46.9%  | **−2.0** |
| L6      | def_vs_dodge  | def     | 54.0%  | 53.7%  | −0.3     |
| L6      | dodge_vs_crit | dodge   | 48.5%  | 47.9%  | −0.6     |
| L9      | def_vs_crit   | def     | 47.1%  | 45.4%  | **−1.7** |
| L9      | def_vs_dodge  | def     | 54.5%  | 54.4%  | −0.1     |
| L9      | dodge_vs_crit | dodge   | 55.1%  | 53.1%  | **−2.0** |
| L12     | def_vs_crit   | def     | 48.0%  | 45.4%  | **−2.6** |
| L12     | def_vs_dodge  | def     | 54.9%  | 55.2%  | +0.3     |
| L12     | dodge_vs_crit | dodge   | 62.7%  | 59.6%  | **−3.1** |

Изменение умеренное: defender и dodge просели на 0-3 пункта Win% на
большинстве слайсов. Сильнее всего пострадали:
- **def_vs_crit** на L6/L9/L12 (−1.7..−2.6) — критическая комбинация
  обоих изменений: blocked-crit теперь срезает чуть больше HP + блок
  стал чуть дороже у defender'а.
- **dodge_vs_crit dodge** на L9/L12 (−2.0/−3.1) — но и здесь это
  скорее «возврат к симметрии», см. наблюдение 3.

## Сравнение всех замеров (главное)

| Уровень | Матчап        | Сторона | Baseline | Step 5 | Step 6 | Step 7 | Step 8 | Цель    |
|---------|---------------|---------|----------|--------|--------|--------|--------|---------|
| L12     | def_vs_crit   | def     | 27.0%    | 67.8%  | 54.2%  | 48.0%  | **45.4%** ✗ | 60-70%  |
| L12     | def_vs_dodge  | def     | 33.2%    | 68.0%  | 62.2%  | 54.9%  | **55.2%** ⚠ | 60-70%  |
| L12     | dodge_vs_crit | dodge   | 69.8%    | 73.5%  | 65.4%  | 62.7%  | **59.6%** ⚠ | 60-70%  |
| L9      | def_vs_crit   | def     | 35.8%    | 65.4%  | 53.3%  | 47.1%  | **45.4%** ✗ | 60-70%  |
| L9      | def_vs_dodge  | def     | 43.2%    | 69.3%  | 61.3%  | 54.5%  | **54.4%** ⚠ | 60-70%  |
| L9      | dodge_vs_crit | dodge   | 60.6%    | 62.8%  | 57.2%  | 55.1%  | **53.1%** ⚠ | 60-70%  |
| L6      | def_vs_crit   | def     | 45.3%    | 65.6%  | 53.3%  | 48.9%  | **46.9%** ✗ | 60-70%  |
| L6      | def_vs_dodge  | def     | 51.6%    | 69.9%  | 59.0%  | 54.0%  | **53.7%** ⚠ | 60-70%  |
| L6      | dodge_vs_crit | dodge   | 52.4%    | 53.8%  | 50.1%  | 48.5%  | **47.9%** ✗ | 60-70%  |
| L3      | def_vs_crit   | def     | 54.6%    | 65.0%  | 54.2%  | 50.5%  | **49.5%** ⚠ | 60-70%  |
| L3      | def_vs_dodge  | def     | 58.5%    | 67.8%  | 56.5%  | 52.8%  | **52.2%** ⚠ | 60-70%  |
| L3      | dodge_vs_crit | dodge   | 36.7%    | 44.4%  | 45.2%  | 45.5%  | **45.0%** ✗ | 60-70%  |

Маркеры: ✓ внутри 60-70 диапазона, ⚠ под нижней границей, ✗ далеко.

## Наблюдения

### 1. Defender дальше уходит от цели 60-70 %

Все def-ячейки сейчас на 45.4 — 55.2 %. На def_vs_crit L6+ defender уже
**проигрывает чаще, чем выигрывает** в среднем (45-47 %). Это совместный
эффект двух изменений:

- **blocked-crit weighted** — каждый удачно заблокированный крит атакующего
  теперь в среднем `×1.1125`. Особенно сильно бьёт по L9/L12, где
  абсолютные значения weaponDamage большие.
- **blocksPerEndurancePoint 0.3** — defender с большим Endurance теряет
  часть скидки на блок. Видно в `Blocks` defender'а: L12 def_vs_dodge
  step 7: 9.44 → step 8: 9.57 (+0.13, мизер). А вот у crit/dodge сторон
  Blocks тоже подросли (см. ниже), и они не платят за это столько же
  Endurance.

### 2. Новые колонки `Crit%` / `Dodge%` сразу подсвечивают перекос

Главное в новых колонках — **`def` сторона всегда показывает 0.0% / 0.0%**.
Это потому что fight-style таблица назначает `Power = 0` и `Agility = 0`
для def-стиля. Соответственно:
- Crit: `selectedChance = power - opponentInstinct = 0 - X ≤ 0` → auto-fail.
- Dodge: `agility = 0` → нижний край распределения, в большинстве боёв
  ролл уходит в auto-fail или близко.

Это **архитектурное наблюдение, не баг**: def построен на блоке + Endurance,
не должен критовать или уворачиваться. Но в принтере 0.0%/0.0% теперь
явно показывает, что def-сторона никогда не получает «случайного буста»
от crit или dodge — её Win% полностью держится на Endurance × Blocks.

### 3. dodge_vs_crit стал почти идеально симметричным

На L9 и L12 у `dodge` и `crit` практически одинаковые Crit%/Dodge%:

| Уровень | crit.Crit% | dodge.Dodge% | Разница |
|---------|-----------|--------------|---------|
| L3      | 9.6%      | 9.6%         | 0       |
| L6      | 19.1%     | 19.2%        | 0.1     |
| L9      | 28.5%     | 28.5%        | 0       |
| L12     | 37.9%     | 37.8%        | 0.1     |

Это структурное свойство: fight-style attribute table выдаёт crit и dodge
одинаковые «primary» статы (один → Power, другой → Agility), поэтому
формулы crit-chance и dodge-chance симметричны.

Win% распределяется при этом неравномерно (например L12 dodge 59.6%
vs crit 31.9%): dodge **получает оба бонуса**: уворот + блок (defense
points > attack points у dodge-стиля), а crit полагается на крит без
надёжной защиты. Победители-через-Win% получают тот же шанс на
сработку crit/dodge — но конвертируют его в выигрыш по-разному.

### 4. Crit%/Dodge% растут с уровнем

| Уровень | crit.Crit% | dodge.Dodge% |
|---------|-----------|--------------|
| L3      | 7-10%     | 7-10%        |
| L6      | 14-19%    | 14-19%       |
| L9      | 21-29%    | 21-29%       |
| L12     | 27-38%    | 28-38%       |

Линейный (почти) рост — Power/Agility растут с уровнем, и crit/dodge
chance вместе с ним. Это **ожидаемое поведение**: на L12 crit-стиль
делает крит в каждой 3-й попытке, dodge уворачивается каждой 3-й.

### 5. EndRed% и Crit% complementary показатели урона

На L12 def_vs_crit:
- crit.Crit% = 27.4% — каждый 4-й удар крит.
- def.EndRed% = 15.1% — каждое 7-е HP из чейн-урона съедено Endurance.

Сравнение: Endurance даёт defender'у ~15% «защитной экономии», crit даёт
attacker'у ~27% попыток с 1.5×+ damage. Грубо: crit attacker'а статистически
обходит Endurance defender'а почти в 2 раза по эффективному вкладу.
Что и видим в Win% (45 vs 44).

### 6. Blocks для crit/dodge сторон выросли

Это не из-за блока-меняющих изменений, а из-за `blocksPerEndurancePoint
0.3`: формула `cost = pool / (pool/baseCost + endurance × 0.3)`. У сторон
с Endurance = 0 (crit/dodge) `pool/baseCost = 2400/200 = 12`, поэтому
`cost = 2400/12 = 200` — ровно baseCost. То есть **crit/dodge всегда
платят baseCost (=200) за блок при любом значении `blocksPerEndurancePoint`**
(пока их Endurance = 0). И при пуле 2400 они могут сделать максимум
12 блоков за бой против ~9-10 раньше (при пуле 2000).

Видно в `Blocks` колонке: crit/dodge поднялись с 4.44-4.85 (step 6,
пул 2000) до 5.01-5.86 (step 8, пул 2400 + 0.3). У defender же `Blocks`
почти не изменилось (он не упирался в пул).

## Итог

Текущий баланс: defender проиграл главенство, crit/dodge подтянулись
почти к равенству. Из 12 ячеек **только 0 ✓** внутри целевых 60-70%,
4 ⚠ (под границей), 8 ✗ (далеко). Если цель — defender 60-70%,
**направление движения от step 5 неправильное** уже четвёртый шаг
подряд: 67.8 → 65.6 → 54.2 → 48.0 → 45.4 на L12 def_vs_crit.

Если цель симметричный треугольник 50/50/50 — текущее состояние ближе
всего к этому (большинство ячеек 45-55%), но всё ещё с двумя выбросами:
**dodge_vs_crit dodge на L12 = 59.6%** (легкий перекос dodge>crit) и
**def_vs_crit def на L9/L12 = 45.4%** (легкий перекос crit>def).

## Возможные следующие шаги

Если цель **вернуть defender в 60-70%**:

1. **Откатить `blocksPerEndurancePoint` к 0.4 или 0.5** — restore Endurance
   value, defender снова получает большую скидку на блок.

2. **Урезать `blockedCritMultiplierWeights`**, например
   `[10, 60, 30, 0, 0, 0]` (mean ≈ 0.95×). Это убьёт buff атакующему
   через blocked-крит. Альтернатива — `[5, 70, 25, 0, 0, 0]` (mean ≈
   0.9875).

3. **Понизить `startingEP` обратно к 2200 или 2000** — crit/dodge снова
   будут чаще исчерпываться.

4. **Поднять `exhaustedBlockDamageMultiplier`** с 0.5 → 0.6-0.7 —
   defender в weak-block фазе принимает меньше урона (хотя у него
   `WkBlock ≈ 0.00` на L6+, влияние мизерное).

Если цель **симметричный 50/50/50** — текущее состояние почти ОК, нужно
только тонко доводить:
- **dodge_vs_crit dodge на L12** = 59.6% — слегка нерфнуть dodge:
  понизить `dodgePeakWeight` или вес 1.5×/2.0× у `critMultiplierWeights`
  (crit reward сильнее).
- **def_vs_crit def на L9/L12** = 45.4% — слегка побустить defender
  без буста других def-матчапов: возможно, поднять
  `exhaustedBlockDamageMultiplier` 0.5 → 0.55 (помогает defender в
  Exhausted-сценариях, которых у него очень мало, но всё же).
