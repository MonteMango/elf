//
//  CloseButton.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(
                    width: GameDayConstants.Sizing.closeButtonSize,
                    height: GameDayConstants.Sizing.closeButtonSize
                )
                .background { GameDayConstants.Colors.closeButtonBackground }
        }
    }
}

#Preview {
    CloseButton { }
        .preferredColorScheme(.dark)
}
