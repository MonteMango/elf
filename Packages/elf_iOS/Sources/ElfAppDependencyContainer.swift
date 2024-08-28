//
//  ElfAppDependencyContainer.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import elf_Kit

public final class ElfAppDependencyContainer {
    
    public init() {
        
    }
    
    //MARK: Root
    
    public func makeRootViewController() -> RootContainerViewController {
        return RootContainerViewController(viewModel: makeRootViewModel(), menuViewController: makeMenuViewController())
    }
    
    private func makeRootViewModel() -> RootViewModel {
        return RootViewModel()
    }
    
    //MARK: Menu
    
    private func makeMenuViewController() -> MenuViewController {
        return MenuViewController(viewModel: makeMenuViewModel())
    }
    
    private func makeMenuViewModel() -> MenuViewModel {
        return MenuViewModel()
    }
}
