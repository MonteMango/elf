//
//  SelectHeroItemScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import SwiftUI
import elf_Kit
import Combine

internal struct SelectHeroItemScreenContent: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SelectHeroItemViewModel

    private let heroItemType: HeroItemType

    internal init(viewModel: SelectHeroItemViewModel, heroItemType: HeroItemType) {
        self._viewModel = State(initialValue: viewModel)
        self.heroItemType = heroItemType
    }

    internal var body: some View {
        ZStack {
            // Items Grid - full size
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Empty cell (unequip option)
                    EmptyItemCell(isSelected: viewModel.selectedItemId == nil)
                        .onTapGesture {
                            viewModel.selectItem(nil)
                        }

                    // Available items
                    ForEach(viewModel.availableItems, id: \.id) { item in
                        ItemCell(
                            item: item,
                            isSelected: viewModel.selectedItemId == item.id
                        )
                        .onTapGesture {
                            viewModel.selectItem(item.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            // Title
            Text(itemTypeTitle)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .padding(.top, 20)
        }
        .overlay(alignment: .topTrailing) {
            // Close button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding(20)
        }
        .overlay(alignment: .bottomTrailing) {
            // Equip button
            Button(action: {
                // TODO: Implement item selection callback to BattleSetupViewModel
                dismiss()
            }) {
                Text("EQUIP")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .padding(20)
        }
    }

    private var itemTypeTitle: String {
        switch heroItemType {
        case .helmet: return "Select Helmet"
        case .gloves: return "Select Gloves"
        case .shoes: return "Select Shoes"
        case .upperBody: return "Select Upper Body"
        case .bottomBody: return "Select Bottom Body"
        case .shirt: return "Select Shirt"
        case .weapons: return "Select Weapon"
        case .shields: return "Select Shield"
        case .ring: return "Select Ring"
        case .necklace: return "Select Necklace"
        case .earrings: return "Select Earrings"
        }
    }
}
