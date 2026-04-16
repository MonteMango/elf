//
//  BackButton.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import SwiftUI

public struct BackButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        Button(action: action) {
            Image(systemName: "arrow.backward")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(ElfColors.Button.primaryText)
                .frame(width: ElfSizing.minTouchTarget, height: ElfSizing.minTouchTarget)
                .background(ElfColors.Button.primary)
        }
    }
}

#Preview {
    BackButton {
        print("Back tapped")
    }
}
