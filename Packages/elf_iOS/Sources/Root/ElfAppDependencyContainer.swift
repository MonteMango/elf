//
//  ElfAppDependencyContainer.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import elf_Kit

public final class ElfAppDependencyContainer {
    
    // Long-lived dependencies
    internal let sharedRootViewModel: RootViewModel
    
    public init() {
        self.sharedRootViewModel = RootViewModel()
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
        let battleDependencyContainer = ElfBattleDependencyContainer(appDependencyContainer: self)
        return BattleContainerViewController(viewModel: makeBattleViewModel(),
                                             battleSetupViewController: battleDependencyContainer.makeBattleSetupViewController())
    }
    
    private func makeBattleViewModel() -> BattleViewModel {
        return BattleViewModel()
    }
}
