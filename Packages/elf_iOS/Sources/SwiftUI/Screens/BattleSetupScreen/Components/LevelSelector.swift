//
//  LevelSelector.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI

struct LevelSelector: View {
    @Binding var level: Int16
    let minLevel: Int16 = 1
    let maxLevel: Int16 = 12

    var body: some View {
        VStack(spacing: BattleSetupConstants.Spacing.labelToControlSpacing) {
            Text("Level")
                .font(BattleSetupConstants.Fonts.labelFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            HStack {
                Button(action: decrementLevel) {
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .buttonStyle(LevelButtonStyle())
                .disabled(level <= minLevel)

                Text("\(level)")
                    .font(BattleSetupConstants.Fonts.levelFont)
                    .foregroundColor(.white)
                    .frame(width: 40)
                    .multilineTextAlignment(.center)

                Button(action: incrementLevel) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .buttonStyle(LevelButtonStyle())
                .disabled(level >= maxLevel)
            }
        }
    }

    private func incrementLevel() {
        if level < maxLevel {
            level += 1
        }
    }

    private func decrementLevel() {
        if level > minLevel {
            level -= 1
        }
    }
}

// MARK: - Preview

struct LevelSelector_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LevelSelector(level: .constant(1))
                .padding()
                .background(Color.black)
                .previewDisplayName("Min Level")

            LevelSelector(level: .constant(5))
                .padding()
                .background(Color.black)
                .previewDisplayName("Mid Level")

            LevelSelector(level: .constant(12))
                .padding()
                .background(Color.black)
                .previewDisplayName("Max Level")
        }
        .previewLayout(.sizeThatFits)
    }
}
