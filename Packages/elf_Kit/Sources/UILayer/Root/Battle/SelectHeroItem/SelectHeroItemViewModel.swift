//
//  SelectHeroItemViewModel.swift
//
//
//  Created by Vitalii Lytvynov on 20.09.24.
//

import Combine
import Foundation

public final class SelectHeroItemViewModel {
    
    private let battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>
    private let itemsRepository: ItemsRepository
    
    private var cancellables = Set<AnyCancellable>()
    
    public private(set) var currentHeroItemId: UUID?
    public private(set) var heroType: HeroType
    public private(set) var heroItemType: HeroItemType
    
    @Published public private(set) var heroItems: HeroItems?
    @Published public private(set) var selectedHeroItemId: UUID?
    
    public let selectedHeroItem = PassthroughSubject<(HeroType, HeroItemType, UUID?), Never>()
    
    public init(
        currentHeroItemId: UUID?,
        heroType: HeroType,
        heroItemType: HeroItemType,
        battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>,
        itemsRepository: ItemsRepository
    ) {
        self.currentHeroItemId = currentHeroItemId
        self.heroType = heroType
        self.heroItemType = heroItemType
        self.battleViewStateDelegate = battleViewStateDelegate
        self.itemsRepository = itemsRepository
        
        itemsRepository.heroItemsPublisher
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.heroItems, on: self)
                    .store(in: &cancellables)
    }
    
    // MARK: Methods
    
    public func didSelectItem(itemId: UUID?) {
        selectedHeroItemId = itemId
    }
    
    // Функция для фильтрации элементов на основе выбранного типа HeroItemType
    public func filterItems(for type: HeroItemType, in heroItems: HeroItems) -> [Item] {
        let itemsMap: [HeroItemType: [Item]] = [
            .helmet: heroItems.helmets,
            .gloves: heroItems.gloves,
            .shoes: heroItems.shoes,
            .upperBody: heroItems.upperBodies,
            .bottomBody: heroItems.bottomBodies,
            .shirt: heroItems.robes,
            .weapons: heroItems.weapons,
            .shields: heroItems.shields + heroItems.weapons.filter({ $0.handUse == .secondary }),
            .ring: heroItems.rings,
            .necklace: heroItems.necklaces,
            .earrings: heroItems.earrings
        ]
        
        return itemsMap[type] ?? []
    }
    
    // MARK: Actions
    
    @objc
    public func closeButtonAction() {
        battleViewStateDelegate.setViewState(.setup)
    }
    
    @objc
    public func equipButtonAction() {
        selectedHeroItem.send((heroType, heroItemType, self.selectedHeroItemId))
        battleViewStateDelegate.setViewState(.setup)
    }
}
