# Triangle Win-Rate Sweep — post weak-block + crit semantic fix step 10 (2026-05-26)

**Замер после правки семантики weak-block + crit. Раньше weak-блок против
крита: сырой crit-multiplier (`[1.0, 1.25, 1.5, 2.0, 3.0]`, mean ≈ 1.475)
плюс финальное `× 0.6`. Теперь: `selectBlockedCritMultiplier()`
(`[0.75, 1.0, 1.25, 1.5]` mean ≈ 1.1125), БЕЗ дополнительного `× 0.6`.
Никакого double-dip'a.**

## Что изменилось со step 9

**Изменение в коде** (`ElfSnapshotCombatCalculator.resolveWeakBlock`):

```swift
// Было (step 9): сырой crit, потом всё × 0.6
let multiplier = critResult.success ? critResult.selectedMultiplier : 1.0
let amplifiedWeapon = Int(Double(attackDamage) * multiplier)
let postArmorDamage = max(0, amplifiedWeapon + strengthDamage - enduranceReduction - defenderArmor)
let finalDamage = Int((Double(postArmorDamage) * 0.6).rounded(.down))

// Стало (step 10): crit-ветка — blocked-multiplier, БЕЗ × 0.6
if critResult.success {
    let mult = critService.selectBlockedCritMultiplier()  // [5,50,40,5,0,0] → 0.75..1.5
    let amplifiedWeapon = Int(Double(attackDamage) * mult)
    finalDamage = max(0, amplifiedWeapon + strengthDamage - enduranceReduction - defenderArmor)
} else {
    let postArmorDamage = max(0, attackDamage + strengthDamage - enduranceReduction - defenderArmor)
    finalDamage = Int((Double(postArmorDamage) * GameMechanicsConstants.exhaustedBlockDamageMultiplier).rounded(.down))
}
```

**Что это значит математически.** Берём weapon=10, str=5, end=0, armor=2:

| Ветка                     | Step 9 (mean) | Step 10 (mean) | Δ        |
|---------------------------|--------------:|---------------:|---------:|
| weak-block + no crit      | (10+5−2)·0.6 = **7.8** | (10+5−2)·0.6 = **7.8** | 0     |
| weak-block + crit         | (10·1.475 + 5 − 2)·0.6 ≈ **10.65** | 10·1.1125 + 5 − 2 ≈ **14.13** | **+33 %** |

То есть это **buff атакующему**, который крит-ит по Exhausted-защитнику.
No-crit ветка нетронута. Защитник в обычной фазе (когда EP > 0) тоже не
тронут — `resolveSuccessfulBlock` использовал `selectBlockedCritMultiplier()`
и раньше.

**Кого это бьёт.** Смотрим колонку `WkBlock` — у defender'а 0.00-0.08 за
бой, у crit/dodge — 0.93-3.61. Изменение бьёт **только** проигрывающие
weak-block-стороны, и **сильнее всего** в матчапах, где атакующий часто
крит-ит (т.е. `Crit%` высокий).

## Методика

Headless `BattleSimulationIntegrationTests.testStyleTriangleSweep`,
**30 000** битв × **12** конфигов. Wall clock **135.3s** (на 4s медленнее
step 9 — бои чуть длиннее: weak-блок теперь хуже гасит крит → больше
урона за пробитие → но это нерф dodge, не общий ритм).

## Сопутствующие изменения (без влияния на баланс)

- Новый сервис `PointStatusFormatter` (protocol + `DefaultPointStatusFormatter`
  + DI-обёртка). Вынесли композицию `shortLabel` / `debugLine`-строк из
  `HeroDisplayView` и `ConsoleDebugBattleLogger`. Damage-число везде берётся
  из `PointStatus.damageTakenValue`. Сюда же — мок `MockDamageService.calculateTotalDamage`
  в тестах. Чистая централизация форматирования, на цифры не влияет.
- Docstring `exhaustedBlockDamageMultiplier` переписан под `0.6` (раньше
  говорил `0.5 = "takes half"`).
- Два теста в `ElfSnapshotCombatCalculatorTests` синхронизированы с
  фактическим `0.6` и новой crit-семантикой.

## Сырые данные

```
Level  Matchup         Side    Win%    EP%     Blocks  WkBlock  Exh%    EndRed%  Crit%   Dodge%  StrDmg    Str%
----------------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      51.1%  61.6%  5.94    0.04      7.1%   4.6%     0.0%    0.0%     5.0      5.6%
L3     def_vs_crit     crit     38.3%  83.7%  5.02    0.95     57.3%   0.0%     7.1%    0.0%     4.6      5.3%
       (draw)          —        10.7%   avg rounds=15.0

L3     def_vs_dodge    def      55.0%  65.5%  6.33    0.08     10.8%   4.8%     0.0%    0.0%     5.1      5.7%
L3     def_vs_dodge    dodge    35.1%  86.5%  5.19    1.20     63.6%   0.0%     0.0%    6.9%     4.6      5.5%
       (draw)          —        10.0%   avg rounds=16.0

L3     dodge_vs_crit   dodge    42.9%  84.2%  5.05    0.93     57.8%   0.0%     0.0%    9.6%     4.7      5.4%
L3     dodge_vs_crit   crit     43.5%  83.9%  5.03    0.94     57.4%   0.0%     9.7%    0.0%     4.6      5.2%
       (draw)          —        13.6%   avg rounds=14.9

L6     def_vs_crit     def      49.5%  49.4%  6.51    0.00      0.1%   8.5%     0.0%    0.0%    11.1     10.8%
L6     def_vs_crit     crit     39.8%  87.5%  5.25    1.26     65.4%   0.0%    13.8%    0.0%    10.1     10.0%
       (draw)          —        10.7%   avg rounds=16.3

L6     def_vs_dodge    def      56.1%  56.0%  7.39    0.00      1.1%   9.1%     0.0%    0.0%    11.4     11.0%
L6     def_vs_dodge    dodge    34.8%  92.1%  5.52    1.91     76.9%   0.0%     0.0%   13.9%    10.3     10.4%
       (draw)          —         9.1%   avg rounds=18.5

L6     dodge_vs_crit   dodge    45.8%  88.4%  5.30    1.23     66.4%   0.0%     0.0%   19.1%    10.4     10.1%
L6     dodge_vs_crit   crit     42.0%  87.6%  5.25    1.28     65.5%   0.0%    19.0%    0.0%     9.5      9.3%
       (draw)          —        12.2%   avg rounds=16.3

L9     def_vs_crit     def      47.4%  41.4%  6.95    0.00      0.0%  11.6%     0.0%    0.0%    18.0     15.4%
L9     def_vs_crit     crit     41.8%  90.1%  5.41    1.57     71.4%   0.0%    20.7%    0.0%    16.5     14.3%
       (draw)          —        10.8%   avg rounds=17.4

L9     def_vs_dodge    def      57.5%  49.8%  8.37    0.00      0.2%  12.6%     0.0%    0.0%    18.9     16.1%
L9     def_vs_dodge    dodge    34.3%  95.4%  5.72    2.67     85.5%   0.0%     0.0%   20.7%    16.9     15.0%
       (draw)          —         8.2%   avg rounds=21.0

L9     dodge_vs_crit   dodge    50.2%  91.9%  5.51    1.57     74.3%   0.0%     0.0%   28.5%    16.7     14.2%
L9     dodge_vs_crit   crit     38.9%  90.5%  5.43    1.66     72.7%   0.0%    28.4%    0.0%    14.6     12.8%
       (draw)          —        10.9%   avg rounds=17.7

L12    def_vs_crit     def      47.6%  36.3%  7.39    0.00      0.0%  15.1%     0.0%    0.0%    26.0     19.8%
L12    def_vs_crit     crit     41.8%  92.1%  5.53    1.89     76.5%   0.0%    27.4%    0.0%    24.2     18.5%
       (draw)          —        10.6%   avg rounds=18.5

L12    def_vs_dodge    def      59.8%  46.5%  9.47    0.00      0.0%  16.7%     0.0%    0.0%    27.8     20.9%
L12    def_vs_dodge    dodge    32.8%  97.7%  5.86    3.61     92.2%   0.0%     0.0%   27.4%    24.9     19.8%
       (draw)          —         7.3%   avg rounds=23.6

L12    dodge_vs_crit   dodge    55.4%  94.2%  5.65    1.91     80.3%   0.0%     0.0%   37.9%    24.2     18.2%
L12    dodge_vs_crit   crit     34.9%  92.5%  5.55    2.02     77.8%   0.0%    38.0%    0.0%    20.1     16.0%
       (draw)          —         9.7%   avg rounds=18.9
```

## Сравнение step 9 → step 10 (Δ W%)

| Уровень | Матчап        | Сторона | Step 9 | Step 10 | Δ        |
|---------|---------------|---------|-------:|--------:|---------:|
| L3      | def_vs_crit   | def     | 50.7%  | 51.1%   | +0.4     |
| L3      | def_vs_crit   | crit    | 38.6%  | 38.3%   | −0.3     |
| L3      | def_vs_dodge  | def     | 54.8%  | 55.0%   | +0.2     |
| L3      | def_vs_dodge  | dodge   | 35.4%  | 35.1%   | −0.3     |
| L3      | dodge_vs_crit | dodge   | 43.8%  | 42.9%   | −0.9     |
| L3      | dodge_vs_crit | crit    | 42.9%  | 43.5%   | +0.6     |
| L6      | def_vs_crit   | def     | 48.9%  | 49.5%   | +0.6     |
| L6      | def_vs_crit   | crit    | 40.3%  | 39.8%   | −0.5     |
| L6      | def_vs_dodge  | def     | 56.4%  | 56.1%   | −0.3     |
| L6      | def_vs_dodge  | dodge   | 34.5%  | 34.8%   | +0.3     |
| L6      | dodge_vs_crit | dodge   | 46.8%  | 45.8%   | **−1.0** |
| L6      | dodge_vs_crit | crit    | 41.1%  | 42.0%   | **+0.9** |
| L9      | def_vs_crit   | def     | 47.6%  | 47.4%   | −0.2     |
| L9      | def_vs_crit   | crit    | 41.6%  | 41.8%   | +0.2     |
| L9      | def_vs_dodge  | def     | 57.8%  | 57.5%   | −0.3     |
| L9      | def_vs_dodge  | dodge   | 34.3%  | 34.3%   |  0.0     |
| L9      | dodge_vs_crit | dodge   | 52.4%  | 50.2%   | **−2.2** |
| L9      | dodge_vs_crit | crit    | 37.0%  | 38.9%   | **+1.9** |
| L12     | def_vs_crit   | def     | 47.5%  | 47.6%   | +0.1     |
| L12     | def_vs_crit   | crit    | 41.6%  | 41.8%   | +0.2     |
| L12     | def_vs_dodge  | def     | 59.3%  | 59.8%   | +0.5     |
| L12     | def_vs_dodge  | dodge   | 33.3%  | 32.8%   | −0.5     |
| L12     | dodge_vs_crit | dodge   | 59.1%  | 55.4%   | **−3.7** |
| L12     | dodge_vs_crit | crit    | 31.7%  | 34.9%   | **+3.2** |

## Наблюдения

### 1. Главный сдвиг — `dodge_vs_crit`, не `def_vs_*`

`def_vs_crit` и `def_vs_dodge` практически не двинулись (Δ ∈ ±0.6 пп —
шум при 30k боёв). Defender как был на грани 47-60 %, так и остался.
Это ожидаемо: defender weak-блокирует 0.00-0.08 раз за бой, изменение
крит-ветки weak-блока его не касается ни как защитника, ни как
атакующего (defender редко крит-ит).

**Сдвинулась** комбинация `dodge_vs_crit`:

| Уровень | Δ crit Win% | Δ dodge Win% | Crit%  | dodge.WkBlock |
|---------|------------:|-------------:|-------:|--------------:|
| L3      | +0.6        | −0.9         | 9.7 %  | 0.93          |
| L6      | +0.9        | −1.0         | 19.0 % | 1.23          |
| L9      | +1.9        | −2.2         | 28.4 % | 1.57          |
| L12     | **+3.2**    | **−3.7**     | 38.0 % | 1.91          |

Корреляция между сдвигом и `Crit% × dodge.WkBlock` почти прямая: чем
чаще крит у атакующего и чаще weak-блок у защитника, тем сильнее
эффект. На L12 crit-сторона выкидывает 38 % крит-успехов, dodge
weak-блокирует 1.91 раз за бой → +3.2 пп на стороне крита.

### 2. Crit немного «оживает» в матчапе против dodge

В `dodge_vs_crit` старая семантика (crit ×rawMult ×0.6) серьёзно
гасила крит-канал атакующего против истощённого защитника. Новая
семантика возвращает крит-каналу значимость на Exhausted-фазе:
+33 % урона в среднем при крит+weak-block.

L12 dodge_vs_crit особенно показателен: dodge всё ещё выигрывает
(55.4 %), но крит вернул себе **−4 пп** дисбаланса (был 59.1/31.7,
стал 55.4/34.9). Внутри пары стало ровнее.

### 3. def_vs_crit на L9-L12 — изменение не помогло

Цель «вытащить defender'а из 45-50 % в 60-70 %» этот шаг не приблизил.
Defender тут не страдал от старой weak-block-крит-механики (он не
weak-блокирует), и атакующий-crit при этом ещё и сам по себе слабее
в L9-L12 относительно базовой балансировки. Чтобы поднять defender'а
против crit, нужно работать с **обычным** crit-каналом (когда EP > 0),
а не с Exhausted-механикой.

### 4. EndRed%, Crit%, Dodge% — стохастически идентичны step 9

Все ±0.5 пп от step 9. Доп-проверка: новая crit-семантика не трогает
ни сами роллы крита/доджа, ни Endurance-редукцию — только финальный
урон по weak-блоку.

### 5. avg rounds почти не изменился

L3: 15.0/16.0/14.9 (step 9: 15.0/16.0/14.9) — копия.
L12: 18.5/23.6/18.9 (step 9: 18.5/23.7/19.0) — копия в пределах шума.

Бои не стали ни длиннее, ни короче — только их **исходы** немного
сдвинулись внутри `dodge_vs_crit`.

## Состояние треугольника

| Маркер              | Step 8 | Step 9 | Step 10 |
|---------------------|-------:|-------:|--------:|
| ✓ в 60-70 %         |   0    |   0    |   0     |
| ⚠ под нижней (45-60)| 4      | 10     | 9       |
| ✗ далеко (<45 %)    |   8    |   2    |   3     |

`L6 dodge_vs_crit dodge` ушёл из ⚠ (46.8) в ✗ (45.8 — на границе).
`L9 dodge_vs_crit dodge` остался в ⚠. `L3 dodge_vs_crit dodge` остался
в ✗ (42.9). Net: один слайс сполз через границу 45 %.

## Сравнение всех замеров (главное)

| Уровень | Матчап        | Сторона | Step 5 | Step 6 | Step 7 | Step 8 | Step 9 | Step 10 | Цель    |
|---------|---------------|---------|-------:|-------:|-------:|-------:|-------:|--------:|---------|
| L12     | def_vs_crit   | def     | 67.8%  | 54.2%  | 48.0%  | 45.4%  | 47.5%  | **47.6%** ⚠ | 60-70%  |
| L12     | def_vs_dodge  | def     | 68.0%  | 62.2%  | 54.9%  | 55.2%  | 59.3%  | **59.8%** ⚠ | 60-70%  |
| L12     | dodge_vs_crit | dodge   | 73.5%  | 65.4%  | 62.7%  | 59.6%  | 59.1%  | **55.4%** ⚠ | 60-70%  |
| L9      | def_vs_crit   | def     | 65.4%  | 53.3%  | 47.1%  | 45.4%  | 47.6%  | **47.4%** ⚠ | 60-70%  |
| L9      | def_vs_dodge  | def     | 69.3%  | 61.3%  | 54.5%  | 54.4%  | 57.8%  | **57.5%** ⚠ | 60-70%  |
| L9      | dodge_vs_crit | dodge   | 62.8%  | 57.2%  | 55.1%  | 53.1%  | 52.4%  | **50.2%** ⚠ | 60-70%  |
| L6      | def_vs_crit   | def     | 65.6%  | 53.3%  | 48.9%  | 46.9%  | 48.9%  | **49.5%** ⚠ | 60-70%  |
| L6      | def_vs_dodge  | def     | 69.9%  | 59.0%  | 54.0%  | 53.7%  | 56.4%  | **56.1%** ⚠ | 60-70%  |
| L6      | dodge_vs_crit | dodge   | 53.8%  | 50.1%  | 48.5%  | 47.9%  | 46.8%  | **45.8%** ✗ | 60-70%  |
| L3      | def_vs_crit   | def     | 65.0%  | 54.2%  | 50.5%  | 49.5%  | 50.7%  | **51.1%** ⚠ | 60-70%  |
| L3      | def_vs_dodge  | def     | 67.8%  | 56.5%  | 52.8%  | 52.2%  | 54.8%  | **55.0%** ⚠ | 60-70%  |
| L3      | dodge_vs_crit | dodge   | 44.4%  | 45.2%  | 45.5%  | 45.0%  | 43.8%  | **42.9%** ✗ | 60-70%  |

Маркеры: ✓ внутри 60-70, ⚠ под нижней, ✗ далеко.

## Возможные следующие шаги для def Win% > 60 %

Самый близкий слайс — **L12 def_vs_dodge def = 59.8 %**, нужно +0.2 пп
до 60 %. Это уже шумовая зона: можно ничего не менять и попасть в
коридор на следующем прогоне.

Для остального — рычаги те же, что в step 9 doc (A/B/C). Главный
вывод этого шага: **weak-block + crit семантика — это инструмент для
балансировки `crit-vs-dodge` пары, не для буста defender'а.** Если
хочется ещё больше нагрузить crit в этом матчапе — снизить веса
`blockedCritMultiplierWeights` в сторону 0.75-1.0 (сейчас `[5,50,40,5,0,0]`,
mean 1.1125; например `[10, 60, 30, 0, 0, 0]` даст mean 1.0 — это
ещё нерфит crit и буст dodge).

Для defender'а нужно работать с **обычной** фазой блока (когда EP > 0):
- увеличить `blockedCritMultiplierWeights` в сторону низких значений
  (сейчас mean 1.1125 — крит почти не «течёт» сквозь обычный блок);
- буст `Endurance` (увеличить ratio в `predefinedDistributions` от
  30 % к 35-40 % от Strength);
- буст armor у defender-style.

## Итог

Семантика weak-block + crit перестала «двойным штрафом» гасить крит:
`× selectBlockedCritMultiplier()` вместо `× rawMult × 0.6` даёт
**+33 % урона в среднем** по защитнику-в-Exhausted под критом.

Net эффект — точечное перебалансирование пары `dodge_vs_crit`
(crit +3.2 пп на L12), defender везде в стохастическом шуме.
Параллельно решены три «технических» долга:

1. константа `0.6` теперь корректно отражена в docstring и тестах;
2. damage-формула собрана в `PointStatus.damageTakenValue`, рендер
   и логи берут её оттуда через `PointStatusFormatter`;
3. weak-block + crit больше не штрафуется дважды (`selectBlockedCritMultiplier`
   ИЛИ `× 0.6` — никогда оба).
