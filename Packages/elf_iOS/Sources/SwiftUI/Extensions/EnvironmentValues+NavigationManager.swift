//
//  EnvironmentValues+NavigationManager.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

private struct NavigationManagerKey: EnvironmentKey {
    static let defaultValue: any NavigationManaging = AppNavigationManager()
}

public extension EnvironmentValues {
    var navigationManager: any NavigationManaging {
        get { self[NavigationManagerKey.self] }
        set { self[NavigationManagerKey.self] = newValue }
    }
}
