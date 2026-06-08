# Triangle Win-Rate Sweep — pre-endurance-reduction baseline (2026-05-25)

**Снимок baseline'а перед добавлением механики Endurance → damage reduction.**

Зафиксирован для сравнения с пост-изменением метрикой. Endurance в этом
прогоне работает только как EP-discount для блоков (старая, единственная
роль). После этой даты включается вторая роль — `getRandomEnduranceDamageReduction`
внутри `ElfDamageService.calculateTotalDamage`, по таблице 1:1 со Strength.

## Методика

- Headless `BattleSimulationIntegrationTests.testStyleTriangleSweep`
- **30 000 битв** на (level, matchup), **1 прогон**
- Уровни: 3, 6, 9, 12 × матчапы: def_vs_crit, def_vs_dodge, dodge_vs_crit
- `includeRandomAttributes = off`, Recruit's Spear loadout, без экипировки
- Bot AI: атаки/блоки выбираются равномерно случайно

Итого: **4 × 3 × 30 000 = 360 000 битв**, wall clock **136.9s**.

## Сырые данные

```
Level  Matchup         Side    Win%    EP%     Blocks  Fail %  AvgRound  %Through  StrDmg    Str%
------------------------------------------------------------------------------------------------------------------------
L3     def_vs_crit     def      54.6%  60.2%  6.72     2.1% 17.5      94.7%        5.8      6.4%
L3     def_vs_crit     crit     34.5%  81.0%  5.40    56.7% 14.1      80.3%        5.3      6.2%
       (draw)          —        11.0%   avg rounds=16.9

L3     def_vs_dodge    def      58.5%  63.8%  7.13     4.1% 18.7      93.7%        5.8      6.4%
L3     def_vs_dodge    dodge    31.6%  82.9%  5.53    63.5% 14.6      78.6%        5.4      6.4%
       (draw)          —         9.9%   avg rounds=18.0

L3     dodge_vs_crit   dodge    44.2%  81.5%  5.43    57.4% 14.1      80.4%        5.8      6.4%
L3     dodge_vs_crit   crit     37.5%  81.5%  5.43    58.2% 14.1      80.2%        5.5      6.2%
       (draw)          —        18.3%   avg rounds=17.0

L6     def_vs_crit     def      45.3%  45.3%  7.07     0.0% 19.2      96.9%       12.2     12.0%
L6     def_vs_crit     crit     43.8%  82.4%  5.50    61.5% 14.5      78.9%       11.7     11.4%
       (draw)          —        10.9%   avg rounds=17.7

L6     def_vs_dodge    def      51.6%  51.2%  7.99     0.3% 23.3      96.7%       12.3     12.0%
L6     def_vs_dodge    dodge    39.3%  85.8%  5.72    74.8% 15.3      74.9%       12.0     12.0%
       (draw)          —         9.1%   avg rounds=20.0

L6     dodge_vs_crit   dodge    52.4%  83.9%  5.59    64.6% 14.6      78.5%       12.7     12.1%
L6     dodge_vs_crit   crit     33.7%  83.2%  5.54    64.8% 14.6      78.2%       11.3     11.1%
       (draw)          —        13.9%   avg rounds=18.2

L9     def_vs_crit     def      35.8%  36.3%  7.33     0.0% —         —           19.1     16.9%
L9     def_vs_crit     crit     53.4%  83.8%  5.58    64.3% 14.7      77.8%       18.8     15.8%
       (draw)          —        10.8%   avg rounds=18.3

L9     def_vs_dodge    def      43.2%  43.5%  8.79     0.0% 30.3      97.9%       19.3     17.0%
L9     def_vs_dodge    dodge    48.7%  87.5%  5.84    82.5% 15.9      71.4%       19.8     17.0%
       (draw)          —         8.1%   avg rounds=22.0

L9     dodge_vs_crit   dodge    60.6%  85.6%  5.70    71.3% 15.0      76.6%       20.5     17.1%
L9     dodge_vs_crit   crit     28.6%  84.9%  5.66    71.5% 15.1      76.5%       17.0     15.3%
       (draw)          —        10.8%   avg rounds=19.3

L12    def_vs_crit     def      27.0%  30.4%  7.50     0.0% —         —           26.2     21.3%
L12    def_vs_crit     crit     63.3%  84.3%  5.62    66.3% 14.9      77.1%       26.5     19.6%
       (draw)          —         9.7%   avg rounds=18.7

L12    def_vs_dodge    def      33.2%  38.7%  9.54     0.0% —         —           26.1     21.4%
L12    def_vs_dodge    dodge    59.6%  88.4%  5.89    87.6% 16.3      68.1%       28.7     21.5%
       (draw)          —         7.1%   avg rounds=23.9

L12    dodge_vs_crit   dodge    69.8%  87.0%  5.80    76.4% 15.3      74.7%       29.3     21.6%
L12    dodge_vs_crit   crit     22.1%  86.0%  5.74    77.1% 15.4      74.5%       22.5     18.8%
       (draw)          —         8.1%   avg rounds=20.4
```

## Сводка W% по граням (для сравнения с post-change)

| Уровень | def_vs_crit (def) | def_vs_dodge (def) | dodge_vs_crit (dodge) |
|---|---|---|---|
| L3  | 54.6% | 58.5% | 44.2% |
| L6  | 45.3% | 51.6% | 52.4% |
| L9  | 35.8% | 43.2% | 60.6% |
| L12 | **27.0%** | **33.2%** | **69.8%** |

**Ожидание после endurance → damage reduction:** def-стиль должен подняться
на обеих гранях, особенно на высоких уровнях (где Endurance набирает 12+
очков). dodge_vs_crit мало изменится — обе стороны имеют endurance 0.
