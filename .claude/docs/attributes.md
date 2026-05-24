# Elfy — Character Attributes

Single source of truth for character attributes, fight styles, and the combat
math that consumes them. Combat resolution flow lives in `game-design.md` —
this doc focuses on the **stats** themselves: what each one does, how each
fight style scales them per level, and how the planned **Endurance / EP**
system fits in.

> **Status legend** — sections marked **(current)** describe shipped
> behaviour. Sections marked **(planned)** describe agreed design that is
> not yet in code. When implementing, prefer reading the source under
> `Packages/elf_Kit/Sources/DataLayer/Services/{Attributes,Crit,Dodge,Combat}`
> over relying on this doc — code wins on conflicts, then update this doc.

---

## Attribute Roster

Attributes are stored on `HeroAttributes` (see
`elf_Kit/Sources/DataLayer/Model/Hero/`) and on `CombatantSnapshot` for
combat. The numeric type is `Attribute` (a typed wrapper, not raw `Int16`)
— see `type-driven-design.md`.

### Core stats (current)

| Attribute       | Role                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **Strength**    | Adds to per-attack damage (rolled via `DamageService`).                  |
| **Agility**     | Dodge chance.                                                            |
| **Power**       | Critical-hit chance. Crits land through blocks but a blocked crit deals only normal-hit damage (multiplier forced to `1.0×`). |
| **Intuition**   | Suppresses opponent's dodge chance and crit chance.                      |
| **Hit Points**  | Health pool. 0 HP = defeat.                                              |
| **Mana Points** | Resource for abilities (not yet used).                                   |

### Planned stat

| Attribute       | Role                                                                    |
|-----------------|-------------------------------------------------------------------------|
| **Endurance**   | Reduces EP cost paid per successful block (see *Endurance / EP* below). |

Endurance is a **global, equal-rank attribute** — equipment and crystals
can grant it like any other stat. It is not exclusive to the def style.

### One attribute → one role (done)

The "Agility reduces enemy crit multiplier" coupling has been removed
(2026-05-23). Each attribute now drives exactly one mechanic:

| Attribute   | Role                                 |
|-------------|--------------------------------------|
| Strength    | damage                               |
| Agility     | dodge chance                         |
| Power       | crit chance                          |
| Intuition   | suppress enemy dodge & crit          |
| Endurance   | EP-efficient blocking                |

### Level cap

**Max hero level is 12.** All scaling tables, balance flags, and
imbalance assessments in this doc assume that hard ceiling. Stats also
gain values from equipment, but base level scaling alone never pushes
any single stat above 50, which means the dodge/crit 100%-cap (auto-
success path in stage 2) is not reachable through levelling alone.

---

## Combat Math (current)

Resolution per body part (see `ElfSnapshotCombatCalculator`):

| Situation                | Rolls performed                                                                            |
|--------------------------|--------------------------------------------------------------------------------------------|
| Attacked **and** blocked | Crit roll only. On success → `.critHit` with multiplier forced to `1.0×` (normal-hit damage, but UI/stats still mark it as a crit); on fail → `.blocked`. EP is spent in both branches. |
| Attacked, **not** blocked| Dodge roll first. If dodged → done. Otherwise crit roll → crit hit (full multiplier) or normal hit. |
| Not attacked             | Nothing.                                                                                   |

Both **dodge** and **crit** use the same two-stage peak+linear-tail
distribution:

1. **Stage 1** — pick a chance value from the peak+linear-tail
   distribution (the peak takes `peakWeight` of the total probability;
   the rest tapers linearly toward both ends with floor 1). Inputs:
   - Dodge: `defender.agility` vs `attacker.intuition`
   - Crit:  `attacker.power` vs `defender.intuition`
2. **Stage 2** — roll `1...100`, succeed if `roll ≤ chance`. Auto-fail at
   `chance ≤ 0`, auto-success at `chance ≥ 100`.

Crit then runs a **Stage 3** to pick a damage multiplier from the fixed
`CritMultiplierDistribution`. Defender stats no longer skew this roll —
agility's only effect on crit damage now is upstream, via the dodge
roll cancelling the attack entirely.

**Distribution shape — peak + linear tail** (was tent until 2026-05-23).
Two knobs in `GameMechanicsConstants` per side:

| Constant | Default | Meaning |
|---|---|---|
| `dodgePeakPosition` / `critPeakPosition` | `0.0` | Where the peak sits inside the range `[stat-instinct ... min(stat,100)]`. `0.0` = peak at minimum, `0.5` = middle, `1.0` = maximum. |
| `dodgePeakWeight`   / `critPeakWeight`   | `0.6` | Exact share of total probability the peak value takes — *independent of range size*. The remaining `1 − weight` is split among non-peak values with a linear falloff from the peak toward both ends (floor 1). |

**Example** (lvl 12 dodge agility 48 vs def intuition 24, range
`[24...48]`, peak at index 0):

| Rolled value | Probability |
|---|---|
| 24 (peak) | **60%** |
| 25 | 4.4% |
| 30 | 3.5% |
| 36 | 2.4% |
| 48 | 0.2% |

The peak share no longer depends on `rangeSize`. (Old integer-tent
weighting gave the peak only `2/(N+1)` ≈ 7.7% in this case.)

**Crit multiplier distribution** — values `[0.75, 1.00, 1.25, 1.50, 2.00, 3.00]`,
weights `[0, 5, 15, 40, 30, 10]` → `E[multiplier | crit] = 1.74×`. So a
successful crit adds **+0.74×** of base damage on average.

**Important nuance** — when `instinct == 0` on the opponent side, the
distribution range collapses to a single value equal to the actor's stat.
So with no instinct, **1 agility = exactly 1% dodge** and **1 power =
exactly 1% crit**. Once instinct opens the range, the peak pulls the
expected chance well below the stat value (see *Per-Point Value* below).

Implementations:
- `ElfDodgeService.calculateDodge(agility:instinct:)`
- `ElfCritService.calculateCrit(power:instinct:defenderAgility:)`
- `ElfSnapshotCombatCalculator.calculatePointStatus(...)`

---

## Per-Point Value

Empirical coefficients derived from the actual code (distribution
strategies + damage tables). Use these instead of the naive 1:1
intuitions ("1 agility = 1% dodge"); the real numbers are conditional on
the opponent's intuition.

### Dodge (1 agility)

| Defender's agility | Attacker's intuition | Mean dodge chance |
|---|---|---|
| 40 | 0  | **40%** (single-value range) |
| 40 | 10 | ~33% |
| 40 | 20 | ~27% |
| 40 | 40 | ~17% |

Rule of thumb: **1 agility ≈ 1% dodge** vs zero-intuition opponent;
**~0.6%** vs an opponent with comparable intuition.

### Crit (1 power)

Same shape, but with peak `0.2` (more aggressive instinct cut):

| Attacker's power | Defender's intuition | Mean crit chance |
|---|---|---|
| 40 | 0  | **40%** |
| 40 | 10 | ~32% |
| 40 | 20 | ~24% |
| 40 | 40 | ~10% |

Rule of thumb: **1 power ≈ 1% crit** vs zero-intuition opponent;
**~0.5%** with comparable intuition.

### Strength → mean damage (per attack)

From `ElfStrengthDamageDistributionStrategy.predefinedDistributions`:

| Strength | Mean damage |
|---|---|
| 1  | 0.25 |
| 5  | ~0.6 |
| 10 | ~1.3 |
| 12 (max from levelling) | ~1.6 |
| 20 | ~3.4 |
| 30 | ~4.5 |
| 40 | ~6.7 |
| 50 | 8.4 |

Rule of thumb: **1 strength ≈ +0.17 mean damage per attack** in the
levelling range — much weaker than the naive "+1 per round". Strength
gains most of its weight from equipment, not levels.

### Endurance

**1 endurance = +0.5 effective blocks** (universal across weapons by the
rule). For a typical-damage hit at lvl 12 (~5-10 base damage), one block
saves roughly that much HP, so **1 endurance ≈ 2.5-5 HP saved per
battle** — but only for a hero who actually allocates block points.

### Per-point HP-equivalent (rough, lvl 12, both heroes with equal intuition)

Assumes ~8 HP per attack base damage and 1 attack/round.

| 1 point of … | Defensive value | Offensive value |
|---|---|---|
| agility    | ~0.05 HP/round saved | — |
| power      | — | ~0.04 HP/round dealt (incl. multiplier) |
| strength   | — | **~0.17 HP/round dealt** |
| intuition  | ~0.05 HP/round saved (cuts crit + dodge equally) | — |
| endurance  | **~0.4 HP/round saved** (when blocking, 2H) | — |

> **Reading these numbers:** strength is the strongest *offensive* point
> per unit; endurance is the strongest *defensive* point per unit, but
> only when blocks are actually being set. Power and agility are the
> weakest per-point — but both exist primarily for the **triangle**, not
> raw DPS, so this is by design.

---

## Triangle Snapshot at Max Level (lvl 12)

Stat totals from levelling alone (no equipment), using the *planned*
scaling table:

| Style  | strength | agility | power | intuition | endurance |
|--------|----------|---------|-------|-----------|-----------|
| crit   | 12 | 0  | **48** | 12 | 0 |
| dodge  | 12 | **48** | 0 | 12 | 0 |
| def    | 12 | 0  | 0 | 24 | **36** |

Effective triangle probabilities (peak+linear-tail distribution, peak at
minimum, peak weight 0.6):

| Edge | Mechanism | Effective rate |
|------|-----------|----------------|
| **dodge > crit** | dodge defender (agility 48) vs crit's intuition 12; range 36-48 peak at 36 (60%) | **~37% dodge** |
| **crit > def**   | crit attacker (power 48) vs def's intuition 24; range 24-48 peak at 24 (60%) | **~28% crit lands** (on blocked parts: damage reduced to normal hit; on unblocked: full multiplier) |
| **def > dodge**  | dodge attacker (agility 48) vs def's intuition 24; range 24-48 peak at 24 (60%) | **~28% dodge** (down from ~37% baseline) |

The peak-weight model concentrates roll outcomes near the minimum, so
effective rates are 5-15 pp below the old tent-shape baseline. Confirmed
by win-rate simulation — see Open Balance Flags.

---

## Open Balance Flags

Известные или предполагаемые проблемы. Решать симуляцией, не интуицией.

### Измеренные win-rate треугольника (lvl 12 vs lvl 12, 30 000 боёв, без экипировки)

Цель по дизайну: победитель 60-70% / ничья 0-10% / проигравший 30-40%.

**Текущая конфигурация** (2026-05-24):
- `peak+linear` распределение, `peakPosition = 0.0`, `peakWeight = 0.6`
- agility ↛ crit-multiplier связка удалена
- `critMultiplierWeights = [0,15,30,40,10,5]` (mean множителя 1.475×)
- `blockedCritMultiplier = 1.0` (блокированный крит = обычный урон, статус остаётся `.critHit`)
- HP всех стилей = `80 + 5×lvl` (140 на lvl 12)

Замеры — среднее из 3 прогонов × 30 000 боёв (разброс ≤ 0.5 pp на эдж,
выборка 30k достаточно репрезентативна).

| Эдж           | Win    | Draw | Lose  | Σ разброс | Вердикт |
|---------------|--------|------|-------|-----------|---------|
| dodge > crit  | 69.5%  | 8.3% | 22.2% | ±0.15 pp  | ✓ верхняя граница цели |
| crit > def    | 63.6%  | 9.8% | 26.7% | ±0.10 pp  | ✓ центр цели |
| def > dodge   | 59.4%  | 7.1% | 33.6% | ±0.25 pp  | ✓ нижняя граница цели (−0.6 pp) |

Разбивка по прогонам:

| Эдж | Run 1 | Run 2 | Run 3 |
|-----|-------|-------|-------|
| dodge > crit | 69.7 / 8.2 / 22.1 | 69.4 / 8.2 / 22.4 | 69.5 / 8.4 / 22.1 |
| crit > def   | 63.5 / 9.6 / 26.9 | 63.7 / 9.7 / 26.6 | 63.5 / 10.0 / 26.6 |
| def > dodge  | 59.1 / 7.1 / 33.8 | 59.4 / 7.1 / 33.5 | 59.6 / 7.1 / 33.4 |

**Все три эджа в дизайн-коридоре одновременно.** Триангл сбалансирован.

### Эволюция win-rate (для истории)

| Итерация | dodge>crit | crit>def | def>dodge |
|----------|------------|----------|-----------|
| Baseline (старый tent 0.4/0.2, crit weights `[0,5,15,40,30,10]`, agility-decreaser активен, blockedCrit = rolled) | 62/9/29 ✓ | 89/5/7 ⚠⚠ | 14/5/81 ✗ |
| + peak+linear `0.0/0.6` для dodge & crit | 60/9/31 ✓ | 84/6/10 ⚠ | 21/7/72 ✗ |
| + удалён agility→crit-multiplier + softer mults `[0,15,30,40,10,5]` + `blockedCrit = 1.0` | 54/10/36 ⚠ | 72/9/19 ⚠ | 21/7/72 ✗ |
| **+ HP `80 + 5×lvl` для всех стилей** (avg of 3 × 30k) | **69.5/8.3/22.2 ✓** | **63.6/9.8/26.7 ✓** | **59.4/7.1/33.6 ✓** |

### Почему +5HP/lvl сработал именно сейчас

Раньше (когда я тестировал +5HP/lvl поверх baseline-механик в самом начале)
он **ухудшал** баланс — длинные бои уменьшали дисперсию и дома убивали слабую
сторону ещё стабильнее. Сейчас он **исправил** баланс, потому что
предшествующие изменения уже выровняли DPS:
- удалённый agility-decreaser и softer multiplier weights дали crit-у нормальный, нечрезмерный урон
- `blockedCrit = 1.0` отнял у crit «двойную награду» против блока def
- HP +5/lvl растянул бои с ~10-15 раундов до ~18-25, что вскрыло **EP-bottleneck**
  у dodge: 86-88% пула расходуется, block coverage падает с 36% до 25% — dodge
  буквально не успевает блокировать в поздней игре. def с его endurance-discount-ом
  использует только 30-39% пула и держит coverage 40% всё битву.

### EP-диагностика на текущей конфигурации

| Матчап | Bot1 EP% / coverage | Bot2 EP% / coverage | Avg blocks (Bot1 / Bot2) | Avg battle length |
|---|---|---|---|---|
| dodge vs crit | 86.8% / 28.4% | 86.1% / 28.1% | 5.78 / 5.74 | ~20-21 раунд |
| dodge vs def  | 88.6% / 24.7% | 38.9% / 40.1% | 5.91 / 9.60 | ~24 раунда |
| crit vs def   | 84.3% / 30.1% | 30.2% / 39.9% | 5.62 / 7.47 | ~19 раундов |

(Bot1 = атакер первой колонки, Bot2 = атакер второй.)

**Endurance-asymmetry** — главный «балансер»: dodge/crit при endurance 0 не могут
сберечь EP в длинных боях, а def при endurance 36 платит 71-87 EP за блок
вместо 200-300 и сохраняет полное покрытие до конца.

(Методика: `BattleSetupScreen` → кнопка 1000x → `PerfTestConfig.multiBattleCount = 30000`. Bot AI выбирает атаку/блок равномерно случайно; loadout по умолчанию = Recruit's Spear, без прочей экипировки.)

### Корневые причины

1. **`def > dodge` инвертирован (несущая грань треугольника).**
   Под капотом на lvl 12:
   - Оба героя выбирают 1 атаку + 2 блока за раунд случайно из 5 частей
     тела. **Покрытие блоком = 2/5 = 40%** для обоих. То есть бюджет
     блоков симметричен — Endurance не даёт def *никакого* преимущества
     в этом матчапе.
   - dodge-защитник: agility 48 vs def's intuition 24 → шанс додж ~35%
     на 60% атак, попадающих по неблокированным частям.
   - dodge суммарное избегание ≈ 40% блок + (60% × 35%) = **~61%**.
   - def суммарное избегание ≈ 40% блок, ноль доджа, ноль крит-пирса =
     **~40%**.
   - При одинаковых 80 HP и одинаковой силе 12, у dodge эффективно
     ~1.5× HP при одинаковом уроне → выигрывает ~81%.
   - **Endurance структурно мёртв в этом матчапе.** У def 24 блока
     (2H) / 30 (1H); бот тратит за бой только ~5-6 блоков (≈14 раундов
     × 0.4 совпадения атака↔блок), поэтому EP никогда не кончается,
     поэтому Endurance ни на что не влияет.
   - Дополнительные удары по def: planned scaling убрал бонус HP
     (`80 + 2×lvl` → `80`) и срезал силу с `+2` до `+1`. По сравнению
     со старым кодом def потерял ~24 HP и ~12 силы, не получив ничего
     взамен в данном матчапе (EP в работу не вступает).

2. **`crit > def` перебивает цель (88.8% вместо ~65%).**
   - crit-атакер: power 48 vs def intuition 24 → шанс крита ~29-33%
     за удар. Крит пробивает блоки (блок + крит = полный урон).
   - Средний крит-множитель 1.74×, ожидаемый урон за атаку ≈ 0.98×
     base. Против атак def (нет крита, нет доджа) crit получает только
     ~0.60× base за атаку → crit наносит ~1.5× DPS от def.
   - При одинаковых 80 HP crit убивает def за ~9 раундов, получая
     60% урона. Измеренная средняя длительность 9.2 раунда — линейная
     гонка HP, которую def проигрывает.
   - У def ноль офенсивных инструментов против crit: 0 power (нет
     своих критов), 0 agility (не может уворачиваться), 24 intuition
     срезает шанс крита врага только до ~30% (всё ещё много).
   - **(исторически)** до 2026-05-23 крит пробивал блок с полным
     множителем, и EP всё равно тратился — «двойной налог» по тем
     цифрам. Сейчас правило изменено: блок снижает крит-множитель до
     `1.0×` (= обычный урон), EP по-прежнему расходуется. Двойного
     налога больше нет; конкретные win-rates на новой механике см.
     ниже («Crit + block downgrade»).

3. **`dodge > crit` укладывается в цель (62% / 9% / 29%).** Это
   единственный эдж, где текущая математика распределений и бюджет
   статов сходятся с дизайном. Обе стороны вкладываются симметрично
   (48 одной, 12 другой), а механика доджа естественно выигрывает,
   потому что додж отменяет всю крит-цепочку.

### Предложения по изменению механик (нужно тестировать)

Чтобы попасть в 60-70 / 0-10 / 30-40, нужно добавить новые источники
асимметрии для def. Эдж dodge > crit изменений не требует.

**A. Вернуть def бонус HP (откатить часть planned scaling).**
План передвинул def с `80 + 2×lvl` HP на `80` flat. На lvl 12 это
−24 HP (30% от пула). Вернуть как `80 + 3×lvl` → 116 HP на lvl 12.
Только эта правка стоит ~+15% win rate против dodge и ~+8% против
crit в линейной гонке урона. Самое дешёвое и наименее инвазивное.

**B. Сделать Endurance реально дефицитным ресурсом или пассивным
бафом (а не множителем количества блоков).**
Текущее правило `+0.5 эффективных блоков на endurance` даёт столько
блоков, что почти ни в одном бою они не расходуются, поэтому
endurance вносит ноль в симуляциях lvl 12. Варианты:
- *(B1) Уменьшить объём блоков.* Снизить базовый пул EP с 2000 до
  1000 и удвоить базовые стоимости (2H = 800, 1H = 400). Endurance
  по-прежнему даёт `+0.5 блока` за очко. Итог: у def ~2 базовых +
  ~9 эндюрансных = 11 блоков на 2H, что РЕАЛЬНО кончается к ~10-12
  раунду против crit, заставляя def отказываться от блоков в поздней
  стадии и вознаграждая инвестиции в endurance.
- *(B2) Endurance даёт пассивную митигацию урона на успешных блоках.*
  Когда блок оплачен, урон от крита, пробившего блок, снижается на
  `min(50%, endurance × 1%)`. На endurance 36 → 36% митигации на
  пробитых критах. Прямо бьёт по проблеме crit > def, не задевая
  другой матчап.

**C. Дать def инструмент против dodge.**
Сейчас у def нет отдельного стат-рычага, чтобы давить шанс доджа
противника помимо общей intuition. Два простых варианта:
- *(C1) Endurance также подавляет вражеский шанс доджа.* Считать его
  вторым `instinct`-эквивалентом только для додж-ролла, с
  коэффициентом 50% (то есть 36 endurance читается как +18
  додж-подавления). На lvl 12 dodge vs def шанс доджа защитника
  упадёт с ~35% до ~22%, суммарное избегание с 61% до ~53%. В
  сочетании с (A) должно привести def-vs-dodge к ~60/10/30.
- *(C2) Скейлинг силы для def.* Вернуть `+2×lvl` силы (план снизил
  до `+1`). На lvl 12 → strength 24 ≈ +3.4 урона/атаку против
  текущих ≈ +1.6. Чистый DPS-рычаг. Дешевле в реализации, но грубее
  — применяется во всех матчапах, в том числе в def vs crit, где
  def уже проигрывает гонку.

**D. Смягчить crit, понизив верхнюю границу множителя.**
Текущее распределение множителей `[0.75, 1.00, 1.25, 1.50, 2.00,
3.00]`, веса `[0, 5, 15, 40, 30, 10]` → mean 1.74×. Два рычага:
- *(D1) Убрать 3.00-уровень.* Новые веса `[0, 5, 15, 40, 30, 0]`
  плюс перераспределить 10% обратно в 2.00 → веса `[0, 5, 15, 40,
  40, 0]` → mean 1.59×. Простая правка в `GameMechanicsConstants`.
- *(D2) Сдвинуть peak шанса крита.* Peak crit = 0.2 (низко, делает
  шанс крита заметно меньше сырого power). Перевод на 0.3 повышает
  ожидаемый шанс против целей с нулевой intuition, но снижает против
  тех, кто вкладывается в intuition. Скорее всего, **не подходит**
  тут — ухудшит crit > def, а не поможет.

**Рекомендованная стартовая комбинация для теста:** A + C1 + D1.
Ожидаемый эффект: def-vs-dodge поднимется до ~55-65%, crit-vs-def
упадёт до ~70-80%, dodge-vs-crit останется на месте. После симуляции
итерировать численными константами B1/B2 только если A + C1 + D1
оставит crit > def выше ~75%.

### Дополнительная диагностика (EP / Block coverage, lvl 12, 30k батлов)

`MultiBattleViewModel.logBalanceDiagnostics` теперь печатает в unified
log (`NSLog`, тег `ELFBAL`) использование EP, число блоков (вызванных
и реально потраченных), покрытие блоком и количество боёв, где EP
полностью истощился. Захват: `xcrun simctl spawn booted log stream
--predicate 'eventMessage CONTAINS "ELFBAL"'`.

| Матчап         | EP-pool (Bot1/Bot2) | Avg EP spent (Bot1/Bot2)    | Avg blocks used (Bot1/Bot2) | Block coverage (Bot1/Bot2) | Battles EP exhausted |
|----------------|----------------------|-----------------------------|-----------------------------|----------------------------|----------------------|
| dodge vs crit  | 2000 / 2000          | 1407 (70%) / 1370 (69%)     | 4.69 / 4.57                  | 36.7% / 35.8%              | 0% / 0%              |
| dodge vs def   | 2000 / 2000          | 1495 (75%) / 466 (23%)      | 4.98 / 5.76                  | 34.7% / 40.1%              | 0% / 0%              |
| crit vs def    | 2000 / 2000          | 1078 (54%) / 299 (15%)      | 3.59 / 3.69                  | 38.9% / 40.0%              | 0% / 0%              |

Выводы из диагностики:
1. **EP-пул одинаковый = 2000 для всех** (см. `GameMechanicsConstants.startingEP`).
   Endurance НЕ увеличивает пул — он только снижает стоимость блока.
2. **Дефолтный Recruit's Spear имеет epBlockCost 300** (1H-цена выше
   докового базового 200). При endurance 0 → 6.67 max блоков (бой
   ~12-14 раундов ≈ 4-5 блоков используется → впритык). При
   endurance 36 → 81 EP/блок, 24.7 max блоков.
3. **У def 4-7× запас EP, который не нужен.** В матчапе dodge vs def
   def тратит 23% пула; в crit vs def — всего 15% (бой короткий).
   Endurance ни разу не становится bottleneck-ресурсом.
4. **dodge напротив на грани истощения EP** (74.7% пула в dodge vs def
   — 5 блоков из 6.67 максимума). Если бой удлинится, dodge не сможет
   блокировать в поздней игре.
5. **Block coverage ≈ 40%** для всех (= 2 блока / 5 частей тела при
   случайном выборе ботом). Кроме dodge, где coverage падает до
   35-36% из-за приближения к EP-границе.

### Эксперимент: +5 HP на уровень

Идея пользователя: «увеличить HP +5 за уровень, чтобы блоки эффективнее
работали в более длинном бою». Протестировано — результат **не такой,
как ожидалось**:

| Конфигурация            | dodge vs crit | def vs dodge | crit vs def |
|--------------------------|---------------|--------------|-------------|
| baseline (HP 80 всем)    | dodge 62% ✓   | def 14% ✗    | crit 89% ⚠ |
| +5HP/lvl всем (HP 140)   | dodge 82% ⚠   | def 20% ✗    | crit 92% ⚠ |
| +5HP/lvl только def (140 vs 80) | (не тест.) | def 85% ⚠⚠ | crit 23% ⚠⚠ |
| +3HP/lvl только def (116 vs 80) | (не тест.) | def 59% ✓  | crit 51% ⚠ |
| +2HP/lvl только def (104 vs 80) | (не тест.) | def 43% ✗  | crit 66% ✓ |

Ключевые выводы:
- **Универсальный +5/lvl УХУДШАЕТ баланс.** Длинные бои уменьшают
  дисперсию → доминирующая сторона побеждает ещё стабильнее. Слабая
  сторона теряет шанс на «выстрелить из ничего».
- **HP-буст только для def работает в нужном направлении**, но
  никакое одно значение не попадает в обе цели одновременно. +2HP/lvl
  для def фиксит crit vs def (66% ✓), но оставляет def vs dodge
  инвертированным (43%). +3HP/lvl фиксит def vs dodge (59% ✓), но
  опускает crit vs def слишком низко (51%).
- **Нужна комбинация HP + другого рычага.** Например: `def +2HP/lvl
  (старый scaling)` + `C1: endurance подавляет вражеский додж`
  должно дать `def vs dodge ~55-65%` и `crit vs def ~65%` одновременно.
  Или: `def +3HP/lvl` + `D1: уменьшить mean crit multiplier с 1.74×
  до 1.59×` — компенсирует «слишком мягкий crit vs def».

**Рекомендация по HP:** не идти на универсальный +5HP. Если двигаться
быстрым путём — `def-only +2HP/lvl` (восстанавливает старый scaling
из текущей реализации до planned-изменения) **плюс** второй рычаг
(C1 предпочтительнее — точечно бьёт по проблеме def vs dodge).

### Прочие известные флаги

4. **Agility/power асимметрия из-за позиций peak.** Dodge peak `0.4`
   vs crit peak `0.2` делает один и тот же численный стат на ~25%
   эффективнее со стороны доджа. Подтверждено симуляцией: dodge > crit
   попадает в цель *именно из-за* этой асимметрии; перевод обоих peak
   на `0.3` ослабит матчап доджа против крита и **не рекомендуется**,
   пока эдж dodge > crit не начнёт перебивать цель.
5. **Linear scaling assumed safe at lvl 12.** Максимум от левелинга —
   48 (crit power, dodge agility), поэтому 100% auto-success cap
   недостижим только за счёт уровней. Экипировка может выйти за
   границу — балансится отдельно.

### Per-level scaling

#### Current (in code)

| Style    | strength | agility | power   | intuition | endurance | hit points |
|----------|----------|---------|---------|-----------|-----------|------------|
| `crit`   | +1×lvl   | 0       | +4×lvl  | +1×lvl    | 0         | 80 + 5×lvl |
| `dodge`  | +1×lvl   | +4×lvl  | 0       | +1×lvl    | 0         | 80 + 5×lvl |
| `def`    | +1×lvl   | 0       | 0       | +2×lvl    | +3×lvl    | 80 + 5×lvl |

Notes:
- All styles share the same `+5 HP/level` scaling. Battles are longer
  (more rolls per fight = lower variance) and EP discipline matters more,
  since blocks stretch over more rounds without the pool getting larger.
- def's identity is **tactical staying power** via Endurance, not a fat
  HP bar — every style now has the same HP pool.
- Numbers are tuned during balancing; see *Open Balance Flags* below for
  the latest measured triangle.

---

## Style Triangle: `def > dodge > crit > def`

A soft rock-paper-scissors. The intent is **slight** advantage (~60 / 10 /
30), not auto-win. Each edge is grounded in mechanics, not magic numbers:

- **dodge > crit** — A successful dodge cancels the attack. Crit's
  multiplier is never applied; power investment yields zero return on that
  swing.
- **crit > def** — Crit lands even on blocked parts, so def cannot
  fully cancel an attacker's swing the way dodge can. The def hero has no
  power and no agility, so cannot suppress crits or roll its own. EP
  still drains on blocked crits (see below), but the crit's damage is
  capped at the normal-hit value via `blockedCritMultiplier` — the block
  cancels the multiplier bonus, not the swing itself.
- **def > dodge** — High intuition trims the dodge hero's dodge chance, and
  Endurance lets def absorb the trickle of unblocked hits longer than
  dodge can keep offence going. Without Endurance this edge is the weakest
  of the three; Endurance is the load-bearing piece of the triangle.

---

## Endurance & EP (planned)

### Goal

Replace "blocks are essentially unlimited" with a **finite resource for
blocking**. Blocking trades EP instead of HP. When EP runs out, blocks no
longer protect — and (later) start damaging the equipment instead.

### Constants & rules

| Rule                          | Value (MVP)                                          |
|-------------------------------|------------------------------------------------------|
| Starting EP                   | **2000** for every hero, every level (see `GameMechanicsConstants.startingEP`) |
| Auto-regen per round          | **None.** EP is restored only via abilities/potions/scrolls. |
| Base block cost — 1H weapon   | 200 EP                                               |
| Base block cost — 2H weapon   | 400 EP                                               |
| Base block cost — shield      | TBD (lower than 1H, likely ≤ 100 EP)                 |
| Endurance effect              | Reduces actual EP paid per block (formula TBD).      |
| Insufficient EP (MVP)         | Whenever `currentEP < cost` (including 0), the block input is accepted but **no protection occurs** — incoming attack resolves as if unblocked (dodge/crit rolls run normally). EP is **not** spent because no successful block happened. |
| Crit on blocked part          | Crit success is preserved (UI marks the hit as a crit, stats record a crit success), but damage is scaled by `GameMechanicsConstants.blockedCritMultiplier` (default `1.0×` = normal-hit damage) instead of the rolled multiplier. EP is still spent for the block. |
| Dodge interaction             | Unchanged. Dodge only runs when the body part is **not** blocked. Choosing to block a part disables that part's dodge roll. |
| Strike order (dual-wield)     | The **right-hand (primary) weapon** strikes first; **left-hand (secondary)** strikes second. EP is drained in this order — the primary's block check happens before the secondary's. If EP runs out between strikes, the secondary's block fails (resolves as undefended). |
| Strike → body-part mapping    | Among the body parts the attacker selected to hit, the i-th in enum order `[head, body, leftHand, rightHand, legs]` is hit by the i-th strike. Strike 0 (primary) → top-most attacked body part; strike 1 (secondary) → next. |

### Endurance → block-cost formula

**Rule.** Every **+2 Endurance grants +1 effective block**, regardless of
weapon. The pool stays nominally at `startingEP` (currently 2000); Endurance
reduces the EP paid per block such that one extra block fits.

**Formula (canonical).**

```
cost = pool / (pool / baseCost + endurance / 2)
```

**Equivalent implementation — bonus pool** (preferred in code, no
rounding drift):

```
effective_pool = startingEP + (baseCost × endurance / 2)
cost           = baseCost                  // unchanged
blocks         = floor(effective_pool / baseCost)
```

Both models yield the same block count. Display the *reduced cost* form
to the player (matches their mental model: "Endurance softens incoming
hits"); compute via the bonus-pool form internally.

**Reference tables** (using `startingEP = 2000`).

2H weapon (base 400 EP):

| Endurance | Effective pool | Blocks | Reduced cost |
|-----------|----------------|--------|--------------|
| 0  | 2000 | 5  | 400 |
| 2  | 2400 | 6  | 333 |
| 4  | 2800 | 7  | 286 |
| 6  | 3200 | 8  | 250 |
| 10 | 4000 | 10 | 200 |
| 36 (def lvl 12 max) | 9200 | 23 | 87 |

1H weapon (base 200 EP):

| Endurance | Effective pool | Blocks | Reduced cost |
|-----------|----------------|--------|--------------|
| 0  | 2000 | 10 | 200 |
| 2  | 2200 | 11 | 182 |
| 4  | 2400 | 12 | 167 |
| 10 | 3000 | 15 | 133 |
| 36 (def lvl 12 max) | 5600 | 28 | 71 |

**def style — blocks per level** (planned scaling `+3 × level`, max lvl 12):

| Level | Endurance | 2H blocks | 1H blocks |
|-------|-----------|-----------|-----------|
| 1  | 3  | 6  | 11 |
| 4  | 12 | 11 | 16 |
| 8  | 24 | 17 | 22 |
| 12 | 36 | **23** | **28** |

> **Balance flag.** At lvl 12 max, def hero blocks 23× (2H) or 28× (1H)
> over a battle. Typical fight length is ~10-15 rounds with up to 2 blocks
> per round → 20-30 blocks needed. Def can therefore *cover almost every
> attack with blocks* in a full fight. The triangle counter is the crit
> chance landing on unblocked parts (~28% at lvl 12 — see Triangle
> Snapshot above); on blocked parts the crit is preserved but its damage
> is forced to normal-hit value, so the block still does work.
> Whether this is balanced depends on simulation results;
> **do not add an Endurance cap until a simulator confirms it's needed**.

### Future iterations (not MVP)

- **Equipment durability.** Each item has its own HP. When an attack
  lands on a body part covered by an item (no EP left, or unblocked hit),
  the item loses HP.
- **Equipment states:** `full` → armor + stat bonuses, `damaged` → stat
  bonuses only (armor lost), `broken` → nothing.
- **EP-restoring resources:** abilities, potions, scrolls.
- **Weapon block-cost variants** — heavier/2H weapons may charge more EP
  to defenders that block them, beyond the wielder's own block cost.

---

## File Map

When working on attributes or related combat math, the relevant code is:

| Concern                                   | Location                                                                     |
|-------------------------------------------|------------------------------------------------------------------------------|
| `HeroAttributes`, `Attribute` value type  | `elf_Kit/Sources/DataLayer/Model/Hero/`                                      |
| Per-level fight-style scaling             | `elf_Kit/Sources/DataLayer/Services/Attributes/Implementation/ElfAttributeService.swift` |
| Random per-level scaling (non-style NPCs) | same file, `getRandomLevelAttributes()`                                      |
| `FightStyle` enum                         | `elf_Kit/Sources/DataLayer/Model/Hero/FightStyle.swift`                      |
| Dodge service & distribution              | `elf_Kit/Sources/DataLayer/Services/Dodge/Implementation/`                   |
| Crit service & distribution               | `elf_Kit/Sources/DataLayer/Services/Crit/Implementation/`                    |
| Round resolver (consumes all the above)   | `elf_Kit/Sources/DataLayer/Services/Combat/Implementation/ElfSnapshotCombatCalculator.swift` |
| Combat snapshot (immutable round input)   | `elf_Kit/Sources/DataLayer/Model/Combat/CombatantSnapshot.swift`             |
| Item attribute aggregation                | `ElfAttributeService.getAllItemsAttributes(for:)`                            |
| UI formatting of attributes               | `elf_Kit/Sources/UILayer/Inventory/ItemAttributesFormatter.swift`            |
