//
//  AppearanceSelectionView.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import SwiftUI

/// Stage 1: Select character appearance
struct AppearanceSelectionView: View {
    @Binding var selectedAppearance: CharacterAppearance?
    let safeAreaInsets: EdgeInsets

    var body: some View {
        StageContainer(safeAreaInsets: safeAreaInsets) { size, safeArea in
            let cardHeight = size.height - 40 // padding
            let cardWidth = cardHeight * 0.6

            ZStack {
                // Items Grid - full size
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(CharacterAppearance.allCases, id: \.self) { appearance in
                            appearanceCard(for: appearance, width: cardWidth, height: cardHeight)
                        }
                    }
                    .padding(.leading, StagePadding.leading(safeArea))
                    .padding(.trailing, StagePadding.trailing(safeArea))
                    .padding(.vertical, StagePadding.standard)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .topLeading) {
                // Title
                Text("Select your appearance")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.top, StagePadding.top())
                    .padding(.leading, StagePadding.leading(safeArea))
            }
        }
    }

    @ViewBuilder
    private func appearanceCard(for appearance: CharacterAppearance, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedAppearance == appearance

        Button {
            selectedAppearance = appearance
        } label: {
            Image(appearance.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.5) : Color.black.opacity(0.2), radius: isSelected ? 8 : 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppearanceSelectionView(
        selectedAppearance: .constant(nil),
        safeAreaInsets: EdgeInsets()
    )
}
