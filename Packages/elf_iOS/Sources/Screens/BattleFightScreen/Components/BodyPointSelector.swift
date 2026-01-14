//
//  BodyPointSelector.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

// MARK: - BodyPointSelector

struct BodyPointSelector: View {

    // MARK: - Properties

    let mode: Mode
    let selectedPoints: Set<BodyPart>
    let maxPoints: Int
    let onToggle: (BodyPart) -> Void

    // MARK: - Mode

    enum Mode {
        case attack
        case defense

        var label: String {
            switch self {
            case .attack:
                return "Attack"
            case .defense:
                return "Defense"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        let checkboxSize = ElfSizing.BattleFight.checkboxSize
        let spacing: CGFloat = 10
        let selectorWidth = checkboxSize * 3 + spacing * 2
        let selectorHeight = checkboxSize * 3 + spacing * 2

        VStack(spacing: 20) {
            // Label
            Text(mode.label)
                .font(ElfFonts.Component.statLabel)
                .foregroundColor(.black)

            // Checkboxes with calculated frame
            ZStack {
                let centerX = selectorWidth / 2
                let centerY = selectorHeight / 2

                // Center - Body
                checkbox(for: .body)
                    .position(x: centerX, y: centerY)

                // Top - Head
                checkbox(for: .head)
                    .position(x: centerX, y: centerY - checkboxSize - spacing)

                // Bottom - Legs
                checkbox(for: .legs)
                    .position(x: centerX, y: centerY + checkboxSize + spacing)

                // Left - Left Hand
                checkbox(for: .leftHand)
                    .position(x: centerX - checkboxSize - spacing, y: centerY)

                // Right - Right Hand
                checkbox(for: .rightHand)
                    .position(x: centerX + checkboxSize + spacing, y: centerY)
            }
            .frame(width: selectorWidth, height: selectorHeight)
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func checkbox(for bodyPart: BodyPart) -> some View {
        let isSelected = selectedPoints.contains(bodyPart)
        let isDisabled = !isSelected && selectedPoints.count >= maxPoints

        Button(action: {
            if !isDisabled {
                onToggle(bodyPart)
            }
        }) {
            Circle()
                .fill(backgroundColor(isSelected: isSelected, isDisabled: isDisabled))
                .frame(
                    width: ElfSizing.BattleFight.checkboxSize,
                    height: ElfSizing.BattleFight.checkboxSize
                )
                .overlay(
                    Circle()
                        .stroke(
                            borderColor(isSelected: isSelected, isDisabled: isDisabled),
                            lineWidth: 2
                        )
                )
                .overlay(
                    Group {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )
        }
        .disabled(isDisabled)
    }

    private func backgroundColor(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled {
            return ElfColors.Interactive.disabled
        } else if isSelected {
            return ElfColors.Interactive.selected
        } else {
            return ElfColors.Interactive.normal
        }
    }

    private func borderColor(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled {
            return ElfColors.Interactive.disabled
        } else if isSelected {
            return ElfColors.Interactive.selected
        } else {
            return Color.white.opacity(0.5)
        }
    }
}

// MARK: - Preview

#Preview {
    BodyPointSelector(
        mode: .attack,
        selectedPoints: [.head, .body],
        maxPoints: 2,
        onToggle: { _ in }
    )
    .padding()
    .background { Color.yellow }
}
