//
//  SelectHeroItemViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 19.09.24.
//

import elf_Kit
import elf_UIKit
import UIKit

internal final class SelectHeroItemViewController: NiblessViewController {
    
    // MARK: Properties
    
    private let viewModel: SelectHeroItemViewModel
    private let screenView: SelectHeroItemScreenView
    
    private var dataSource: SelectHeroItemDataSource!
    
    private lazy var flowLayoutDelegate = SelectHeroItemFlowLayout(viewModel: viewModel, dataSource: dataSource)
    
    internal init(viewModel: SelectHeroItemViewModel) {
        self.viewModel = viewModel
        self.screenView = SelectHeroItemScreenView()
        super.init()
    }
    
    internal override func loadView() {
        super.loadView()
        view = screenView
    }
    
    internal override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performAppearAnimations()
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        setupBindings()
    }
    
    private func setupDataSource() {
        dataSource = SelectHeroItemDataSource(collectionView: screenView.itemsCollectionView, viewModel: viewModel)
    }
    
    private func setupBindings() {
        screenView.closeButton.addTarget(
            viewModel,
            action: #selector(viewModel.closeButtonAction),
            for: .touchUpInside)
        
        screenView.itemsCollectionView.delegate = flowLayoutDelegate
    }
    
    private func performAppearAnimations() {
           UIView.animate(withDuration: 0.2, animations: { [weak self] in
               self?.screenView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.4)
           })
           
           UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: { [weak self] in
               guard let self = self else { return }
               self.screenView.updateBackgroundViewPositionForCenter()
               self.view.layoutIfNeeded()
           }, completion: nil)
       }
}
