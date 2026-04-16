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
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: ElfFonts.Size.title3, weight: .bold))
                .foregroundStyle(ElfColors.Button.closeText)
                .frame(
                    width: ElfSizing.Button.closeSize,
                    height: ElfSizing.Button.closeSize
                )
                .background(ElfColors.Button.close)
                .clipShape(Circle())
        }
    }
}

#Preview {
    CloseButton { }
        .preferredColorScheme(.dark)
}
