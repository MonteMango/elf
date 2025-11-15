//
//  View+DisableSwipeBack.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import SwiftUI

extension View {
    func disableSwipeBack() -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in }
        )
    }
}
