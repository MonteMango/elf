//
//  BodyPointSelector.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import SwiftUI
import elf_Kit

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
        VStack(spacing: 5) {
            // Label
            Text(mode.label)
                .font(BattleFightConstants.Fonts.sectionLabel)
                .foregroundColor(.white)

            // Checkboxes
            GeometryReader { geometry in
                let checkboxSize = BattleFightConstants.Sizing.checkboxSize
                let spacing = BattleFightConstants.Sizing.checkboxSpacing
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2

                ZStack {
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
            }
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
                    width: BattleFightConstants.Sizing.checkboxSize,
                    height: BattleFightConstants.Sizing.checkboxSize
                )
                .overlay(
                    Circle()
                        .stroke(
                            borderColor(isSelected: isSelected, isDisabled: isDisabled),
                            lineWidth: BattleFightConstants.Sizing.checkboxBorderWidth
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
            return BattleFightConstants.Colors.checkboxDisabled
        } else if isSelected {
            return BattleFightConstants.Colors.checkboxSelected
        } else {
            return BattleFightConstants.Colors.checkboxNormal
        }
    }

    private func borderColor(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled {
            return BattleFightConstants.Colors.checkboxDisabled
        } else if isSelected {
            return BattleFightConstants.Colors.checkboxSelected
        } else {
            return Color.white.opacity(0.5)
        }
    }
}

// MARK: - Preview

struct BodyPointSelector_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 30) {
            // Attack mode
            BodyPointSelector(
                mode: .attack,
                selectedPoints: [.head, .body],
                maxPoints: 2,
                onToggle: { _ in }
            )
            .frame(width: 200, height: 200)

            // Defense mode
            BodyPointSelector(
                mode: .defense,
                selectedPoints: [.leftHand, .rightHand, .legs],
                maxPoints: 3,
                onToggle: { _ in }
            )
            .frame(width: 200, height: 200)
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Body Point Selector")
    }
}
