//
//  RequirementRow.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// A row displaying "Need [icon] ×N more" pattern.
/// Used in CraftScreen (missing ingredients) and QuestScreen (conditions).
public struct RequirementRow: View {
    let imageName: String
    let amount: Int

    public init(imageName: String, amount: Int) {
        self.imageName = imageName
        self.amount = amount
    }

    public var body: some View {
        HStack(spacing: ElfSpacing.xxxs) {
            Text("Need")

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: ElfSizing.Icon.tiny, height: ElfSizing.Icon.tiny)

            Text("×\(amount) more")
        }
        .font(ElfFonts.Component.dropItemName)
        .foregroundStyle(ElfColors.Text.error)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .trailing, spacing: 4) {
        RequirementRow(imageName: "material_monster_soul_gem", amount: 13)
        RequirementRow(imageName: "material_monster_soul_gem", amount: 2)
        RequirementRow(imageName: "material_monster_soul_gem", amount: 1)
    }
    .padding()
}
