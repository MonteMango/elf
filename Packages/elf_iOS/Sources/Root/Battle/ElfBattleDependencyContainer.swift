//
//  ElfBattleDependencyContainer.swift
//
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_Kit

internal final class ElfBattleDependencyContainer {

    // From parent container
    private let rootViewModel: RootViewModel
    
    internal init(appDependencyContainer: ElfAppDependencyContainer) {
        self.rootViewModel = appDependencyContainer.sharedRootViewModel
    }
    
    // MARK: BattleSetup
    
    internal func makeBattleSetupViewController() -> BattleSetupViewController {
        return BattleSetupViewController(viewModel: makeBattleSetupViewModel())
    }
    
    internal func makeBattleSetupViewModel() -> BattleSetupViewModel {
        return BattleSetupViewModel(rootViewStateDelegate: AnyViewStateDelegate(rootViewModel))
    }
    
    // MARK: BattleFight
    
    internal func makeBattleFightViewController() -> BattleFightViewController {
        return BattleFightViewController(viewModel: makeBattleFightViewModel())
    }
    
    internal func makeBattleFightViewModel() -> BattleFightViewModel {
        return BattleFightViewModel()
    }
}
