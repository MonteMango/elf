//
//  GameSession.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Public facade for an active game session. Owns the observable `state`
/// (`GameStore`), the dungeon child session, the day-state shortcut, and
/// every game-level mutation + persistence operation.
///
/// Views and ViewModels go through `GameSession` exclusively — `GameService`
/// is private implementation. State reads via `session.state.X`; mutations
/// via `session.X(...)`; persistence via `session.save()`.
///
/// Lifecycle: created when a game starts, released when it ends (see
/// `AppCoordinator.startGame` / `endGame`).
@MainActor
@Observable
public final class GameSession {

    // MARK: - State

    public let state: GameStore

    // MARK: - Child sessions

    public var dungeonSession: DungeonSession?

    // MARK: - Day-state shortcut

    /// Convenience VM exposing day/AP/calendar bits and the advance/spend ops.
    /// IUO is intentional — it captures `self` at the end of `init`, after all
    /// stored properties are set, so the weak ref inside the dayState VM
    /// resolves correctly. Never observed as nil from outside.
    public private(set) var dayState: GameDayStateViewModel!

    // MARK: - Private dependencies

    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.gameRepository) private var gameRepository

    @ObservationIgnored
    @Dependency(\.debugGameLogger) private var debugGameLogger

    private let slotId: String

    // MARK: - Initialization

    public init(
        game: Game,
        playTime: TimeInterval = 0,
        slotId: String = SaveSlotInfo.defaultSlotId
    ) {
        let store = GameStore(from: game, playTime: playTime)
        self.state = store
        self.gameService = DefaultGameService(store: store)
        self.slotId = slotId
        // Build dayState last — captures `self` weakly.
        self.dayState = GameDayStateViewModel(session: self)
    }

    // MARK: - Day Management

    public func advanceToNextDay() {
        gameService.advanceToNextDay()
    }

    public func spendActionPoints(_ amount: Int) {
        gameService.spendActionPoints(amount)
    }

    // MARK: - Player Progression

    public func addPlayerExperience(_ amount: Int) {
        gameService.addPlayerExperience(amount)
    }

    public func addFishingExperience(_ amount: Int) {
        gameService.addFishingExperience(amount)
    }

    public func addForagingExperience(_ amount: Int) {
        gameService.addForagingExperience(amount)
    }

    public func addMiningExperience(_ amount: Int) {
        gameService.addMiningExperience(amount)
    }

    public func addDropsToPlayerInventory(rewards: HuntRewards) {
        gameService.addDropsToPlayerInventory(rewards: rewards)
    }

    public func addFishToInventory(_ fish: [Fish]) {
        gameService.addFishToInventory(fish)
    }

    public func addHerbsToInventory(_ herbs: [Herb]) {
        gameService.addHerbsToInventory(herbs)
    }

    public func addOresToInventory(_ ores: [Ore]) {
        gameService.addOresToInventory(ores)
    }

    public func addItemsToPlayerInventory(_ items: [Item]) {
        gameService.addItemsToPlayerInventory(items)
    }

    // MARK: - Crafting

    @discardableResult
    public func craftItem(recipe: Recipe, item: Item) -> Bool {
        gameService.craftItem(recipe: recipe, item: item)
    }

    // MARK: - Persistence

    /// Saves the active game state. Snapshots the store on the main thread,
    /// then offloads disk I/O to the repository (background actor).
    // TODO: [persistence/P0] Coalesce/debounce rapid save() calls.
    public func save() async throws {
        let snap = state.snapshot()
        let time = state.playTime
        debugGameLogger.logGameSave(game: snap, playTime: time)
        try await gameRepository.save(snap, slotId: slotId, playTime: time)
    }

    // MARK: - Dungeon Session Lifecycle

    @discardableResult
    public func startDungeonSession(dungeonId: UUID, allyIds: [UUID]) -> DungeonSession {
        let session = DungeonSession(
            gameStore: state,
            dungeonId: dungeonId,
            allyIds: allyIds
        )
        dungeonSession = session
        return session
    }

    public func endDungeonSession() {
        dungeonSession = nil
    }

    // MARK: - ViewModel Factories

    public func makeFarmViewModel() -> FarmViewModel {
        FarmViewModel(session: self)
    }

    public func makeFarmActivityViewModel(activity: FarmActivity) -> FarmActivityViewModel {
        FarmActivityViewModel(activity: activity, session: self)
    }

    public func makeHuntViewModel() -> HuntViewModel {
        HuntViewModel(session: self)
    }

    public func makeCraftViewModel() -> CraftViewModel {
        CraftViewModel(session: self)
    }

    public func makeQuestViewModel(questId: QuestID) -> QuestViewModel {
        QuestViewModel(questId: questId, session: self)
    }

    public func makeQuestListViewModel() -> QuestListViewModel {
        QuestListViewModel(session: self)
    }

    public func makeGameDayViewModel() -> GameDayViewModel {
        GameDayViewModel(session: self)
    }

    public func makeCalendarViewModel(calendar: [GameDay], currentDayNumber: Int) -> CalendarViewModel {
        CalendarViewModel(calendar: calendar, currentDayNumber: currentDayNumber)
    }

    public func makeInventoryViewModel() -> InventoryViewModel {
        InventoryViewModel(session: self)
    }
}
