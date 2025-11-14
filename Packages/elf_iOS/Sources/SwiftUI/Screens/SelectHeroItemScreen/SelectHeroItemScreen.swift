//
//  SelectHeroItemScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import SwiftUI
import elf_Kit
import Combine

internal struct SelectHeroItemScreen: View {
    @State private var viewModel: NewSelectHeroItemViewModel

    internal init(viewModel: NewSelectHeroItemViewModel) {
        self._viewModel = State(initialValue: viewModel)
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
            Button(action: viewModel.closeButtonAction) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding(20)
        }
        .overlay(alignment: .bottomTrailing) {
            // Equip button
            Button(action: viewModel.equipButtonAction) {
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
        switch viewModel.heroItemType {
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

// MARK: - Preview

#Preview {
    // Mock Item for preview
    struct MockItem: Item {
        let id: UUID
        let title: String
        let tier: Int16
        var isUnique: Bool?
        var strength: Int16?
        var agility: Int16?
        var power: Int16?
        var instinct: Int16?
        var hitPoints: Int16?
        var manaPoints: Int16?
    }

    // Mock Repository
    class MockItemsRepository: ItemsRepository {
        var heroItems: HeroItems?
        var heroItemsPublisher: AnyPublisher<HeroItems?, Never> {
            Just(heroItems).eraseToAnyPublisher()
        }

        func loadHeroItems() async throws {
            // Mock implementation - do nothing
        }

        func getHeroItem(_ id: UUID) async -> Item? {
            // Mock implementation - return nil
            return nil
        }
    }

    let mockRepository = MockItemsRepository()
    let viewModel = NewSelectHeroItemViewModel(
        heroType: .player,
        heroItemType: .helmet,
        currentItemId: nil,
        navigationManager: AppNavigationManager(),
        itemsRepository: mockRepository,
        onItemSelected: { id in print("Selected: \(String(describing: id))") }
    )

    // Add mock items with real UUIDs from assets
    viewModel.availableItems = [
        MockItem(
            id: UUID(uuidString: "a9d587dd-c44a-466b-87d2-3601f142ac02")!,
            title: "Dragon Helmet",
            tier: 3,
            strength: 15,
            agility: 5,
            hitPoints: 30
        ),
        MockItem(
            id: UUID(uuidString: "6023cc65-b183-4d41-8742-f1ecb0172942")!,
            title: "Legendary Helmet",
            tier: 4,
            isUnique: true,
            strength: 20,
            agility: 10,
            power: 5,
            hitPoints: 50
        ),
        MockItem(
            id: UUID(uuidString: "8313bc77-0cc6-423b-ba59-ead9c360e0eb")!,
            title: "Ancient Shield",
            tier: 3,
            strength: 12,
            hitPoints: 25
        ),
        MockItem(
            id: UUID(uuidString: "ff81624c-5da6-4302-8432-70e802e94159")!,
            title: "Titan Shield",
            tier: 4,
            strength: 18,
            hitPoints: 40
        ),
        MockItem(
            id: UUID(uuidString: "50c98297-08ea-4f6a-ae80-54d5d2830ec2")!,
            title: "Battle Axe",
            tier: 3,
            strength: 20,
            power: 10,
            hitPoints: 15
        )
    ]
    viewModel.isLoading = false

    return SelectHeroItemScreen(viewModel: viewModel)
        .background(Color.black)
}
