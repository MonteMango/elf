---
status: Accepted
owner: "Vitalii Lytvynov"
reviewers: []
updated_at: "2026-08-13"
feature_size: "XS"
ticket: "view-viewmodel-boundary-fix"
---

# 0001 — Host dungeon-run completion logic directly on GameSession

- **Status:** Accepted
- **Date:** 2026-08-13
- **Deciders:** Vitalii Lytvynov (во время Socratic-прохода `design`)

## Context

`DungeonScreen` (кнопка Finish) и `BattleResultScreen` (продолжение после гибели героя) сегодня независимо вызывают идентичную пару `gameSession.finishDungeonRun()` + `gameSession.saveInBackground()` напрямую из View, в обход своего ViewModel — это одно из четырёх мест, нарушающих View→ViewModel-границу (spec.md §1/§2, находки V-2/V-3 архитектурного обзора). `DungeonViewModel` уже хранит `gameSession` в своём `init`, поэтому расширить его тривиально. Но `BattleResultViewModel` — это `typealias BattleResultViewModel = ResultViewModel<T>`, generic-тип с собственным doc-комментарием «Generic ViewModel for displaying results (fishing, foraging, battle, etc.). Simply holds a result value for presentation» (`ResultViewModel.swift:10-14`) — сегодня в кодовой базе используется только как `ResultViewModel<ManualBattleResult>`, но документирован как переиспользуемый. Нужно решить, где живёт эта единая логика завершения, чтобы удовлетворить spec §6 NFR «Единое владение завершением Finish» (обе точки вызывают одну и ту же реализацию, без дублирования).

## Decision drivers

- spec §6 NFR «Единое владение завершением Finish» — путь Finish и путь гибели героя обязаны вызывать одну и ту же логику, без дублирующейся реализации выплаты+сохранения.
- spec Goal #1 (§2) — ноль мест в слое View, мутирующих `GameSession`/`DungeonSession` напрямую.
- Явный архитектурный doc-комментарий класса `GameSession` (`GameSession.swift:11-21`): «Views and ViewModels go through `GameSession` exclusively... There is no separate "service" layer underneath — the mutation logic lives directly in this type.» — существующая, установленная конвенция именно для этого типа.
- `architecture-map.md` §Frontend / UI foundation — правило переиспользования: новая единица логики не должна портить переиспользуемость уже существующего generic-типа без необходимости.

## Considered options

1. **Метод на `GameSession`** — новый `completeDungeonRun()`, оборачивающий уже существующие `finishDungeonRun()` + `saveInBackground()` с ранним return при отсутствии активного забега; `DungeonViewModel` вызывает его напрямую (уже держит `gameSession`), для `BattleResultScreen` заводится новый маленький session-aware companion ViewModel, вызывающий тот же метод.
2. **Отдельный DI-инжектируемый `@MainActor`-сервис** (например `DungeonRunCompleter`, протокол + `liveValue`, по образцу существующих Builders/Validators/Mutators) — сам вызывает `session.finishDungeonRun()` + `.saveInBackground()`, session передаётся параметром; инжектируется и в `DungeonViewModel`, и в новый companion VM для `BattleResultScreen`.
3. **Расширить сам `BattleResultViewModel`** опциональной ссылкой на `GameSession` — реальная развилка, которую spec.md §8 прямо называет открытым вопросом, оставленным на усмотрение `design`. Отклонена по драйверам выше: она полностью удовлетворила бы NFR-требование, но напрямую противоречит документированной цели типа как generic display-only presentation VM (`ResultViewModel<T>`, «просто хранит результат для отображения»), переиспользуемого для fishing/foraging/battle — каждый будущий не-подземельный вызов был бы вынужден передавать `session: nil` и знать про эту dungeon-специфичную деталь.

## Decision outcome

**Chosen:** Option 1 — метод `completeDungeonRun()` на `GameSession`. Оба независимых консультанта (SwiftUI и Swift-concurrency), не видевшие исходный код `GameSession.swift`, предложили Option 2 (отдельный DI-сервис) по общей лучшей практике DI в этом проекте (Builders/Validators/Calculators/Resolvers всегда через `@Dependency`). Но явный архитектурный комментарий на самом классе `GameSession` — прямое указание проекта, которое перевешивает общий совет (project rules win, per `_shared/consultant-fold.md`): мутационная и persistence-логика уже структурно обязана жить на `GameSession`, а не в отдельном сервисном слое. Option 1 — меньший диф (без нового типа/файла/DI-регистрации), для 2-строчной оркестровки, которую `GameSession` и так уже структурно обязан нести.

## Consequences

**Positive**
- Соответствует существующей документированной архитектуре `GameSession` («no separate service layer underneath»).
- Минимальный диф: один новый метод на уже существующем типе, без нового файла/протокола/DI-регистрации.
- Ранний return при отсутствии активного забега (AC-03/AC-04) реализуется одним guard'ом в одном месте и переиспользуется всеми вызывающими сторонами.

**Negative**
- Публичная поверхность `GameSession` растёт ещё на один метод (хотя по форме идентичен уже существующим `finishDungeonRun()`/`bankDungeonRewardsOnDeath()`/`saveInBackground()`).
- `BattleResultScreen` получает второй `@State`-ViewModel (генерический display-only + новый session-aware companion) вместо одного — прецедент есть (`GameDayScreen` уже держит `viewModel` + `inventoryViewModel`), но это дополнительная точка внимания при чтении экрана.

**Neutral**
- Если оркестровка вырастет сложнее двух вызовов, миграция на отдельный DI-сервис (Option 2) в будущем остаётся возможной — потребует вынести тело метода в новый тип, не меняя форму вызова со стороны ViewModels.

## Links

- Spec: [[../spec.md]]
- SAD: [[../sad.md]] §4
- Related ADR: none
