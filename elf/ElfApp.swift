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
    @Environment(\.scenePhase) private var scenePhase

    internal var body: some Scene {
        WindowGroup {
            RootScreen()
                .environment(container)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                Task { @MainActor in
                    await container.saveActiveGameIfNeeded()
                }
            }
        }
    }
}
