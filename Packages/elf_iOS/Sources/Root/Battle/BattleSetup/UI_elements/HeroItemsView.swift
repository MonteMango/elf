//
//  HeroItemsView.swift
//
//
//  Created by Vitalii Lytvynov on 15.09.24.
//

import elf_UIKit
import UIKit

internal final class HeroItemsView: NiblessView {
    
    internal var onItemSelected: ((HeroItemButtonType) -> Void)?
    
    // MARK: UI Controls
    
    // Left
    
    internal lazy var helmetItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.helmet.rawValue
        return button
    }()
    
    internal lazy var glovesItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.gloves.rawValue
        return button
    }()
    
    internal lazy var shoesItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.shoes.rawValue
        return button
    }()
    
    internal lazy var weaponPrimaryItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.weaponPrimary.rawValue
        return button
    }()
    
    // Right
    
    internal lazy var upperBodyItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.upperBody.rawValue
        return button
    }()
    
    internal lazy var bottomBodyItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.bottomBody.rawValue
        return button
    }()
    
    internal lazy var shirtItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.shirt.rawValue
        return button
    }()
    
    internal lazy var weaponSecondaryFilterView: UIView = {
        let view = UIView()
        view.alpha = 0.4
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()
    
    internal lazy var weaponScondaryItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .item)
        button.tag = HeroItemButtonType.weaponSecondary.rawValue
        return button
    }()
    
    //  Center
    
    internal lazy var ringItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .jewelryItem)
        button.tag = HeroItemButtonType.ring.rawValue
        return button
    }()
    
    internal lazy var necklaceItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .jewelryItem)
        button.tag = HeroItemButtonType.necklace.rawValue
        return button
    }()
    
    internal lazy var earringsItemButton: ElfButton = {
        let button = ElfButton(buttonStyle: .jewelryItem)
        button.tag = HeroItemButtonType.earrings.rawValue
        return button
    }()
    
    // MARK: Initializer
    
    internal override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
        configureControls()
    }
    
    private func styleView() {
        
    }
    
    private func constructHierarchy() {
        addSubview(helmetItemButton)
        addSubview(glovesItemButton)
        addSubview(shoesItemButton)
        addSubview(weaponPrimaryItemButton)
        
        addSubview(upperBodyItemButton)
        addSubview(bottomBodyItemButton)
        addSubview(shirtItemButton)
        addSubview(weaponScondaryItemButton)
        addSubview(weaponSecondaryFilterView)
        
        addSubview(ringItemButton)
        addSubview(necklaceItemButton)
        addSubview(earringsItemButton)
    }
    
    private func activateConstraints() {
        helmetItemButton.translatesAutoresizingMaskIntoConstraints = false
        glovesItemButton.translatesAutoresizingMaskIntoConstraints = false
        shoesItemButton.translatesAutoresizingMaskIntoConstraints = false
        weaponPrimaryItemButton.translatesAutoresizingMaskIntoConstraints = false
        
        upperBodyItemButton.translatesAutoresizingMaskIntoConstraints = false
        bottomBodyItemButton.translatesAutoresizingMaskIntoConstraints = false
        shirtItemButton.translatesAutoresizingMaskIntoConstraints = false
        weaponScondaryItemButton.translatesAutoresizingMaskIntoConstraints = false
        weaponSecondaryFilterView.translatesAutoresizingMaskIntoConstraints = false
        
        ringItemButton.translatesAutoresizingMaskIntoConstraints = false
        necklaceItemButton.translatesAutoresizingMaskIntoConstraints = false
        earringsItemButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // helmetItemButton
            helmetItemButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            helmetItemButton.topAnchor.constraint(equalTo: topAnchor),
            
            // glovesItemButton
            glovesItemButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            glovesItemButton.topAnchor.constraint(equalTo: helmetItemButton.bottomAnchor),
            
            // shoesItemButton
            shoesItemButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            shoesItemButton.topAnchor.constraint(equalTo: glovesItemButton.bottomAnchor),
            
            // weaponPrimaryItemButton
            weaponPrimaryItemButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            weaponPrimaryItemButton.topAnchor.constraint(equalTo: shoesItemButton.bottomAnchor),
            weaponPrimaryItemButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // upperBodyItemButton
            upperBodyItemButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            upperBodyItemButton.topAnchor.constraint(equalTo: topAnchor),
            
            // bottomBodyItemButton
            bottomBodyItemButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBodyItemButton.topAnchor.constraint(equalTo: upperBodyItemButton.bottomAnchor),
            
            // shirtItemButton
            shirtItemButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            shirtItemButton.topAnchor.constraint(equalTo: bottomBodyItemButton.bottomAnchor),
            
            // weaponScondaryItemButton
            weaponScondaryItemButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            weaponScondaryItemButton.topAnchor.constraint(equalTo: shirtItemButton.bottomAnchor),
            weaponScondaryItemButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // weaponSecondaryFilterView
            weaponSecondaryFilterView.leadingAnchor.constraint(equalTo: weaponScondaryItemButton.leadingAnchor),
            weaponSecondaryFilterView.trailingAnchor.constraint(equalTo: weaponScondaryItemButton.trailingAnchor),
            weaponSecondaryFilterView.topAnchor.constraint(equalTo: weaponScondaryItemButton.topAnchor),
            weaponSecondaryFilterView.bottomAnchor.constraint(equalTo: weaponScondaryItemButton.bottomAnchor),
            
            // ringItemButton
            ringItemButton.leadingAnchor.constraint(equalTo: weaponPrimaryItemButton.trailingAnchor, constant: 20),
            ringItemButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // necklaceItemButton
            necklaceItemButton.leadingAnchor.constraint(equalTo: ringItemButton.trailingAnchor),
            necklaceItemButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // earringsItemButton
            earringsItemButton.leadingAnchor.constraint(equalTo: necklaceItemButton.trailingAnchor),
            earringsItemButton.trailingAnchor.constraint(equalTo: weaponScondaryItemButton.leadingAnchor, constant: -20),
            earringsItemButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func configureControls() {
        helmetItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        glovesItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        shoesItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        weaponPrimaryItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        
        upperBodyItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        bottomBodyItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        shirtItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        weaponScondaryItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        
        ringItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        necklaceItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
        earringsItemButton.addTarget(self, action: #selector(itemButtonAction(_:)), for: .touchUpInside)
    }
    
    @objc
    private func itemButtonAction(_ sender: ElfButton) {
        guard let itemType = HeroItemButtonType(rawValue: sender.tag) else { return }
        onItemSelected?(itemType)
    }
}

internal enum HeroItemButtonType: Int {
    case helmet = 1
    case gloves = 2
    case shoes = 3
    case weaponPrimary = 4
    case weaponSecondary = 5
    case upperBody = 6
    case bottomBody = 7
    case shirt = 8
    case ring = 9
    case necklace = 10
    case earrings = 11
}
