//
//  ElfApp.swift
//  elf
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

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
                    await appContainer.createGameContainer()
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
