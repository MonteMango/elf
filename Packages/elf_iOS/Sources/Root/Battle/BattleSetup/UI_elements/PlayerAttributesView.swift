//
//  PlayerAttributesView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 26.10.24.
//

import elf_Kit
import elf_UIKit
import UIKit

internal final class PlayerAttributesView: NiblessView, AttributesView {
    
    internal lazy var strengthTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "Strength")
        return label
    }()
    
    internal lazy var strengthCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var agilityTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "Agility")
        return label
    }()
    
    internal lazy var agilityCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var powerTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "Power")
        return label
    }()
    
    internal lazy var powerCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var instinctTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "Instinct")
        return label
    }()
    
    internal lazy var instinctCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var attackPrimaryTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "Att 1")
        return label
    }()
    
    internal lazy var attackPrimaryCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var attackSecondaryTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "Att 2")
        return label
    }()
    
    internal lazy var attackSecondaryCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var hitPointsTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "HP")
        return label
    }()
    
    internal lazy var hitPointsCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
    }()
    
    internal lazy var manaPointsTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerTitleLabel, text: "MP")
        return label
    }()
    
    internal lazy var manaPointsCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributePlayerCalculationLabel)
        return label
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
        addSubview(strengthTitleLabel)
        addSubview(strengthCalculationLabel)
        
        addSubview(agilityTitleLabel)
        addSubview(agilityCalculationLabel)
        
        addSubview(powerTitleLabel)
        addSubview(powerCalculationLabel)
        
        addSubview(instinctTitleLabel)
        addSubview(instinctCalculationLabel)
        
        addSubview(attackPrimaryTitleLabel)
        addSubview(attackPrimaryCalculationLabel)
        
        addSubview(attackSecondaryTitleLabel)
        addSubview(attackSecondaryCalculationLabel)
        
        addSubview(hitPointsTitleLabel)
        addSubview(hitPointsCalculationLabel)
        
        addSubview(manaPointsTitleLabel)
        addSubview(manaPointsCalculationLabel)
    }
    
    private func activateConstraints() {
        strengthTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        strengthCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        agilityTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        agilityCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        powerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        powerCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        instinctTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        instinctCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        attackPrimaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        attackPrimaryCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        attackSecondaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        attackSecondaryCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        hitPointsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        hitPointsCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        manaPointsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        manaPointsCalculationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // strengthTitleLabel
            strengthTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            strengthTitleLabel.topAnchor.constraint(equalTo: topAnchor),
            
            // strengthCalculationLabel
            strengthCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            strengthCalculationLabel.topAnchor.constraint(equalTo: strengthTitleLabel.bottomAnchor),
            
            // agilityTitleLabel
            agilityTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            agilityTitleLabel.topAnchor.constraint(equalTo: strengthCalculationLabel.bottomAnchor, constant: 15),
            
            // agilityCalculationLabel
            agilityCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            agilityCalculationLabel.topAnchor.constraint(equalTo: agilityTitleLabel.bottomAnchor),
            
            // powerTitleLabel
            powerTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            powerTitleLabel.topAnchor.constraint(equalTo: agilityCalculationLabel.bottomAnchor, constant: 15),
            
            // powerCalculationLabel
            powerCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            powerCalculationLabel.topAnchor.constraint(equalTo: powerTitleLabel.bottomAnchor),
            
            // instinctTitleLabel
            instinctTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            instinctTitleLabel.topAnchor.constraint(equalTo: powerCalculationLabel.bottomAnchor, constant: 15),
            
            // instinctCalculationLabel
            instinctCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            instinctCalculationLabel.topAnchor.constraint(equalTo: instinctTitleLabel.bottomAnchor),
            instinctCalculationLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // attackPrimaryTitleLabel
            attackPrimaryTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            attackPrimaryTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            attackPrimaryTitleLabel.topAnchor.constraint(equalTo: topAnchor),
            
            // attackPrimaryCalculationLabel
            attackPrimaryCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            attackPrimaryCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            attackPrimaryCalculationLabel.topAnchor.constraint(equalTo: attackPrimaryTitleLabel.bottomAnchor),
            
            // attackSecondaryTitleLabel
            attackSecondaryTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            attackSecondaryTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            attackSecondaryTitleLabel.topAnchor.constraint(equalTo: attackPrimaryCalculationLabel.bottomAnchor, constant: 15),
            
            // attackSecondaryCalculationLabel
            attackSecondaryCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            attackSecondaryCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            attackSecondaryCalculationLabel.topAnchor.constraint(equalTo: attackSecondaryTitleLabel.bottomAnchor),
            
            // hitPointsTitleLabel
            hitPointsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            hitPointsTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            hitPointsTitleLabel.topAnchor.constraint(equalTo: attackSecondaryCalculationLabel.bottomAnchor, constant: 15),
            
            // hitPointsCalculationLabel
            hitPointsCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            hitPointsCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            hitPointsCalculationLabel.topAnchor.constraint(equalTo: hitPointsTitleLabel.bottomAnchor),
            
            // manaPointsTitleLabel
            manaPointsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            manaPointsTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            manaPointsTitleLabel.topAnchor.constraint(equalTo: hitPointsCalculationLabel.bottomAnchor, constant: 15),
            
            // manaPointsCalculationLabel
            manaPointsCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65),
            manaPointsCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            manaPointsCalculationLabel.topAnchor.constraint(equalTo: manaPointsTitleLabel.bottomAnchor),
            manaPointsCalculationLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: Methods
    
    internal func updateAttributes(fightStyleAttributes: HeroAttributes?, levelRandomAttributes: [Int16: HeroAttributes]?, itemsAttributes: HeroAttributes?) {
        strengthCalculationLabel.attributedText = formattedText(
            fightStyleAttributes?.strength,
            sumOfLevelAttributes(for: \.strength, in: levelRandomAttributes),
            itemsAttributes?.strength
        )
        
        agilityCalculationLabel.attributedText = formattedText(
            fightStyleAttributes?.agility,
            sumOfLevelAttributes(for: \.agility, in: levelRandomAttributes),
            itemsAttributes?.agility
        )
        
        powerCalculationLabel.attributedText = formattedText(
            fightStyleAttributes?.power,
            sumOfLevelAttributes(for: \.power, in: levelRandomAttributes),
            itemsAttributes?.power
        )
        
        instinctCalculationLabel.attributedText = formattedText(
            fightStyleAttributes?.instinct,
            sumOfLevelAttributes(for: \.instinct, in: levelRandomAttributes),
            itemsAttributes?.instinct
        )
        
        hitPointsCalculationLabel.attributedText = formattedText(
            fightStyleAttributes?.hitPoints,
            sumOfLevelAttributes(for: \.hitPoints, in: levelRandomAttributes),
            itemsAttributes?.hitPoints
        )
        
        manaPointsCalculationLabel.attributedText = formattedText(
            fightStyleAttributes?.manaPoints,
            sumOfLevelAttributes(for: \.manaPoints, in: levelRandomAttributes),
            itemsAttributes?.manaPoints
        )
    }
    
    // MARK: Private methods
    
    // Helper function to format the text as "X A+B+C"
    private func formattedText(_ fightStyleValue: Int16?, _ levelValueSum: Int16, _ itemValue: Int16?) -> NSAttributedString {
        let a: Int16 = fightStyleValue ?? 0
        let b: Int16 = levelValueSum
        let c: Int16 = itemValue ?? 0
        let total = a + b + c
        
        // Create the string components
        let firstPart = "\(total)"
        let secondPart = "\(a)+\(b)+\(c)"
        
        // Create a mutable attributed string
        let attributedString = NSMutableAttributedString(string: "\(firstPart) \(secondPart)")
        
        // Define the ranges for each part of the string
        let firstRange = NSRange(location: 0, length: firstPart.count)
        let secondRange = NSRange(location: firstPart.count + 1, length: secondPart.count)
        
        // Set attributes for the first part (X) -> bold, orange, font 12
        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 12), range: firstRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.orange, range: firstRange)
        
        // Set attributes for the second part (C+B+A) -> regular, white (with transparency), font 10
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 8), range: secondRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.8), range: secondRange)
        
        return attributedString
    }

    
    // Helper function to sum level attributes for a specific property
    private func sumOfLevelAttributes(for keyPath: KeyPath<HeroAttributes, Int16>, in levelAttributes: [Int16: HeroAttributes]?) -> Int16 {
        guard let levelAttributes = levelAttributes else { return 0 }
        return levelAttributes.values.reduce(0) { $0 + $1[keyPath: keyPath] }
    }
}
