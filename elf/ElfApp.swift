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
    @State private var coordinator = AppCoordinator()
    @State private var isBootstrapped = false

    init() {
        loadRocketSimConnect()
        configureAppearance()
    }

    internal var body: some Scene {
        WindowGroup {
            if isBootstrapped {
                RootScreen()
                    .environment(coordinator)
                    .onScenePhaseChange(coordinator: coordinator)
            } else {
                ProgressView()
                    .task {
                        await DependencyBootstrap.run()
                        isBootstrapped = true
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
    
    // MARK: RocketSim

    private func loadRocketSimConnect() {
        #if DEBUG
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
        #endif
    }
}

// MARK: - Scene Phase Handler

/// View modifier that handles scene phase changes without causing App body re-evaluation.
/// Takes `AppCoordinator` as a parameter rather than reading from environment — the modifier
/// lives on the outside of the `.environment(coordinator)` wrapper, so @Environment wouldn't
/// resolve inside it.
private struct ScenePhaseChangeModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let coordinator: AppCoordinator

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
                        await coordinator.saveIfNeeded()
                    }
                }
            }
    }
}

extension View {
    func onScenePhaseChange(coordinator: AppCoordinator) -> some View {
        modifier(ScenePhaseChangeModifier(coordinator: coordinator))
    }
}
