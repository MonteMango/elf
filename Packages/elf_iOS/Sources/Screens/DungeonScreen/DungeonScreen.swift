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
    private let dungeonSession: DungeonSession
    @State private var viewModel: DungeonViewModel

    init(session: GameSession) {
        // Force-unwrap is safe: the route is only reachable from
        // `GameDayScreen.dungeon` which calls `session.startDungeonSession(...)`
        // before pushing the route.
        guard let dungeonSession = session.dungeonSession else {
            fatalError("DungeonScreen reached without an active DungeonSession on GameSession.")
        }
        self.dungeonSession = dungeonSession
        self._viewModel = State(initialValue: DungeonViewModel(session: dungeonSession))
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
            EntranceButton(
                isEnabled: dungeonSession.canEnter,
                action: { router.pop() }
            )
        }
        .background {
            dungeonBackground
        }
        .overlay {
            DebugSafeAreaOverlay()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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

    let dungeonId = UUID(uuidString: "11111111-0000-0000-0000-000000000001") ?? UUID()

    if let coordinator, let session = coordinator.gameSession {
        let house = session.state.houses[session.state.playerHouseIndex]
        let allyIds = house.members
            .enumerated()
            .filter { $0.offset != session.state.playerMemberIndex }
            .map(\.element.id)
            .shuffled()
            .prefix(4)
        let _ = session.startDungeonSession(dungeonId: dungeonId, allyIds: Array(allyIds))

        NavigationStack(path: $router.navigationPath) {
            DungeonScreen(session: session)
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
