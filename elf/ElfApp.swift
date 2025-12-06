//
//  ElfApp.swift
//  elf
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_iOS
import SwiftUI

@main
internal struct ElfApp: App {
    @State private var container = ElfAppDependencyContainer()

    init() {
        configureAppearance()
    }

    internal var body: some Scene {
        WindowGroup {
            RootScreen()
                .environment(container)
                .onScenePhaseChange(container: container)
        }
    }

    // MARK: - Appearance Configuration

    private func configureAppearance() {
        // Segmented control styling
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.orange
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.black],
            for: .normal
        )
    }
}

// MARK: - Scene Phase Handler

/// View modifier that handles scene phase changes without causing App body re-evaluation
private struct ScenePhaseChangeModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let container: ElfAppDependencyContainer

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    Task { @MainActor in
                        await container.saveActiveGameIfNeeded()
                    }
                }
            }
    }
}

extension View {
    func onScenePhaseChange(container: ElfAppDependencyContainer) -> some View {
        modifier(ScenePhaseChangeModifier(container: container))
    }
}
