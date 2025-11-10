//
//  BattleContainerViewController.swift
//
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Combine
import elf_Kit
import elf_UIKit
import Foundation

public final class BattleContainerViewController: NiblessContainerViewController {
    
    // MARK: - Properties
    
    private let viewModel: BattleViewModel
    
    // Child View Controller
    private let battleSetupViewController: BattleSetupViewController
    private var selectHeroItemViewController: SelectHeroItemViewController?
    private var battleFightViewController: BattleFightViewController?
    
    // Factories
    private let makeSelectHeroItemViewControllerFactory: (UUID?, HeroType, HeroItemType) -> SelectHeroItemViewController
    private let makeBattleFightViewControllerFactory: (_ user: HeroConfiguration, _ enemy: HeroConfiguration) -> BattleFightViewController
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Methods
    
    internal init(viewModel: BattleViewModel,
                  battleSetupViewController: BattleSetupViewController,
                  selectHeroItemViewControllerFactory: @escaping (UUID?, HeroType, HeroItemType) -> SelectHeroItemViewController,
                  battleFightItemViewControllerFactory: @escaping (HeroConfiguration, HeroConfiguration) -> BattleFightViewController) {
        self.viewModel = viewModel
        self.battleSetupViewController = battleSetupViewController
        self.makeSelectHeroItemViewControllerFactory = selectHeroItemViewControllerFactory
        self.makeBattleFightViewControllerFactory = battleFightItemViewControllerFactory
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
                case .setup:
                    if let selectHeroItemViewController = self.selectHeroItemViewController {
                        hideViewController(selectHeroItemViewController)
                        removeViewController(selectHeroItemViewController)
                        self.selectHeroItemViewController = nil
                    }
                    
                    if let battleFightViewController = self.battleFightViewController {
                        hideViewController(battleFightViewController)
                        removeViewController(battleFightViewController)
                        self.battleFightViewController = nil
                    }
                case .selectItem(let heroType, let heroItemType, let currentHeroItemId):
                    if self.selectHeroItemViewController == nil {
                        self.selectHeroItemViewController = makeSelectHeroItemViewControllerFactory(currentHeroItemId, heroType, heroItemType)
                    }
                    
                    guard let selectHeroItemViewController = self.selectHeroItemViewController else { return }
                    addViewController(selectHeroItemViewController)
                    showAlertViewController(selectHeroItemViewController)
                case .fight(let user, let enemy):
                    if self.battleFightViewController == nil {
                        self.battleFightViewController = makeBattleFightViewControllerFactory(user, enemy)
                    }
                    
                    guard let battleFightViewController = self.battleFightViewController else { return }
                    addViewController(battleFightViewController)
                    showViewController(battleFightViewController)
                }
            }.store(in: &subscriptions)
    }
    
    public override func loadView() {
        super.loadView()
        
        addViewController(self.battleSetupViewController)
        showViewController(self.battleSetupViewController)
    }
}
