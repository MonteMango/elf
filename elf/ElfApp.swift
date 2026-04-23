//
//  ElfApp.swift
//  elf
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import Dependencies
import elf_iOS
import elf_SwiftUI
import SwiftUI

@main
internal struct ElfApp: App {
    @State private var appContainer = ElfAppContainer()

    init() {
        configureAppearance()
    }

    internal var body: some Scene {
        WindowGroup {
            RootScreen()
                .environment(appContainer)
                .onScenePhaseChange(appContainer: appContainer)
                .task {
                    let gameContainer = await appContainer.createGameContainer()
                    prepareDependencies {
                        $0.farmActivityService = gameContainer.farmActivityService
                        $0.monsterRepository = gameContainer.gameDataRepository.monsters
                        $0.snapshotBuilder = gameContainer.snapshotBuilder
                        $0.itemsRepository = gameContainer.gameDataRepository.items
                        $0.materialRepository = gameContainer.gameDataRepository.materials
                        $0.recipeRepository = gameContainer.gameDataRepository.recipes
                        $0.oreRepository = gameContainer.gameDataRepository.ores
                        $0.questRepository = gameContainer.gameDataRepository.quests
                        $0.herbRepository = gameContainer.gameDataRepository.herbs
                        $0.fishRepository = gameContainer.gameDataRepository.fish
                        $0.attributeService = gameContainer.attributeService
                        $0.armorService = gameContainer.armorService
                        $0.damageService = gameContainer.damageService
                        $0.weaponValidator = gameContainer.weaponValidator
                        $0.snapshotCombatCalculator = gameContainer.snapshotCombatCalculator
                        $0.combatRoundExecutor = gameContainer.combatRoundExecutor
                        $0.battleSimulationService = gameContainer.battleSimulationService
                        $0.battleResultCalculator = gameContainer.battleResultCalculator
                    }
                }
        }
    }

    // MARK: - Appearance Configuration

    private func configureAppearance() {
        // Segmented control styling
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(ElfColors.primary)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(ElfColors.Text.primaryLight)],
            for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(ElfColors.Text.primary)],
            for: .normal
        )
    }
}

// MARK: - Scene Phase Handler

/// View modifier that handles scene phase changes without causing App body re-evaluation
private struct ScenePhaseChangeModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let appContainer: ElfAppContainer

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, newPhase in
                // TODO: [persistence/P0] Wrap save in UIApplication.beginBackgroundTask(expirationHandler:)
                // Reason: iOS gives only ~5s after .background before suspending the process.
                // A full JSON save for a large Game (8×10 elves + inventories) may not finish in time,
                // leading to silently lost progress. beginBackgroundTask grants up to ~30s and lets us
                // endBackgroundTask(_:) after the actor-isolated save completes.
                // See: https://developer.apple.com/documentation/uikit/uiapplication/beginbackgroundtask(expirationhandler:)
                if newPhase == .background || newPhase == .inactive {
                    Task { @MainActor in
                        await appContainer.gameContainer?.saveActiveGameIfNeeded()
                    }
                }
            }
    }
}

extension View {
    func onScenePhaseChange(appContainer: ElfAppContainer) -> some View {
        modifier(ScenePhaseChangeModifier(appContainer: appContainer))
    }
}
