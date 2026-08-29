//
//  BattleSetupViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class BattleSetupViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let itemsRepository: any ItemsRepository
    private let attributeService: any AttributeService
    private let armorService: any ArmorService
    private let damageService: any DamageService
    private let weaponValidator: any WeaponValidator
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let monsterRepository: any MonsterRepository

    // MARK: - State

    public var presentedItemSelector: ItemSelectorState?

    /// Selected opponent type (elf or monster)
    public var selectedOpponent: OpponentSelection = .elf

    /// All available monsters for the picker
    public private(set) var allMonsters: [Monster] = []

    /// When `false`, random per-level attributes are not generated — only
    /// fight-style attributes (scaled by level) contribute to totals. Default
    /// `false` so dev battles are deterministic; toggle on to mimic the
    /// regular character creation roll.
    /// Toggling this changes `attributesKey(for:)` for both heroes, so the
    /// view's `.task(id:)` re-runs the debounced recompute. No manual
    /// scheduling needed.
    public var includeRandomAttributes: Bool = false

    // Hero configurations
    public var playerState = HeroConfigurationState()
    public var botState = HeroConfigurationState()

    // MARK: - Private State

    /// Debounce window for recomputing attributes/equipment while the user is
    /// rapidly editing. The wait itself lives inside `applyAttributes`/
    /// `applyEquipment`; cancellation is handled by SwiftUI's `.task(id:)`,
    /// so no task handles are stored here.
    private let debounceDelay: Duration = .milliseconds(250)

    // MARK: - Hero Type Accessors

    private func state(for heroType: HeroType) -> HeroConfigurationState {
        heroType == .player ? playerState : botState
    }

    private func level(for heroType: HeroType) -> Int {
        state(for: heroType).level
    }

    private func fightStyle(for heroType: HeroType) -> FightStyle? {
        state(for: heroType).fightStyle
    }

    private func selectedItems(for heroType: HeroType) -> [HeroItemType: UUID?] {
        state(for: heroType).selectedItems
    }

    private func setFightStyleAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        state(for: heroType).fightStyleAttributes = attrs
    }

    private func setLevelRandomAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        state(for: heroType).levelRandomAttributes = attrs
    }

    private func setTwoHandedWeaponId(_ id: UUID?, for heroType: HeroType) {
        state(for: heroType).twoHandedWeaponId = id
    }

    private func setItemsAttributes(_ attrs: HeroAttributes?, for heroType: HeroType) {
        state(for: heroType).itemsAttributes = attrs
    }

    private func setArmorValues(_ values: [BodyPart: Int16], for heroType: HeroType) {
        state(for: heroType).armorValues = values
    }

    private func setLeftHandDamage(_ damage: (minDmg: Int16, maxDmg: Int16)?, for heroType: HeroType) {
        state(for: heroType).leftHandDamage = damage
    }

    private func setRightHandDamage(_ damage: (minDmg: Int16, maxDmg: Int16)?, for heroType: HeroType) {
        state(for: heroType).rightHandDamage = damage
    }

    // MARK: - Initialization

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.attributeService) var attributeService
        @Dependency(\.armorService) var armorService
        @Dependency(\.damageService) var damageService
        @Dependency(\.weaponValidator) var weaponValidator
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.monsterRepository) var monsterRepository
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
        self.weaponValidator = weaponValidator
        self.snapshotBuilder = snapshotBuilder
        self.monsterRepository = monsterRepository
    }

    // MARK: - Lifecycle

    /// Loads all monsters. Call from the view's `.task { }` so the work is
    /// structured and cancelled when the screen disappears.
    public func load() async {
        await loadAllMonsters()
    }

    // MARK: - Monster Loading

    private func loadAllMonsters() async {
        var monsters: [Monster] = []
        for world in [WorldType.upper, WorldType.middle, WorldType.lower] {
            for level in 1...3 {
                let worldMonsters = monsterRepository.getMonsters(world: world, level: level)
                monsters.append(contentsOf: worldMonsters)
            }
        }
        allMonsters = monsters
    }

    // MARK: - Actions

    public func handlePlayerItemSelection(itemType: HeroItemType) {
        handleItemSelection(for: .player, itemType: itemType)
    }

    public func handleBotItemSelection(itemType: HeroItemType) {
        handleItemSelection(for: .bot, itemType: itemType)
    }

    private func handleItemSelection(for heroType: HeroType, itemType: HeroItemType) {
        let currentItemId = getCurrentItemId(for: heroType, itemType: itemType)

        presentedItemSelector = ItemSelectorState(
            heroType: heroType,
            itemType: itemType,
            currentItemId: currentItemId
        )
    }

    // MARK: - Public API

    public func equipItem(for heroType: HeroType, itemType: HeroItemType, selectedItemId: UUID?) {
        updateSelectedItems(for: heroType, itemType: itemType, selectedItemId: selectedItemId)
    }

    // MARK: - Private Methods

    private func updateSelectedItems(for heroType: HeroType, itemType: HeroItemType, selectedItemId: UUID?) {
        // Mutating `selectedItems` changes the equipment key the view's
        // `.task(id:)` observes, which drives the debounced recompute — no
        // explicit scheduling call needed here.
        if requiresValidation(itemType) {
            let currentState = state(for: heroType)
            validationTask(for: itemType, on: currentState)?.cancel()

            let snapshotItems = currentState.selectedItems
            let newTask: Task<Void, Never> = Task {
                var validatedItems = await self.weaponValidator.validateAndResolve(
                    selecting: selectedItemId.map(ItemID.init(rawValue:)),
                    for: itemType,
                    currentItems: snapshotItems.mapValues { $0.map(ItemID.init(rawValue:)) }
                )

                // A cancelled Task's non-cooperating `await` above still
                // completes, but `Task.isCancelled` reflects the cancellation
                // flag set by the newer selection's cancel-and-replace above —
                // bail before writing a stale result (AC-03).
                guard !Task.isCancelled else { return }

                // The pre-`await` snapshot can go stale for a slot this Task
                // doesn't own: a concurrent, independent selection for the
                // *other* slot may have written to the live state while this
                // validation was in flight, so the decision above (e.g.
                // whether a two-handed weapon must clear an equipped shield)
                // may have been made against an outdated picture of that
                // other slot. When the live state has diverged from the
                // snapshot, re-validate once against the live state so the
                // outcome reflects what's actually equipped now, not a
                // stale guess (AC-02, AC-06).
                var baselineItems = snapshotItems
                let liveItems = currentState.selectedItems
                if liveItems != snapshotItems {
                    validatedItems = await self.weaponValidator.validateAndResolve(
                        selecting: selectedItemId.map(ItemID.init(rawValue:)),
                        for: itemType,
                        currentItems: liveItems.mapValues { $0.map(ItemID.init(rawValue:)) }
                    )
                    guard !Task.isCancelled else { return }
                    baselineItems = liveItems
                }

                // Merge only the keys this call actually changed, onto the
                // baseline it was just validated against — never a full
                // overwrite — so a concurrent selection in the other slot
                // (still in flight) is never reverted (AC-06). Walk the
                // union of both slot sets, not just `validatedItems`' own
                // keys: the validator clears a slot via `dict[slot] = nil`,
                // which removes the key from its returned dictionary rather
                // than storing it as present-with-nil, so a cleared slot
                // must still be treated as changed even though it no longer
                // appears in `validatedItems`.
                for slot in Set(baselineItems.keys).union(validatedItems.keys) {
                    let resolvedRawId = (validatedItems[slot] ?? nil).map(\.rawValue)
                    guard (baselineItems[slot] ?? nil) != resolvedRawId else { continue }
                    currentState.selectedItems[slot] = resolvedRawId
                }

                setValidationTask(nil, for: itemType, on: currentState)
            }
            setValidationTask(newTask, for: itemType, on: currentState)
        } else {
            // Other items don't need validation
            let currentState = state(for: heroType)
            currentState.selectedItems[itemType] = selectedItemId
        }
    }

    private func requiresValidation(_ itemType: HeroItemType) -> Bool {
        return itemType == .weapons || itemType == .shields
    }

    /// `itemType` is guaranteed `.weapons` or `.shields` at every call site
    /// (both are behind `requiresValidation`); `default` is a defensive
    /// no-op so a future third validating slot fails to cancel/store
    /// anything instead of silently sharing the shield handle.
    private func validationTask(for itemType: HeroItemType, on state: HeroConfigurationState) -> Task<Void, Never>? {
        switch itemType {
        case .weapons: return state.weaponValidationTask
        case .shields: return state.shieldValidationTask
        default: return nil
        }
    }

    private func setValidationTask(_ task: Task<Void, Never>?, for itemType: HeroItemType, on state: HeroConfigurationState) {
        switch itemType {
        case .weapons: state.weaponValidationTask = task
        case .shields: state.shieldValidationTask = task
        default: break
        }
    }

    private func getCurrentItemId(for heroType: HeroType, itemType: HeroItemType) -> UUID? {
        return state(for: heroType).selectedItems[itemType] ?? nil
    }

    // MARK: - Debounced Recompute (driven by the view's `.task(id:)`)

    /// Identity of a hero's attribute inputs. When any component changes the
    /// key changes, so `.task(id:)` cancels the in-flight recompute (its
    /// `Task.sleep` throws) and starts a fresh one — this is the "latest wins"
    /// guarantee that the old code re-implemented by hand with snapshot guards.
    public struct AttributesKey: Equatable {
        let level: Int
        let fightStyle: FightStyle?
        let includeRandom: Bool
    }

    public func attributesKey(for heroType: HeroType) -> AttributesKey {
        AttributesKey(
            level: level(for: heroType),
            fightStyle: fightStyle(for: heroType),
            includeRandom: includeRandomAttributes
        )
    }

    /// Recomputes fight-style/level attributes after the debounce window.
    /// Call from the view via `.task(id: attributesKey(for:))`.
    public func applyAttributes(for heroType: HeroType) async {
        // Clearing when no fight style is selected is immediate — no debounce.
        guard let fightStyle = fightStyle(for: heroType) else {
            setFightStyleAttributes(nil, for: heroType)
            setLevelRandomAttributes(nil, for: heroType)
            return
        }

        // Debounce. A newer edit changes the task id, so SwiftUI cancels this
        // task and the sleep throws — we bail before mutating state. No manual
        // isCancelled checks or snapshot re-validation required.
        do { try await Task.sleep(for: debounceDelay) } catch { return }

        let currentLevel = level(for: heroType)
        let fsAttrs = attributeService.getAllFightStyleAttributes(
            for: fightStyle,
            at: Int16(currentLevel)
        )
        let lrAttrs: HeroAttributes = includeRandomAttributes
            ? attributeService.getAllRandomLevelAttributes(for: Int16(currentLevel))
            : HeroAttributes()

        setFightStyleAttributes(fsAttrs, for: heroType)
        setLevelRandomAttributes(lrAttrs, for: heroType)
    }

    /// Recomputes items attributes, armor, two-handed flag and per-hand damage
    /// after the debounce window. Call from the view via
    /// `.task(id: <hero>State.selectedItems)`.
    public func applyEquipment(for heroType: HeroType) async {
        do { try await Task.sleep(for: debounceDelay) } catch { return }

        let currentItems = selectedItems(for: heroType)
        let itemIds = currentItems.values.compactMap { $0 }.map(ItemID.init(rawValue:))
        let primaryWeaponId = currentItems[.weapons] ?? nil
        let secondaryWeaponId = currentItems[.shields] ?? nil

        let attrs = attributeService.getAllItemsAttributes(for: itemIds)
        let armor = armorService.getAllItemsArmor(for: itemIds)

        var twoHandedWeaponId: UUID?
        let isTwoHanded: Bool
        if let weaponId = primaryWeaponId,
           let item = itemsRepository.getHeroItem(ItemID(rawValue: weaponId)),
           let weapon = item as? WeaponItem,
           weapon.handUse == .both {
            isTwoHanded = true
            twoHandedWeaponId = weapon.id.rawValue
        } else {
            isTwoHanded = false
        }

        let rightHandDamage: (minDmg: Int16, maxDmg: Int16)?
        let leftHandDamage: (minDmg: Int16, maxDmg: Int16)?
        if isTwoHanded {
            rightHandDamage = damageService.getWeaponDamage(weaponId: primaryWeaponId.map(ItemID.init(rawValue:)))
            leftHandDamage = (minDmg: 0, maxDmg: 0)
        } else {
            rightHandDamage = damageService.getWeaponDamage(weaponId: primaryWeaponId.map(ItemID.init(rawValue:)))
            leftHandDamage = damageService.getWeaponDamage(weaponId: secondaryWeaponId.map(ItemID.init(rawValue:)))
        }

        setItemsAttributes(attrs, for: heroType)
        setArmorValues(armor, for: heroType)
        setTwoHandedWeaponId(twoHandedWeaponId, for: heroType)
        setRightHandDamage(rightHandDamage, for: heroType)
        setLeftHandDamage(leftHandDamage, for: heroType)
    }

    // MARK: - Battle Creation

    /// Create a Battle instance from current player and bot configurations
    /// - Returns: Battle instance or nil if validation fails
    public func startBattle() async -> Battle? {
        // Validate player configuration
        guard let playerFightStyleAttrs = playerState.fightStyleAttributes,
              let playerLevelAttrs = playerState.levelRandomAttributes else {
            return nil
        }

        // Build CombatantSnapshot for player. The adapter falls back to
        // Recruit's Spear if no weapon is selected, so the dev screen can
        // always start a battle.
        let playerEquipped = playerState.makeEquipped(itemsRepository: itemsRepository)
        let playerSnapshot = snapshotBuilder.buildSnapshot(
            name: "Player",
            imageName: "Yuuki Asuna",
            level: playerState.level,
            fightStyleAttributes: playerFightStyleAttrs,
            randomLevelAttributes: playerLevelAttrs,
            equipped: playerEquipped,
            globalBuffs: []
        )

        // Handle opponent based on selection
        switch selectedOpponent {
        case .elf:
            // Validate bot configuration for elf opponent
            guard let botFightStyleAttrs = botState.fightStyleAttributes,
                  let botLevelAttrs = botState.levelRandomAttributes else {
                return nil
            }

            // Build CombatantSnapshot for bot
            let botEquipped = botState.makeEquipped(itemsRepository: itemsRepository)
            let botSnapshot = snapshotBuilder.buildSnapshot(
                name: "Bot",
                imageName: "",
                level: botState.level,
                fightStyleAttributes: botFightStyleAttrs,
                randomLevelAttributes: botLevelAttrs,
                equipped: botEquipped,
                globalBuffs: []
            )

            // Create Battle with elf opponent
            return Battle(
                leftTeam: [playerSnapshot],
                rightTeam: [botSnapshot],
                equippedByCombatantId: [
                    playerSnapshot.id: playerEquipped,
                    botSnapshot.id: botEquipped
                ]
            )

        case .monster(let monster):
            // Build CombatantSnapshot from monster
            let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster, globalBuffs: [])

            // Create Battle with monster opponent
            return Battle(
                leftTeam: [playerSnapshot],
                rightTeam: [monsterSnapshot],
                equippedByCombatantId: [playerSnapshot.id: playerEquipped]
            )
        }
    }
}
