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
    @Namespace private var farmZoomNamespace
    @Namespace private var questZoomNamespace

    public init() {}

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
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
        .allowsHitTesting(router.presentedModal == nil)
        .overlay {
            // Modal layer - displayed on top of navigation stack
            if let modal = router.presentedModal {
                modal.view()
            }
        }
        .environment(\.farmZoomNamespace, farmZoomNamespace)
        .environment(\.questZoomNamespace, questZoomNamespace)
        .environment(router)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
