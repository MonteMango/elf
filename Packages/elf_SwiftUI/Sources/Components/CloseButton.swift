//
//  CloseButton.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

public struct CloseButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(
                    width: ElfSizing.closeButtonSize,
                    height: ElfSizing.closeButtonSize
                )
                .background(ElfColors.elfRed)
                .clipShape(Circle())
        }
    }
}

#Preview {
    CloseButton { }
        .preferredColorScheme(.dark)
}
