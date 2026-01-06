# Type-Driven Design (TDD) Guide

> Based on Alex Ozun's presentation "Type-Driven Design in Swift"

## Core Principle

**"Make impossible states unrepresentable"** — используй систему типов Swift для того, чтобы невалидные состояния не могли существовать в принципе.

---

## 1. Using Types to Model Requirements

### Проблема: Shotgun Parsing
Валидация смешана с бизнес-логикой, инварианты теряются сразу после проверки.

```swift
// BAD: Инвариант (валидный email) теряется после guard
func signIn(email: String, password: String) {
    guard isValidEmail(email) && password.count >= 8 else { return }
    // Здесь email — просто String, валидность не гарантирована типом
}
```

### Решение: Захват инварианта в типе

```swift
// GOOD: Тип гарантирует валидность
struct Email {
    let value: String

    private init(_ value: String) { self.value = value }

    static func parse(_ raw: String) -> Result<Email, ValidationError> {
        guard raw.contains("@") else { return .failure(.invalidFormat) }
        return .success(Email(raw))
    }
}

func signIn(credentials: Credentials) -> Result<User, AuthError> {
    // credentials.email ВСЕГДА валиден — математическая гарантия
}
```

### Curry-Howard Correspondence

| Программирование | Логика |
|------------------|--------|
| Типы | Теоремы/Пропозиции |
| Значения типов | Доказательства |
| Функции | Следствия (implications) |
| Struct (A, B) | Конъюнкция (A ∧ B) |
| Enum (A \| B) | Дизъюнкция (A ∨ B) |

---

## 2. Patterns of Data Types

### 2.1 Simple Wrapper
Обёртка без валидации, для type-safety.

```swift
struct BearerToken {
    let value: String
}

// НЕ путать с typealias — он НЕ создаёт новый тип!
typealias Token = String  // ЭТО НЕ НОВЫЙ ТИП!
```

### 2.2 Wrapper with Parser
Обёртка с валидацией при создании.

```swift
struct CharacterName: Sendable, Equatable, Codable {
    let value: String

    private init(_ value: String) { self.value = value }

    static func parse(_ raw: String) -> Result<CharacterName, NameValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return .failure(.tooShort) }
        guard trimmed.count <= 30 else { return .failure(.tooLong) }
        return .success(CharacterName(trimmed))
    }
}
```

### 2.3 Product Type (Combination)
Struct = A AND B

```swift
struct Credentials {
    let email: Email      // Email И Password
    let password: Password
}
```

### 2.4 Sum Type (Choice)
Enum = A OR B

```swift
enum User {
    case anonymous(AnonymousUser)
    case signedIn(SignedInUser)  // Anonymous ИЛИ SignedIn
}
```

**Anti-pattern: Frankenstein Struct**
```swift
// BAD: Много optionals = несколько типов в одном
struct User {
    let sessionId: UUID
    let id: UserID?        // Optional означает "это может быть другой тип"
    let username: String?
}

// GOOD: Используй enum
enum User {
    case anonymous(sessionId: UUID)
    case signedIn(id: UserID, username: String)
}
```

### 2.5 Phantom Types (Tagged Wrapper)
Type-safety без runtime overhead.

```swift
struct TypedID<Tag>: Hashable, Codable {
    let rawValue: UUID
}

enum ElfTag {}
enum MonsterTag {}

typealias ElfID = TypedID<ElfTag>
typealias MonsterID = TypedID<MonsterTag>

// Теперь нельзя перепутать!
func findElf(id: ElfID) -> Elf?
func findMonster(id: MonsterID) -> Monster?

// findElf(id: monsterId)  // Ошибка компиляции!
```

### 2.6 NonEmpty Collection
Гарантированно непустая коллекция.

```swift
struct NonEmptyArray<Element> {
    let first: Element
    let rest: [Element]

    var asArray: [Element] { [first] + rest }
}

// Функция становится ПОЛНОЙ — всегда может вернуть результат
func findBest(in videos: NonEmptyArray<Video>) -> Video {
    // Гарантированно есть хотя бы одно видео
}
```

---

## 3. Patterns of Function Types

### Parser
Частичная функция — может вернуть ошибку.

```swift
static func parse(_ raw: String) -> Result<Email, ValidationError>
```

### Calculator/Transformer
Полная чистая функция — всегда даёт результат.

```swift
func isEven(_ number: Int) -> Bool {
    number % 2 == 0
}
```

### Decision Maker
Возвращает решение, но НЕ выполняет его.

```swift
func getActions(for launchCount: Int) -> [Action] {
    switch launchCount {
    case 0: return [.showOnboarding]
    case 5: return [.showFeedback]
    default: return []
    }
}
```

### Executor/Performer
Выполняет side effects.

```swift
func perform(_ action: Action) {
    switch action {
    case .showOnboarding: navigator.show(OnboardingVC())
    case .showFeedback: navigator.show(FeedbackVC())
    }
}
```

---

## 4. Making Partial Functions Total

### Определения
- **Полная функция** — даёт ответ на ЛЮБОЙ валидный input
- **Частичная функция** — может упасть, вернуть nil, или зациклиться

```swift
// Частичная — crash при b == 0
func divide(_ a: Int, by b: Int) -> Int { a / b }

// Полная — работает для любого Int
func isEven(_ n: Int) -> Bool { n % 2 == 0 }
```

### Решение: Ограничь input через типы

```swift
// Частичная: пустой массив → nil пузырится наверх
func findBest(in videos: [Video]) -> Video?

// Полная: NonEmpty гарантирует хотя бы один элемент
func findBest(in videos: NonEmptyArray<Video>) -> Video
```

---

## 5. Making Impure Functions Pure

### Functional Sandwich

```
┌─────────────────────────┐
│   Side Effects (input)  │  ← Достаём данные
├─────────────────────────┤
│   Pure Business Logic   │  ← Чистая логика (тестируемая!)
├─────────────────────────┤
│   Side Effects (output) │  ← Выполняем действия
└─────────────────────────┘
```

### Пример

```swift
// BEFORE: Нечистая функция, невозможно тестировать
func handleAppLaunch() {
    let count = UserDefaults.standard.integer(forKey: "launchCount")
    UserDefaults.standard.set(count + 1, forKey: "launchCount")
    if count == 0 { showOnboarding() }
}

// AFTER: Functional Sandwich
enum Action {
    case setUserDefaults(key: String, value: Int)
    case showOnboarding
}

// ЧИСТАЯ функция — легко тестировать!
func getActions(for launchCount: Int) -> [Action] {
    var actions: [Action] = [.setUserDefaults(key: "launchCount", value: launchCount + 1)]
    if launchCount == 0 { actions.append(.showOnboarding) }
    return actions
}

// Нечистая — только выполнение
func perform(_ action: Action) {
    switch action {
    case .setUserDefaults(let key, let value):
        UserDefaults.standard.set(value, forKey: key)
    case .showOnboarding:
        navigator.show(OnboardingVC())
    }
}

// Собираем вместе
func handleAppLaunch() {
    let count = UserDefaults.standard.integer(forKey: "launchCount")  // Side effect
    let actions = getActions(for: count)                               // Pure
    actions.forEach(perform)                                           // Side effect
}
```

### Unit-тесты стали тривиальными!

```swift
func testFirstLaunch() {
    let actions = getActions(for: 0)
    XCTAssertEqual(actions, [
        .setUserDefaults(key: "launchCount", value: 1),
        .showOnboarding
    ])
}
```

---

## 6. Value-Oriented Programming

Вместо контроля потока (if/else, callbacks) работаем со значениями.

```swift
// Обогащаем действия событиями
struct LoggableAction {
    let action: Action
    let event: AnalyticsEvent?
}

func getEvent(for action: Action) -> AnalyticsEvent? {
    switch action {
    case .showOnboarding: return .onboardingShown
    default: return nil
    }
}

// Хотим убрать логирование? Просто убираем одну строку!
actions.forEach(perform)  // Без логов
```

---

## 7. Functional Dependency Injection

### Вместо протоколов — передаём функции

```swift
// Protocol-based (много boilerplate)
protocol UserDefaultsStorable {
    func integer(forKey: String) -> Int
}

// Function-based (простое)
func perform(
    _ action: Action,
    setUserDefaults: (Int, String) -> Void = { UserDefaults.standard.set($0, forKey: $1) }
) { ... }

// В тестах
func testAction() {
    var captured: (Int, String)?
    perform(.setUserDefaults(key: "test", value: 42)) { value, key in
        captured = (value, key)
    }
    XCTAssertEqual(captured?.0, 42)
}
```

### Объединяем зависимости в структуру

```swift
struct Dependencies {
    var getUserDefaultsInt: (String) -> Int = { UserDefaults.standard.integer(forKey: $0) }
    var setUserDefaultsInt: (Int, String) -> Void = { UserDefaults.standard.set($0, forKey: $1) }
    var log: (String) -> Void = { print($0) }
}

// Можно подменить ЛЮБУЮ зависимость по отдельности!
var deps = Dependencies()
deps.log = { _ in }  // Отключили логи
```

---

## 8. Modeling Async Actions

### Рекурсивный enum для цепочек

```swift
indirect enum Action {
    case showOnboarding
    case showError(Error)

    case asyncFetch(
        onSuccess: Action,
        onFailure: Action
    )
}

func perform(_ action: Action) {
    switch action {
    case .asyncFetch(let onSuccess, let onFailure):
        api.fetch { result in
            switch result {
            case .success: perform(onSuccess)
            case .failure: perform(onFailure)
            }
        }
    // ...
    }
}
```

---

## 9. Advanced: Witness Pattern

Доказательство через существование типа.

```swift
struct Witness<T> {
    // Пустая структура! Значение не используется.
    // Сам факт существования — доказательство.
}

enum Action {
    case showOnboarding(Witness<OnboardingVC>)
    case showFeedback(Witness<FeedbackVC>)
}

func showOnboarding(_ witness: Witness<OnboardingVC>) {
    // witness не используется — важен только его ТИП
    navigator.show(OnboardingVC())
}

func perform(_ action: Action) {
    switch action {
    case .showOnboarding(let witness):
        showOnboarding(witness)  // Компилятор проверяет тип!

        // showFeedback(witness)  // Ошибка компиляции!
    }
}
```

---

## Elfy Project Rules

### Always Use

1. **Phantom Types for IDs**
   ```swift
   typealias ElfID = TypedID<ElfIDType>
   typealias MonsterID = TypedID<MonsterIDType>
   ```

2. **Wrapper Types for Validated Values**
   ```swift
   CharacterName.parse(rawInput)  // Result<CharacterName, Error>
   ActionPoints.create(current: 5, maximum: 10)
   ```

3. **Sum Types for Mutually Exclusive States**
   ```swift
   enum WeaponConfiguration {
       case oneHanded(weapon: ElfWeaponItem)
       case twoHanded(weapon: ElfWeaponItem)
       case dualWield(primary: ElfWeaponItem, secondary: ElfWeaponItem)
   }
   ```

4. **NonEmptyArray for Required Collections**
   ```swift
   func calculateDamage(distribution: NonEmptyArray<DamageValue>) -> Damage
   ```

5. **Attribute Type for Game Stats**
   ```swift
   struct HeroAttributes {
       let strength: Attribute  // Not Int16!
       let agility: Attribute
   }
   ```

### Never Use

1. **Raw UUID for Entity IDs**
   ```swift
   // BAD
   func findElf(id: UUID) -> Elf?

   // GOOD
   func findElf(id: ElfID) -> Elf?
   ```

2. **Multiple Optionals for Variants**
   ```swift
   // BAD: Frankenstein struct
   struct Item {
       var weaponDamage: Int?  // Only for weapons
       var armorValue: Int?    // Only for armor
   }

   // GOOD: Sum type
   enum Item {
       case weapon(damage: Int)
       case armor(value: Int)
   }
   ```

3. **Stringly Typed Values**
   ```swift
   // BAD
   let fightStyle: String  // "crit", "dodge", "def"

   // GOOD
   let fightStyle: FightStyle  // enum
   ```

4. **Validation Spread Across Codebase**
   ```swift
   // BAD: validation in multiple places
   if name.count >= 2 && name.count <= 30 { ... }

   // GOOD: validation at parse time, once
   CharacterName.parse(raw)
   ```

---

## Type Checklist

Before creating a new type, ask:

1. Can this value be invalid? → **Wrapper with Parser**
2. Is this an ID that could be confused? → **Phantom Type**
3. Are there mutually exclusive states? → **Sum Type (enum)**
4. Must this collection have elements? → **NonEmptyArray**
5. Is this a numeric value with constraints? → **Wrapper Type**

---

## Resources

- Scott Wlaschin — "Domain Modeling Made Functional"
- Alexis King — "Parse, don't validate"
- Point-Free (pointfree.co)
- swift-tagged, swift-nonempty libraries
