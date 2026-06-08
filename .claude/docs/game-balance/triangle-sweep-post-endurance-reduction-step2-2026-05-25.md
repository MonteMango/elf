# Triangle Win-Rate Sweep — post-endurance-reduction step 2 (2026-05-25)

**Замер после нерфа Endurance до 50% эффективности Strength.**

## Что изменилось со step 1

**Изменение в коде** (один файл, одна функция):
`Packages/elf_Kit/Sources/DataLayer/Services/Damage/Implementation/ElfEnduranceDamageReductionDistributionStrategy.swift`

```swift
// До (step 1): таблица 1:1 со Strength
public func distribution(for endurance: Int16) -> DamageDistribution {
    if let template = predefinedDistributions[endurance] { ... }
    return distributionForExtendedEndurance(endurance)
}

// После (step 2): lookup по halved индексу
public func distribution(for endurance: Int16) -> DamageDistribution {
    let halved = endurance / 2
    if halved < 1 {
        return DamageDistribution(values: [0], weights: [1])
    }
    if let template = predefinedDistributions[halved] { ... }
    return distributionForExtendedEndurance(halved)
}
```

Таблица сама не изменилась — только индекс при чтении. То есть endurance N
теперь использует строку, которой Strength пользуется для N/2.

**Средняя редукция на удар у def-стиля:**

| Уровень | Endurance | Step 1 mean | Step 2 mean | Δ        |
|---------|-----------|-------------|-------------|----------|
| L3      | 9         | ~1.5        | ~0.71       | −53%     |
| L6      | 18        | ~3.0        | ~1.0        | −67%     |
| L9      | 27        | ~4.5        | ~1.76       | −61%     |
| L12     | 36        | ~6.0        | ~3.0        | −50%     |

## Методика

- Headless `BattleSimulationIntegrationTests.testStyleTriangleSweep`
- **30 000 битв** на (level, matchup), **1 прогон**
- Уровни 3/6/9/12 × def_vs_crit / def_vs_dodge / dodge_vs_crit
- `includeRandomAttributes = off`, Recruit's Spear, без экипировки

Wall clock **148.3s** (vs step 1 = 182.5s, baseline = 136.9s — бои стали
короче, чем в step 1, но всё ещё длиннее baseline).

## Сырые данные

```
Level  Matchup         Side    Win%    EP%     Blocks  Fail %  AvgRound  %Through  StrDmg    Str%
------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      72.8%  62.0%  6.93     2.1% 17.5      95.1%        6.0      6.4%
L3     def_vs_crit     crit     18.5%  81.7%  5.45    61.6% 14.3      79.4%        5.5      6.7%
       (draw)          —         8.7%   avg rounds=17.4

L3     def_vs_dodge    def      75.8%  65.7%  7.34     4.0% 18.6      93.4%        6.0      6.4%
L3     def_vs_dodge    dodge    16.7%  83.3%  5.56    67.5% 14.7      77.7%        5.5      6.9%
       (draw)          —         7.5%   avg rounds=18.4

L3     dodge_vs_crit   dodge    45.0%  81.4%  5.43    57.5% 14.1      80.4%        5.8      6.4%
L3     dodge_vs_crit   crit     36.7%  81.1%  5.41    57.3% 14.1      80.3%        5.5      6.1%
       (draw)          —        18.2%   avg rounds=17.0

L6     def_vs_crit     def      83.1%  48.1%  7.52     0.0% 19.3      98.4%       13.2     12.1%
L6     def_vs_crit     crit     10.6%  84.0%  5.60    69.6% 14.9      77.3%       12.3     13.6%
       (draw)          —         6.3%   avg rounds=18.8

L6     def_vs_dodge    def      85.2%  53.8%  8.41     0.3% 23.1      95.5%       13.2     12.1%
L6     def_vs_dodge    dodge     9.7%  86.2%  5.75    79.7% 15.6      73.2%       12.6     14.3%
       (draw)          —         5.1%   avg rounds=21.0

L6     dodge_vs_crit   dodge    52.6%  83.8%  5.59    64.6% 14.6      78.4%       12.6     12.0%
L6     dodge_vs_crit   crit     33.5%  83.2%  5.55    65.2% 14.6      78.2%       11.2     11.1%
       (draw)          —        13.8%   avg rounds=18.2

L9     def_vs_crit     def      88.0%  39.3%  7.95     0.0% —         —           21.3     17.2%
L9     def_vs_crit     crit      7.4%  85.3%  5.69    75.5% 15.2      75.4%       20.4     20.4%
       (draw)          —         4.7%   avg rounds=19.9

L9     def_vs_dodge    def      89.2%  47.0%  9.49     0.0% 27.5      98.1%       21.3     17.2%
L9     def_vs_dodge    dodge     7.4%  88.2%  5.88    88.6% 16.3      68.4%       21.4     21.9%
       (draw)          —         3.5%   avg rounds=23.8

L9     dodge_vs_crit   dodge    60.8%  85.7%  5.71    71.2% 15.0      76.5%       20.5     17.0%
L9     dodge_vs_crit   crit     28.3%  85.0%  5.66    71.8% 15.1      76.4%       17.1     15.3%
       (draw)          —        10.9%   avg rounds=19.3

L12    def_vs_crit     def      95.2%  33.9%  8.37     0.0% —         —           30.3     21.7%
L12    def_vs_crit     crit      2.6%  86.4%  5.76    80.5% 15.6      73.6%       29.7     27.9%
       (draw)          —         2.2%   avg rounds=20.9

L12    def_vs_dodge    def      93.9%  43.4% 10.71     0.0% 36.0      100.0%      30.3     21.7%
L12    def_vs_dodge    dodge     4.3%  89.2%  5.94    94.3% 16.8      63.0%       32.1     30.8%
       (draw)          —         1.8%   avg rounds=26.8

L12    dodge_vs_crit   dodge    69.6%  86.9%  5.79    76.9% 15.4      74.7%       29.3     21.6%
L12    dodge_vs_crit   crit     22.2%  86.1%  5.74    76.9% 15.4      74.4%       22.5     18.8%
       (draw)          —         8.2%   avg rounds=20.4
```

## Сравнение всех трёх замеров (W% по сторонам)

Цель: победитель **60-70%**, ничья **0-10%**, проигравший **30-40%**.

| Уровень | Матчап       | Сторона | Baseline | Step 1 | Step 2 | Цель    |
|---------|--------------|---------|----------|--------|--------|---------|
| L3      | def_vs_crit  | def     | 54.6%    | 53.2%  | **72.8%** | 60-70%  |
| L3      | def_vs_crit  | crit    | 34.5%    | 36.9%  | 18.5%  | 30-40%  |
| L3      | def_vs_dodge | def     | 58.5%    | 54.6%  | **75.8%** | 60-70%  |
| L3      | def_vs_dodge | dodge   | 31.6%    | 34.8%  | 16.7%  | 30-40%  |
| L3      | dodge_vs_crit| dodge   | 44.2%    | 48.6%  | 45.0%  | 60-70%  |
| L3      | dodge_vs_crit| crit    | 37.5%    | 33.9%  | 36.7%  | 30-40%  |
| L6      | def_vs_crit  | def     | 45.3%    | 90.1%  | **83.1%** | 60-70%  |
| L6      | def_vs_crit  | crit    | 43.8%    | 6.1%   | 10.6%  | 30-40%  |
| L6      | def_vs_dodge | def     | 51.6%    | 91.3%  | **85.2%** | 60-70%  |
| L6      | def_vs_dodge | dodge   | 39.3%    | 5.8%   | 9.7%   | 30-40%  |
| L6      | dodge_vs_crit| dodge   | 52.4%    | 58.6%  | 52.6%  | 60-70%  |
| L6      | dodge_vs_crit| crit    | 33.7%    | 29.0%  | 33.5%  | 30-40%  |
| L9      | def_vs_crit  | def     | 35.8%    | 99.7%  | **88.0%** | 60-70%  |
| L9      | def_vs_crit  | crit    | 53.4%    | 0.2%   | 7.4%   | 30-40%  |
| L9      | def_vs_dodge | def     | 43.2%    | 99.5%  | **89.2%** | 60-70%  |
| L9      | def_vs_dodge | dodge   | 48.7%    | 0.3%   | 7.4%   | 30-40%  |
| L9      | dodge_vs_crit| dodge   | 60.6%    | 68.4%  | 60.8%  | 60-70%  |
| L9      | dodge_vs_crit| crit    | 28.6%    | 22.7%  | 28.3%  | 30-40%  |
| L12     | def_vs_crit  | def     | 27.0%    | 100.0% | **95.2%** | 60-70%  |
| L12     | def_vs_crit  | crit    | 63.3%    | 0.0%   | 2.6%   | 30-40%  |
| L12     | def_vs_dodge | def     | 33.2%    | 100.0% | **93.9%** | 60-70%  |
| L12     | def_vs_dodge | dodge   | 59.6%    | 0.0%   | 4.3%   | 30-40%  |
| L12     | dodge_vs_crit| dodge   | 69.8%    | 77.5%  | 69.6%  | 60-70%  |
| L12     | dodge_vs_crit| crit    | 22.1%    | 16.3%  | 22.2%  | 30-40%  |

## Что получилось

### ✓ Работающее

1. **`dodge_vs_crit` вернулся к baseline** на всех уровнях — изменение не
   затронуло матчап, где у обеих сторон endurance 0. Подтверждение, что
   нерф действует только на сторону с endurance > 0.
2. **dodge_vs_crit при L9/L12 — попадает в коридор цели** (60.8% / 69.6%
   победа dodge). Эту грань больше двигать не нужно.
3. **EP-utilisation у def упала** (с 40.6% step 1 до 33.9% на L12) —
   значит, def теперь короче живёт, меньше блокирует. Бои стали короче
   (AvgRound 25.1 → 20.9).
4. **Step 2 короче по времени прогона** (148s vs 182s в step 1).

### ✗ Цель НЕ достигнута

**def-стиль всё ещё доминирует на всех уровнях.** Win rate на L12:
- def vs crit: **95.2%** (цель 60-70%, перебор +25-35 pp)
- def vs dodge: **93.9%** (цель 60-70%, перебор +24-34 pp)

И что важно — **L3 теперь тоже перевешен** (72.8% / 75.8% при цели
60-70% или ниже). Baseline L3 был в коридоре (54-58%), step 1 чуть-чуть
ниже (53-55%), step 2 — overshoot.

### Почему 50% нерфа недостаточно

Endurance создаёт **структурную асимметрию**: def имеет endurance 9-36 в
зависимости от уровня, а crit/dodge имеют **endurance 0** по level scaling.
Любая ненулевая редукция на стороне def vs нулевая на другой = накопленное
преимущество.

Цифры по hits:
- L3 def: mean redux ~0.71, ~12 hits/battle → save ~8.5 HP. При HP ~95-110 на L3 = +8-10% win rate.
- L12 def: mean redux ~3.0, ~14 hits/battle → save **~42 HP**. При HP 140 = почти 1/3 запаса HP бесплатно.

То есть даже половинный нерф оставляет огромный перевес у def — потому
что **противоположная сторона компенсирует это нулём**.

### Тренд по нерфам (L12 def_vs_crit def W%)

| Шаг        | Mean redux/hit | def W% L12 |
|------------|----------------|------------|
| Baseline   | 0              | 27.0%      |
| Step 1     | ~6.0           | 100.0%     |
| Step 2     | ~3.0           | 95.2%      |
| Цель       | ?              | 60-70%     |

Видно, что зависимость **нелинейная** — нерф редукции в 2 раза дал
снижение win rate всего на 4.8 pp. Чтобы попасть в коридор, нужно либо:
- сильнее урезать таблицу (mean ~0.5-1.0 на L12 endurance 36),
- либо **изменить форму механики** (cap, % от урона, scaling от уровня
  атакера/защитника, не флэт),
- либо ввести **компенсаторный буст** у crit/dodge (HP, sustain),
- либо привязать редукцию только к **блокированным частям**.

## Следующие итерации (предложения)

1. **Step 3a (тривиальный):** ещё разделить — `endurance / 3` или `/ 4`.
   На `/4` L12 def → table[9] mean=1.5. Линейная экстраполяция → ожидается
   def_vs_crit ~85-90%. Тоже скорее всего перебор, но дешёво проверить.
2. **Step 3b (по форме):** редукция применяется только если защитник
   потратил block point на эту часть тела. Уменьшает асимметрию: чтобы
   получить редукцию, def должен реально блокировать, что у него и так в
   стратегии — а нолевые-endurance стили остаются нетронутыми.
3. **Step 3c (% redaction):** заменить флэт-редукцию на множитель.
   Например `damage * (1 - endurance/200)` — на L12 endurance 36 даёт 18%
   снижения. По форме ближе к "armor scaling," не превращает удар в 0.

Рекомендация: попробовать (1) сначала (1 строка кода), потом перейти к
(3b) или (3c) если линейный делитель не справится.
