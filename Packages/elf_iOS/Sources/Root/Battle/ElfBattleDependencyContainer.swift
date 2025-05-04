//
//  ElfBattleDependencyContainer.swift
//
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_Kit
import Foundation

internal final class ElfBattleDependencyContainer {

    // From parent container
    private let rootViewModel: RootViewModel
    private let itemsRepository: ItemsRepository
    
    // Long-lived
    private let sharedBattleViewModel: BattleViewModel
    private let sharedAttributeService: AttributeService
    private let sharedArmorService: ArmorService
    
    // Temporal
    private weak var sharedBattleSetupViewModel: BattleSetupViewModel?
    
    internal init(appDependencyContainer: ElfAppDependencyContainer, battleViewModel: BattleViewModel) {
        self.sharedBattleViewModel = battleViewModel
        self.rootViewModel = appDependencyContainer.sharedRootViewModel
        self.itemsRepository = appDependencyContainer.itemsRepository
        self.sharedAttributeService = ElfAttributeService(itemsRepository: self.itemsRepository)
        self.sharedArmorService = ElfArmorService(itemsRepository: self.itemsRepository)
    }
    
    // MARK: BattleSetup
    
    internal func makeBattleSetupViewController() -> BattleSetupViewController {
        return BattleSetupViewController(viewModel: makeBattleSetupViewModel())
    }
    
    internal func makeBattleSetupViewModel() -> BattleSetupViewModel {
        let viewModel = BattleSetupViewModel(
            rootViewStateDelegate: AnyViewStateDelegate(rootViewModel),
            battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>(sharedBattleViewModel),
            attributeService: self.sharedAttributeService,
            armorService: self.sharedArmorService)
        self.sharedBattleSetupViewModel = viewModel
        return viewModel
    }
    
    // MARK: BattleFight
    
    internal func makeBattleFightViewController() -> BattleFightViewController {
        return BattleFightViewController(viewModel: makeBattleFightViewModel())
    }
    
    internal func makeBattleFightViewModel() -> BattleFightViewModel {
        return BattleFightViewModel()
    }
    
    // MARK: SelectHeroItem
    
    internal func makeSelectHeroItemViewController(currentHeroItemId: UUID?, heroType: HeroType, heroItemType: HeroItemType) -> SelectHeroItemViewController {
        return SelectHeroItemViewController(viewModel: makeSelectHeroItemViewModel(currentHeroItemId: currentHeroItemId, heroType: heroType, heroItemType: heroItemType))
    }
    
    internal func makeSelectHeroItemViewModel(currentHeroItemId: UUID?, heroType: HeroType, heroItemType: HeroItemType) -> SelectHeroItemViewModel {
        let viewModel = SelectHeroItemViewModel(
            currentHeroItemId: currentHeroItemId,
            heroType: heroType,
            heroItemType: heroItemType,
            battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>(sharedBattleViewModel),
            itemsRepository: self.itemsRepository)
        sharedBattleSetupViewModel?.selectHeroItemViewModel = viewModel
        return viewModel
    }

}
