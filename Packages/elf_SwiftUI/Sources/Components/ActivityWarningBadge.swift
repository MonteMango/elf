//
//  ActivityWarningBadge.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Warning badge with exclamation icon and italic text
public struct ActivityWarningBadge: View {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: ElfSpacing.small) {
            // Warning icon
            Circle()
                .fill(ElfColors.primary)
                .frame(width: 24, height: 24)
                .overlay {
                    Text("!")
                        .font(ElfFonts.Component.warningIcon)
                        .foregroundStyle(.white)
                }

            // Warning text
            Text(text)
                .font(ElfFonts.Component.warningText)
                .italic()
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, ElfSpacing.medium)
        .padding(.vertical, ElfSpacing.small)
        .fixedSize(horizontal: false, vertical: false)
        .frame(maxWidth: 300)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 20) {
        ActivityWarningBadge(text: "Monsters could attack you during fishing.")

        ActivityWarningBadge(text: "Short warning")
    }
    .padding()
    .background(Color.white)
}
