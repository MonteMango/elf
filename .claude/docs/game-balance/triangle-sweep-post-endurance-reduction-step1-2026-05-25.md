# Triangle Win-Rate Sweep — post-endurance-reduction step 1 (2026-05-25)

**Первый замер после включения Endurance → damage reduction.**

Endurance защитника теперь снижает входящий урон по таблице **1:1
скопированной со Strength** (без тюнинга). Формула:

- `.hit`: `max(0, weapon + strength - enduranceReduction - armor)`
- `.critHit`: `max(0, Int((weapon + strength - enduranceReduction) * multiplier) - armor)`

Парный к этому файлу baseline — `triangle-sweep-pre-endurance-reduction-2026-05-25.md`.

## Методика

- Headless `BattleSimulationIntegrationTests.testStyleTriangleSweep`
- **30 000 битв** на (level, matchup), **1 прогон**
- Уровни 3/6/9/12 × матчапы def_vs_crit / def_vs_dodge / dodge_vs_crit
- `includeRandomAttributes = off`, Recruit's Spear, без экипировки

Wall clock **182.5s** (vs baseline 136.9s — бои стали длиннее ≈ +33%).

## Сырые данные

```
Level  Matchup         Side    Win%    EP%     Blocks  Fail %  AvgRound  %Through  StrDmg    Str%
------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      53.2%  73.3%  8.19    12.9% 20.5      91.4%        7.6      8.5%
L3     def_vs_crit     crit     36.9%  86.8%  5.79    79.2% 15.6      73.2%        6.7      7.6%
       (draw)          —         9.9%   avg rounds=21.0

L3     def_vs_dodge    def      54.6%  76.7%  8.57    18.7% 21.6      90.3%        7.6      8.5%
L3     def_vs_dodge    dodge    34.8%  87.8%  5.85    84.2% 16.0      71.0%        6.9      7.8%
       (draw)          —        10.6%   avg rounds=22.3

L3     dodge_vs_crit   dodge    48.6%  87.3%  5.82    81.7% 15.6      72.6%        7.8      8.5%
L3     dodge_vs_crit   crit     33.9%  87.2%  5.81    81.6% 15.7      72.9%        7.3      8.1%
       (draw)          —        17.5%   avg rounds=21.4

L6     def_vs_crit     def      90.1%  59.0%  9.22     0.6% 23.1      96.7%       17.2     15.8%
L6     def_vs_crit     crit      6.1%  88.2%  5.88    88.2% 16.2      69.8%       15.2     17.3%
       (draw)          —         3.7%   avg rounds=23.1

L6     def_vs_dodge    def      91.3%  66.0% 10.31     3.1% 26.3      93.9%       17.2     15.8%
L6     def_vs_dodge    dodge     5.8%  89.1%  5.94    93.7% 16.7      64.4%       15.7     18.2%
       (draw)          —         2.9%   avg rounds=26.0

L6     dodge_vs_crit   dodge    58.6%  88.2%  5.88    85.5% 16.1      70.9%       16.7     15.7%
L6     dodge_vs_crit   crit     29.0%  88.0%  5.86    85.7% 16.0      70.6%       14.6     14.4%
       (draw)          —        12.5%   avg rounds=22.6

L9     def_vs_crit     def      99.7%  48.1%  9.71     0.0% 25.0      100.0%      27.5     22.0%
L9     def_vs_crit     crit      0.2%  88.6%  5.91    90.9% 16.4      67.6%       24.8     31.0%
       (draw)          —         0.1%   avg rounds=24.2

L9     def_vs_dodge    def      99.5%  57.5% 11.62     0.2% 32.4      96.5%       27.4     21.9%
L9     def_vs_dodge    dodge     0.3%  89.6%  5.97    97.0% 17.1      59.0%       26.2     33.4%
       (draw)          —         0.1%   avg rounds=29.1

L9     dodge_vs_crit   dodge    68.4%  88.8%  5.92    88.8% 16.3      68.9%       26.6     21.9%
L9     dodge_vs_crit   crit     22.7%  88.5%  5.90    89.2% 16.3      68.7%       21.5     19.5%
       (draw)          —         8.9%   avg rounds=23.6

L12    def_vs_crit     def     100.0%  40.6% 10.02     0.0% —         —           38.3     27.3%
L12    def_vs_crit     crit      0.0%  89.0%  5.93    93.1% 16.6      66.1%       35.6     51.9%
       (draw)          —         0.0%   avg rounds=25.1

L12    def_vs_dodge    def     100.0%  52.4% 12.94     0.1% 38.8      96.5%       38.3     27.3%
L12    def_vs_dodge    dodge     0.0%  89.9%  5.99    98.8% 17.3      54.0%       38.8     56.8%
       (draw)          —         0.0%   avg rounds=32.3

L12    dodge_vs_crit   dodge    77.5%  89.1%  5.94    91.4% 16.5      66.9%       37.4     27.2%
L12    dodge_vs_crit   crit     16.3%  88.8%  5.92    91.0% 16.5      66.9%       27.6     23.5%
       (draw)          —         6.2%   avg rounds=24.6
```

## Сравнение с baseline (W% по сторонам)

| Уровень | Матчап        | Side  | Pre   | Post  | Δ       |
|---------|---------------|-------|-------|-------|---------|
| L3      | def_vs_crit   | def   | 54.6% | 53.2% | −1.4 pp |
| L3      | def_vs_crit   | crit  | 34.5% | 36.9% | +2.4 pp |
| L3      | def_vs_dodge  | def   | 58.5% | 54.6% | −3.9 pp |
| L3      | def_vs_dodge  | dodge | 31.6% | 34.8% | +3.2 pp |
| L3      | dodge_vs_crit | dodge | 44.2% | 48.6% | +4.4 pp |
| L3      | dodge_vs_crit | crit  | 37.5% | 33.9% | −3.6 pp |
| L6      | def_vs_crit   | def   | 45.3% | **90.1%** | **+44.8 pp** |
| L6      | def_vs_crit   | crit  | 43.8% | 6.1%  | −37.7 pp |
| L6      | def_vs_dodge  | def   | 51.6% | **91.3%** | **+39.7 pp** |
| L6      | def_vs_dodge  | dodge | 39.3% | 5.8%  | −33.5 pp |
| L6      | dodge_vs_crit | dodge | 52.4% | 58.6% | +6.2 pp |
| L6      | dodge_vs_crit | crit  | 33.7% | 29.0% | −4.7 pp |
| L9      | def_vs_crit   | def   | 35.8% | **99.7%** | **+63.9 pp** |
| L9      | def_vs_crit   | crit  | 53.4% | 0.2%  | −53.2 pp |
| L9      | def_vs_dodge  | def   | 43.2% | **99.5%** | **+56.3 pp** |
| L9      | def_vs_dodge  | dodge | 48.7% | 0.3%  | −48.4 pp |
| L9      | dodge_vs_crit | dodge | 60.6% | 68.4% | +7.8 pp |
| L9      | dodge_vs_crit | crit  | 28.6% | 22.7% | −5.9 pp |
| L12     | def_vs_crit   | def   | 27.0% | **100.0%** | **+73.0 pp** |
| L12     | def_vs_crit   | crit  | 63.3% | 0.0%  | −63.3 pp |
| L12     | def_vs_dodge  | def   | 33.2% | **100.0%** | **+66.8 pp** |
| L12     | def_vs_dodge  | dodge | 59.6% | 0.0%  | −59.6 pp |
| L12     | dodge_vs_crit | dodge | 69.8% | 77.5% | +7.7 pp |
| L12     | dodge_vs_crit | crit  | 22.1% | 16.3% | −5.8 pp |

## Что произошло — диагностика

1. **def-стиль доминирует абсолютно с L6 и выше.** На L9/L12 def
   выигрывает 99-100% против crit и dodge — игроки в этих стилях
   физически не могут пробить редукцию.
2. **Endurance scales линейно с уровнем у def-стиля** (+3 за уровень):
   - L3 def: endurance 9 → распределение `[1,2,3,4]`, mean ≈ 2.5 редукции/удар
   - L6 def: endurance 18 → `[2,3,4]`, mean = 3 редукции/удар
   - L9 def: endurance 27 → `[3,4,5,6]`, mean ≈ 4.5 редукции/удар
   - L12 def: endurance 36 → `[5,6,7]`, mean = 6 редукции/удар
3. **У dodge/crit endurance = 0** — никакой редукции на их стороне.
   Это создаёт **полностью асимметричный эффект**, который растёт с уровнем.
4. **L3 почти не задет** (def −1.4 / −3.9 pp): endurance 9 даёт mean 2.5
   при базовом уроне ~10-12, что соразмерно armor. Эффект мягкий.
5. **`dodge_vs_crit` стабилен** (+4-8 pp в сторону dodge): обе стороны
   имеют endurance 0, edge не задет напрямую. Небольшой сдвиг,
   вероятно, от удлинения боёв и снижения вариативности.
6. **Бои стали значительно длиннее**: AvgRound в `def_vs_dodge` поднялся
   с 23.9 до 32.3 на L12 (+35%). EP-bottleneck у dodge/crit ещё
   сильнее — fail rate подскочил с 87.6% до 98.8%.
7. **`Str%` skewed**: на L9/L12 у проигравшей стороны Str% доходит до
   51-56%, потому что **всё, что не strength (weapon damage), съедено
   endurance-редукцией**. Strength уже не «бонус» — это единственное,
   что вообще остаётся от удара после редукции.

## Вердикт

Step 1 как и ожидалось — **симметричное копирование таблицы 1:1 со Strength
перевешивает баланс**. Нужно либо урезать таблицу Endurance отдельно (мягче
распределение), либо ограничить применение редукции (например, только на
блокирующих хитах). Триангл сейчас выглядит так:

- **def ≫ crit**, **def ≫ dodge**, **dodge > crit** — двусторонний
  «треугольник» превратился в линейную иерархию с def наверху.

Следующий шаг балансировки требует тюнинга таблицы независимо от Strength
(теперь это легко — стратегии разделены).
