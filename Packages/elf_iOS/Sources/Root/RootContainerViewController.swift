//
//  RootContainerViewController.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import Combine
import elf_Kit
import elf_UIKit
import Foundation

public final class RootContainerViewController: NiblessContainerViewController {
    
    // MARK: - Properties
    
    private let viewModel: RootViewModel
    
    // Child View Controller
    private let menuViewController: MenuViewController
    private var battleContainerViewController: BattleContainerViewController?
    
    // Factories
    private let makeBattleContainerViewControllerFactory: () -> BattleContainerViewController
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Methods
    
    internal init(viewModel: RootViewModel,
                menuViewController: MenuViewController,
                  battleContainerViewControllerFactory: @escaping () -> BattleContainerViewController) {
        self.viewModel = viewModel
        self.menuViewController = menuViewController
        self.makeBattleContainerViewControllerFactory = battleContainerViewControllerFactory
        super.init()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel
            .$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewState in
                guard let self = self else { return }
                switch viewState {
                case .menu:
                    if let battleContainerViewController = self.battleContainerViewController {
                        hideViewController(battleContainerViewController)
                        removeViewController(battleContainerViewController)
                    }
                    
                    showViewController(self.menuViewController)
                case .battle:
                    hideViewController(menuViewController)
                    if self.battleContainerViewController == nil {
                        self.battleContainerViewController = makeBattleContainerViewControllerFactory()
                        guard let battleContainerViewController = battleContainerViewController else { return }
                        addViewController(battleContainerViewController)
                    }
                    
                    guard let battleContainerViewController = battleContainerViewController else { return }
                    showViewController(battleContainerViewController)
                }
            }.store(in: &subscriptions)
    }
    
    public override func loadView() {
        super.loadView()
        
        addViewController(self.menuViewController)
        showViewController(self.menuViewController)
    }
}
