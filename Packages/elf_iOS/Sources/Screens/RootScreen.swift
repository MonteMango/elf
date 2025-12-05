//
//  RootScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

public struct RootScreen: View {

    @State private var router = AppRouter()

    public init() {}

    public var body: some View {
        NavigationStack(path: $router.navigationPath) {
            MainMenuScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    route.view()
                        .navigationBarBackButtonHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("")
                }
        }
        .environment(router)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    RootScreen()
        .environment(ElfAppDependencyContainer())
}
