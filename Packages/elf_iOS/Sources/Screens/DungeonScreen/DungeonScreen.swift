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
/// background, and the persistent Entrance button. The middle area swaps
/// between three tab views (Overview / Squad / Map); each tab has its own
/// VM and resolves its own data so this shell stays purely structural.
struct DungeonScreen: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: DungeonViewModel
    private let session: GameSessionModel
    private let dungeonId: UUID
    private let allyIds: [UUID]

    init(dungeonId: UUID, allyIds: [UUID], session: GameSessionModel) {
        self.session = session
        self.dungeonId = dungeonId
        self.allyIds = allyIds
        self._viewModel = State(initialValue: session.makeDungeonViewModel(
            dungeonId: dungeonId,
            allyIds: allyIds
        ))
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
                isEnabled: viewModel.canEnter,
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
        if let uiImage = UIImage(named: viewModel.backgroundImageName) {
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
        Picker("Tab", selection: $viewModel.activeTab) {
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
                DungeonOverviewContent(session: session, dungeonId: dungeonId, allyIds: allyIds)
                    .id(dungeonId)
            case .squad:
                DungeonSquadContent(session: session, dungeonId: dungeonId, allyIds: allyIds)
                    .id(dungeonId)
            case .map:
                DungeonMapContent(session: session, dungeonId: dungeonId)
                    .id(dungeonId)
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

    if let coordinator, let session = coordinator.sessionModel {
        let house = session.gameService.houses[session.gameService.playerHouseIndex]
        let allyIds = house.members
            .enumerated()
            .filter { $0.offset != session.gameService.playerMemberIndex }
            .map(\.element.id)
            .shuffled()
            .prefix(4)

        NavigationStack(path: $router.navigationPath) {
            DungeonScreen(
                dungeonId: dungeonId,
                allyIds: Array(allyIds),
                session: session
            )
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
