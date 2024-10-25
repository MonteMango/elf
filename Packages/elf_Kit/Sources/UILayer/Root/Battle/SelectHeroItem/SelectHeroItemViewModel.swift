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
    
    public func didSelectItem(at indexPath: IndexPath, itemId: UUID?) {
        selectedHeroItem.send((heroType, heroItemType, itemId))
    }
    
    // MARK: Actions
    
    @objc
    public func closeButtonAction() {
        battleViewStateDelegate.setViewState(.setup)
    }
}
