# Type-Driven Design (TDD) Guide

> Based on Alex Ozun's presentation "Type-Driven Design in Swift"

## Core Principle

**"Make impossible states unrepresentable"** — use Swift's type system to make invalid states impossible to exist in the first place.

---

## 1. Using Types to Model Requirements

### Problem: Shotgun Parsing
Validation is mixed with business logic, invariants are lost immediately after checking.

```swift
// BAD: Invariant (valid email) is lost after guard
func signIn(email: String, password: String) {
    guard isValidEmail(email) && password.count >= 8 else { return }
    // Here email is just a String, validity is not guaranteed by the type
}
```

### Solution: Capture Invariant in Type

```swift
// GOOD: Type guarantees validity
struct Email {
    let value: String

    private init(_ value: String) { self.value = value }

    static func parse(_ raw: String) -> Result<Email, ValidationError> {
        guard raw.contains("@") else { return .failure(.invalidFormat) }
        return .success(Email(raw))
    }
}

func signIn(credentials: Credentials) -> Result<User, AuthError> {
    // credentials.email is ALWAYS valid — mathematical guarantee
}
```

### Curry-Howard Correspondence

| Programming | Logic |
|------------------|--------|
| Types | Theorems/Propositions |
| Values of types | Proofs |
| Functions | Implications |
| Struct (A, B) | Conjunction (A ∧ B) |
| Enum (A \| B) | Disjunction (A ∨ B) |

---

## 2. Patterns of Data Types

### 2.1 Simple Wrapper
Wrapper without validation, for type-safety.

```swift
struct BearerToken {
    let value: String
}

// DON'T confuse with typealias — it does NOT create a new type!
typealias Token = String  // THIS IS NOT A NEW TYPE!
```

### 2.2 Wrapper with Parser
Wrapper with validation at creation.

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
    let email: Email      // Email AND Password
    let password: Password
}
```

### 2.4 Sum Type (Choice)
Enum = A OR B

```swift
enum User {
    case anonymous(AnonymousUser)
    case signedIn(SignedInUser)  // Anonymous OR SignedIn
}
```

**Anti-pattern: Frankenstein Struct**
```swift
// BAD: Many optionals = multiple types in one
struct User {
    let sessionId: UUID
    let id: UserID?        // Optional means "this could be a different type"
    let username: String?
}

// GOOD: Use enum
enum User {
    case anonymous(sessionId: UUID)
    case signedIn(id: UserID, username: String)
}
```

### 2.5 Phantom Types (Tagged Wrapper)
Type-safety without runtime overhead.

```swift
struct TypedID<Tag>: Hashable, Codable {
    let rawValue: UUID
}

enum ElfTag {}
enum MonsterTag {}

typealias ElfID = TypedID<ElfTag>
typealias MonsterID = TypedID<MonsterTag>

// Now you can't mix them up!
func findElf(id: ElfID) -> Elf?
func findMonster(id: MonsterID) -> Monster?

// findElf(id: monsterId)  // Compile error!
```

### 2.6 NonEmpty Collection
Guaranteed non-empty collection.

```swift
struct NonEmptyArray<Element> {
    let first: Element
    let rest: [Element]

    var asArray: [Element] { [first] + rest }
}

// Function becomes TOTAL — can always return a result
func findBest(in videos: NonEmptyArray<Video>) -> Video {
    // Guaranteed to have at least one video
}
```

---

## 3. Patterns of Function Types

### Parser
Partial function — can return an error.

```swift
static func parse(_ raw: String) -> Result<Email, ValidationError>
```

### Calculator/Transformer
Total pure function — always produces a result.

```swift
func isEven(_ number: Int) -> Bool {
    number % 2 == 0
}
```

### Decision Maker
Returns a decision, but does NOT execute it.

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
Executes side effects.

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

### Definitions
- **Total function** — returns an answer for ANY valid input
- **Partial function** — can crash, return nil, or loop forever

```swift
// Partial — crash when b == 0
func divide(_ a: Int, by b: Int) -> Int { a / b }

// Total — works for any Int
func isEven(_ n: Int) -> Bool { n % 2 == 0 }
```

### Solution: Restrict Input Through Types

```swift
// Partial: empty array → nil bubbles up
func findBest(in videos: [Video]) -> Video?

// Total: NonEmpty guarantees at least one element
func findBest(in videos: NonEmptyArray<Video>) -> Video
```

---

## 5. Making Impure Functions Pure

### Functional Sandwich

```
┌─────────────────────────┐
│   Side Effects (input)  │  ← Get data
├─────────────────────────┤
│   Pure Business Logic   │  ← Pure logic (testable!)
├─────────────────────────┤
│   Side Effects (output) │  ← Execute actions
└─────────────────────────┘
```

### Example

```swift
// BEFORE: Impure function, impossible to test
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

// PURE function — easy to test!
func getActions(for launchCount: Int) -> [Action] {
    var actions: [Action] = [.setUserDefaults(key: "launchCount", value: launchCount + 1)]
    if launchCount == 0 { actions.append(.showOnboarding) }
    return actions
}

// Impure — only execution
func perform(_ action: Action) {
    switch action {
    case .setUserDefaults(let key, let value):
        UserDefaults.standard.set(value, forKey: key)
    case .showOnboarding:
        navigator.show(OnboardingVC())
    }
}

// Put it together
func handleAppLaunch() {
    let count = UserDefaults.standard.integer(forKey: "launchCount")  // Side effect
    let actions = getActions(for: count)                               // Pure
    actions.forEach(perform)                                           // Side effect
}
```

### Unit tests became trivial!

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

Instead of control flow (if/else, callbacks), work with values.

```swift
// Enrich actions with events
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

// Want to remove logging? Just remove one line!
actions.forEach(perform)  // Without logs
```

---

## 7. Functional Dependency Injection

### Instead of protocols — pass functions

```swift
// Protocol-based (lots of boilerplate)
protocol UserDefaultsStorable {
    func integer(forKey: String) -> Int
}

// Function-based (simple)
func perform(
    _ action: Action,
    setUserDefaults: (Int, String) -> Void = { UserDefaults.standard.set($0, forKey: $1) }
) { ... }

// In tests
func testAction() {
    var captured: (Int, String)?
    perform(.setUserDefaults(key: "test", value: 42)) { value, key in
        captured = (value, key)
    }
    XCTAssertEqual(captured?.0, 42)
}
```

### Combine dependencies into a struct

```swift
struct Dependencies {
    var getUserDefaultsInt: (String) -> Int = { UserDefaults.standard.integer(forKey: $0) }
    var setUserDefaultsInt: (Int, String) -> Void = { UserDefaults.standard.set($0, forKey: $1) }
    var log: (String) -> Void = { print($0) }
}

// Can substitute ANY dependency individually!
var deps = Dependencies()
deps.log = { _ in }  // Disabled logs
```

---

## 8. Modeling Async Actions

### Recursive enum for chains

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

Proof through type existence.

```swift
struct Witness<T> {
    // Empty struct! The value is not used.
    // The mere existence is the proof.
}

enum Action {
    case showOnboarding(Witness<OnboardingVC>)
    case showFeedback(Witness<FeedbackVC>)
}

func showOnboarding(_ witness: Witness<OnboardingVC>) {
    // witness is not used — only its TYPE matters
    navigator.show(OnboardingVC())
}

func perform(_ action: Action) {
    switch action {
    case .showOnboarding(let witness):
        showOnboarding(witness)  // Compiler checks the type!

        // showFeedback(witness)  // Compile error!
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
