//
//  RootScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

public struct RootScreen: View {
    
    @State private var navigationManager = AppNavigationManager.shared
    
    public init() { }
    
    public var body: some View {
        MainMenuScreen()
            .withNavigation()
            .environment(\.navigationManager, navigationManager)
    }
}

#Preview {
    RootScreen()
}
