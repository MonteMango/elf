//
//  ElfAppDependencyContainer.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import elf_Kit
import Foundation

public final class ElfAppDependencyContainer {
    
    // Long-lived dependencies
    internal let sharedRootViewModel: RootViewModel
    internal let itemsRepository: ItemsRepository
    
    public init() {
        self.itemsRepository = ElfItemsRepository()
        self.sharedRootViewModel = RootViewModel(itemsRepository: self.itemsRepository)
    }
    
    // MARK: Root
    
    public func makeRootViewController() -> RootContainerViewController {
        let battleContainerViewControllerFactory = {
            return self.makeBattleContainerViewController()
        }
        
        return RootContainerViewController(
            viewModel: self.sharedRootViewModel,
            menuViewController: makeMenuViewController(),
            battleContainerViewControllerFactory: battleContainerViewControllerFactory)
    }
    
    // MARK: Menu
    
    private func makeMenuViewController() -> MenuViewController {
        return MenuViewController(viewModel: makeMenuViewModel())
    }
    
    private func makeMenuViewModel() -> MenuViewModel {
        return MenuViewModel(rootViewStateDelegate: AnyViewStateDelegate(self.sharedRootViewModel))
    }
    
    // MARK: Battle
    
    private func makeBattleContainerViewController() -> BattleContainerViewController {
        let battleViewModel = makeBattleViewModel()
        let battleDependencyContainer = ElfBattleDependencyContainer(appDependencyContainer: self, battleViewModel: battleViewModel)
        let selectHeroItemViewControllerFactory = { (currentHeroItemId: UUID?, heroType:HeroType, heroItemType: HeroItemType) in
            return battleDependencyContainer.makeSelectHeroItemViewController(currentHeroItemId: currentHeroItemId, heroType: heroType, heroItemType: heroItemType)
        }
        
        return BattleContainerViewController(viewModel: battleViewModel,
                                             battleSetupViewController: battleDependencyContainer.makeBattleSetupViewController(), 
                                             selectHeroItemViewControllerFactory: selectHeroItemViewControllerFactory)
    }
    
    private func makeBattleViewModel() -> BattleViewModel {
        return BattleViewModel()
    }
}
