//
//  DungeonScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Parent dungeon-briefing screen. Owns the picker, the full-bleed dungeon
/// background, and the persistent Entrance button. Reads its state from the
/// active `DungeonSession` on `GameSession` (created by `GameDayScreen`
/// before pushing this route). The middle area swaps between three tab views
/// (Overview / Squad / Map); each tab makes its own ViewModel from the same
/// session so this shell stays purely structural.
struct DungeonScreen: View {

    @Environment(AppRouter.self) private var router

    private let gameSession: GameSession
    private let dungeonSession: DungeonSession
    @State private var viewModel: DungeonViewModel

    /// Both sessions are passed in non-optional — the existence guard lives in
    /// `DungeonRouteView`, which only builds this screen while a run is active.
    /// Keeping `init` trap-free matters because SwiftUI re-creates the view
    /// struct during teardown (e.g. while popping after "Finish"), when the
    /// dungeon session may already have been released.
    init(gameSession: GameSession, dungeonSession: DungeonSession) {
        self.gameSession = gameSession
        self.dungeonSession = dungeonSession
        self._viewModel = State(initialValue: DungeonViewModel(session: dungeonSession, gameSession: gameSession))
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 0) {
            segmentedControl
                .padding(.top, ElfSpacing.screenTop)
            tabBody
        }
        .overlay(alignment: .bottomTrailing) {
            if dungeonSession.isInRun {
                RoomActionButton(
                    title: viewModel.actionTitle ?? "",
                    action: { performRoomAction() }
                )
            } else {
                EntranceButton(
                    isEnabled: dungeonSession.canEnter,
                    action: { Task { await viewModel.enterDungeon() } }
                )
            }
        }
        .background {
            dungeonBackground
        }
        .overlay {
            DebugSafeAreaOverlay()
        }
        .overlay {
            if let transition = viewModel.transition {
                DungeonTransitionView(transition: transition)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.transition)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Room action

    /// Dispatches the bottom action button by the room's current state:
    /// launch the battle, walk to the next room, or finish the run.
    private func performRoomAction() {
        switch viewModel.actionKind {
        case .fight:
            if let battle = viewModel.startRoomBattle() {
                router.navigationPath.append(AppRoute.battleFight(battle))
            }
        case .next:
            Task { await viewModel.advanceToNextRoom() }
        case .finish:
            // Pop first, then finish the run: removing the route before nil-ing
            // the session avoids rebuilding this screen against a missing session.
            // finishDungeonRun flushes the run's banked XP/drops into the player.
            router.popToGameDay()
            gameSession.finishDungeonRun()
            // Persist the now-flushed game state (dungeonSession is nil → no run).
            gameSession.saveInBackground()
        case .drink:
            Task { await viewModel.resolveRoomEvent() }
        case .none:
            break
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var dungeonBackground: some View {
        if let uiImage = UIImage(named: dungeonSession.backgroundImageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        } else {
            ElfColors.Background.dark
                .ignoresSafeArea()
        }
    }

    // MARK: - Segmented control

    private var segmentedControl: some View {
        @Bindable var viewModel = viewModel
        return Picker("Tab", selection: $viewModel.activeTab) {
            ForEach(DungeonTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 280)
    }

    // MARK: - Tab body

    @ViewBuilder
    private var tabBody: some View {
        Group {
            switch viewModel.activeTab {
            case .overview:
                DungeonOverviewContent(session: dungeonSession)
                    .id(dungeonSession.dungeonId)
            case .squad:
                DungeonSquadContent(session: dungeonSession)
                    .id(dungeonSession.dungeonId)
            case .map:
                DungeonMapContent(session: dungeonSession)
                    .id(dungeonSession.dungeonId)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    let dungeonId = DungeonID(rawValue: UUID(uuidString: "11111111-0000-0000-0000-000000000001") ?? UUID())

    if let coordinator, let session = coordinator.gameSession {
        let house = session.state.houses[session.state.playerHouseIndex]
        let allyIds = house.members
            .enumerated()
            .filter { $0.offset != session.state.playerMemberIndex }
            .map(\.element.id)
            .shuffled()
            .prefix(4)
        let dungeonSession = session.startDungeonSession(dungeonId: dungeonId, allyIds: Array(allyIds))

        NavigationStack(path: $router.navigationPath) {
            DungeonScreen(gameSession: session, dungeonSession: dungeonSession)
                .environment(router)
                .environment(coordinator)
        }
    } else {
        ProgressView()
            .task {
                await DependencyBootstrap.run()
                let c = AppCoordinator()
                c.initializePreviewSession(game: PreviewGame.createMockGame())
                coordinator = c
            }
    }
}
#endif
