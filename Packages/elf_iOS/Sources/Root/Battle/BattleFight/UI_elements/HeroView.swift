//
//  HeroView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 24.07.25.
//

import elf_UIKit
import UIKit

internal final class HeroView: NiblessView {
    
    // MARK: UI Controls
    
    // Hero
    
    internal lazy var heroImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    // Left

    internal lazy var helmetButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    internal lazy var glovesButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    internal lazy var shoesButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    internal lazy var leftWeaponButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    // Right
    
    internal lazy var upperBodyButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    internal lazy var lowerBodyButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    internal lazy var shirtButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    internal lazy var rightWeaponButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleIttem)
        return button
    }()
    
    //  Center
    
    internal lazy var ringButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleJewelryItem)
        return button
    }()
    
    internal lazy var necklaceButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleJewelryItem)
        return button
    }()
    
    internal lazy var earringsButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleJewelryItem)
        return button
    }()
    
    // MARK: Initializer
    
    internal override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
    }
    
    private func styleView() {

    }
    
    private func constructHierarchy() {
        addSubview(heroImageView)
        
        addSubview(helmetButton)
        addSubview(glovesButton)
        addSubview(shoesButton)
        addSubview(leftWeaponButton)
        
        addSubview(upperBodyButton)
        addSubview(lowerBodyButton)
        addSubview(shirtButton)
        addSubview(rightWeaponButton)
        
        addSubview(ringButton)
        addSubview(necklaceButton)
        addSubview(earringsButton)
    }
    
    private func activateConstraints() {
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        
        helmetButton.translatesAutoresizingMaskIntoConstraints = false
        glovesButton.translatesAutoresizingMaskIntoConstraints = false
        shoesButton.translatesAutoresizingMaskIntoConstraints = false
        leftWeaponButton.translatesAutoresizingMaskIntoConstraints = false
        
        upperBodyButton.translatesAutoresizingMaskIntoConstraints = false
        lowerBodyButton.translatesAutoresizingMaskIntoConstraints = false
        shirtButton.translatesAutoresizingMaskIntoConstraints = false
        rightWeaponButton.translatesAutoresizingMaskIntoConstraints = false
        
        ringButton.translatesAutoresizingMaskIntoConstraints = false
        necklaceButton.translatesAutoresizingMaskIntoConstraints = false
        earringsButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            // heroImageView
            heroImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heroImageView.topAnchor.constraint(equalTo: topAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // helmetButton
            helmetButton.topAnchor.constraint(equalTo: topAnchor),
            helmetButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            // helmetButton
            glovesButton.topAnchor.constraint(equalTo: helmetButton.bottomAnchor),
            glovesButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            // shoesButton
            shoesButton.topAnchor.constraint(equalTo: glovesButton.bottomAnchor),
            shoesButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            
            // leftWeaponButton
            leftWeaponButton.topAnchor.constraint(equalTo: shoesButton.bottomAnchor),
            leftWeaponButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftWeaponButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // upperBodyButton
            upperBodyButton.topAnchor.constraint(equalTo: topAnchor),
            upperBodyButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // lowerBodyButton
            lowerBodyButton.topAnchor.constraint(equalTo: upperBodyButton.bottomAnchor),
            lowerBodyButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // shirtButton
            shirtButton.topAnchor.constraint(equalTo: lowerBodyButton.bottomAnchor),
            shirtButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // rightWeaponButton
            rightWeaponButton.topAnchor.constraint(equalTo: shirtButton.bottomAnchor),
            rightWeaponButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightWeaponButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // ringButton
            ringButton.leadingAnchor.constraint(equalTo: leftWeaponButton.trailingAnchor, constant: 10),
            ringButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // necklaceButton
            necklaceButton.leadingAnchor.constraint(equalTo: ringButton.trailingAnchor),
            necklaceButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // earringsButton
            earringsButton.leadingAnchor.constraint(equalTo: necklaceButton.trailingAnchor),
            earringsButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            earringsButton.trailingAnchor.constraint(equalTo: rightWeaponButton.leadingAnchor, constant: -10)
        ])
        
    }
}
