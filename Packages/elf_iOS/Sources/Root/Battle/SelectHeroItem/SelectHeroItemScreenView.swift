//
//  SelectHeroItemScreenView.swift
//
//
//  Created by Vitalii Lytvynov on 19.09.24.
//

import elf_UIKit
import UIKit

internal final class SelectHeroItemScreenView: NiblessView {
    
    private var backgroundViewBottomConstraint: NSLayoutConstraint?
    private var backgroundViewCenterYConstraint: NSLayoutConstraint?
    
    // MARK: UI Controls
    
    internal lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.borderWidth = 8.0
        view.layer.borderColor = UIColor.tertiarySystemGroupedBackground.cgColor
        return view
    }()
    
    internal lazy var itemsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(HeroItemCollectionViewCell.self, forCellWithReuseIdentifier: HeroItemCollectionViewCell.reuseIdentifier)
        collectionView.register(EmptyHeroItemCollectionViewCell.self, forCellWithReuseIdentifier: EmptyHeroItemCollectionViewCell.reuseIdentifier)
        
        return collectionView
    }()
    
    internal lazy var closeButton: ElfButton = {
        let button = ElfButton(buttonStyle: .close)
        return button
    }()
    
    internal lazy var equipButton: ElfButton = {
        let button = ElfButton(buttonStyle: .selectItemEquip)
        return button
    }()
    
    internal lazy var setupItemAttributesView: SetupItemAttributesView = {
        let view = SetupItemAttributesView()
        return view
    }()
    
    // MARK: Initializer
    
    internal override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
    }
    
    private func styleView() {
        backgroundColor = UIColor.systemGreen.withAlphaComponent(0.0)
    }
    
    private func constructHierarchy() {
        backgroundView.addSubview(itemsCollectionView)
        addSubview(backgroundView)
        addSubview(closeButton)
        addSubview(equipButton)
        addSubview(setupItemAttributesView)
    }
    
    private func activateConstraints() {
        backgroundViewBottomConstraint = backgroundView.centerYAnchor.constraint(equalTo: self.bottomAnchor, constant: 180)
        backgroundViewCenterYConstraint = backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)
        guard let backgroundViewBottomConstraint = self.backgroundViewBottomConstraint else { return }
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        itemsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        equipButton.translatesAutoresizingMaskIntoConstraints = false
        setupItemAttributesView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            // backgroundView
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: 740),
            backgroundView.heightAnchor.constraint(equalToConstant: 300),
            backgroundViewBottomConstraint,
            
            // itemsCollectionView
            itemsCollectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            itemsCollectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            itemsCollectionView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            itemsCollectionView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            
            // closeButton
            closeButton.centerXAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: backgroundView.topAnchor),
            
            // equipButton
            equipButton.centerYAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            equipButton.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor),
            
            // setupItemAttributesView
            setupItemAttributesView.centerYAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            setupItemAttributesView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: -25)
        ])
    }
    
    // MARK: Methods
    
    internal func updateBackgroundViewPositionForCenter() {
        backgroundViewBottomConstraint?.isActive = false
        backgroundViewCenterYConstraint?.isActive = true
    }
}
