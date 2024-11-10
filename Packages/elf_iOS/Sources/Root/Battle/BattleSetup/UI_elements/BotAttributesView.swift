//
//  BotAttributesView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 26.10.24.
//

import elf_Kit
import elf_UIKit
import UIKit

internal final class BotAttributesView: NiblessView, AttributesView {
    
    // MARK: UI Controls
    
    internal lazy var strengthTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "Strength")
        return label
    }()
    
    internal lazy var strengthCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var agilityTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "Agility")
        return label
    }()
    
    internal lazy var agilityCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var powerTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "Power")
        return label
    }()
    
    internal lazy var powerCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var instinctTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "Instinct")
        return label
    }()
    
    internal lazy var instinctCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var attackPrimaryTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "Att 1")
        return label
    }()
    
    internal lazy var attackPrimaryCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var attackSecondaryTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "Att 2")
        return label
    }()
    
    internal lazy var attackSecondaryCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var hitPointsTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "HP")
        return label
    }()
    
    internal lazy var hitPointsCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
        return label
    }()
    
    internal lazy var manaPointsTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotTitleLabel, text: "MP")
        return label
    }()
    
    internal lazy var manaPointsCalculationLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .attributeBotCalculationLabel)
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
            strengthTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            strengthTitleLabel.topAnchor.constraint(equalTo: topAnchor),
            
            // strengthCalculationLabel
            strengthCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            strengthCalculationLabel.topAnchor.constraint(equalTo: strengthTitleLabel.bottomAnchor),
            
            // agilityTitleLabel
            agilityTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            agilityTitleLabel.topAnchor.constraint(equalTo: strengthCalculationLabel.bottomAnchor, constant: 15),
            
            // agilityCalculationLabel
            agilityCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            agilityCalculationLabel.topAnchor.constraint(equalTo: agilityTitleLabel.bottomAnchor),
            
            // powerTitleLabel
            powerTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            powerTitleLabel.topAnchor.constraint(equalTo: agilityCalculationLabel.bottomAnchor, constant: 15),
            
            // powerCalculationLabel
            powerCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            powerCalculationLabel.topAnchor.constraint(equalTo: powerTitleLabel.bottomAnchor),
            
            // instinctTitleLabel
            instinctTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            instinctTitleLabel.topAnchor.constraint(equalTo: powerCalculationLabel.bottomAnchor, constant: 15),
            
            // instinctCalculationLabel
            instinctCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            instinctCalculationLabel.topAnchor.constraint(equalTo: instinctTitleLabel.bottomAnchor),
            instinctCalculationLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // attackPrimaryTitleLabel
            attackPrimaryTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            attackPrimaryTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            attackPrimaryTitleLabel.topAnchor.constraint(equalTo: topAnchor),
            
            // attackPrimaryCalculationLabel
            attackPrimaryCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            attackPrimaryCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            attackPrimaryCalculationLabel.topAnchor.constraint(equalTo: attackPrimaryTitleLabel.bottomAnchor),
            
            // attackSecondaryTitleLabel
            attackSecondaryTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            attackSecondaryTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            attackSecondaryTitleLabel.topAnchor.constraint(equalTo: attackPrimaryCalculationLabel.bottomAnchor, constant: 15),
            
            // attackSecondaryCalculationLabel
            attackSecondaryCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            attackSecondaryCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            attackSecondaryCalculationLabel.topAnchor.constraint(equalTo: attackSecondaryTitleLabel.bottomAnchor),
            
            // hitPointsTitleLabel
            hitPointsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            hitPointsTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            hitPointsTitleLabel.topAnchor.constraint(equalTo: attackSecondaryCalculationLabel.bottomAnchor, constant: 15),
            
            // hitPointsCalculationLabel
            hitPointsCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            hitPointsCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            hitPointsCalculationLabel.topAnchor.constraint(equalTo: hitPointsTitleLabel.bottomAnchor),
            
            // manaPointsTitleLabel
            manaPointsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            manaPointsTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            manaPointsTitleLabel.topAnchor.constraint(equalTo: hitPointsCalculationLabel.bottomAnchor, constant: 15),
            
            // manaPointsCalculationLabel
            manaPointsCalculationLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            manaPointsCalculationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65),
            manaPointsCalculationLabel.topAnchor.constraint(equalTo: manaPointsTitleLabel.bottomAnchor),
            manaPointsCalculationLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: Methods
    
    internal func updateAttributes(fightStyleAttributes: HeroAttributes?, levelRandomAttributes: [Int16: HeroAttributes]?, itemsAttributes: HeroAttributes?) {
        strengthCalculationLabel.text = formattedText(
            fightStyleAttributes?.strength,
            sumOfLevelAttributes(for: \.strength, in: levelRandomAttributes),
            itemsAttributes?.strength
        )
        
        agilityCalculationLabel.text = formattedText(
            fightStyleAttributes?.agility,
            sumOfLevelAttributes(for: \.agility, in: levelRandomAttributes),
            itemsAttributes?.agility
        )
        
        powerCalculationLabel.text = formattedText(
            fightStyleAttributes?.power,
            sumOfLevelAttributes(for: \.power, in: levelRandomAttributes),
            itemsAttributes?.power
        )
        
        instinctCalculationLabel.text = formattedText(
            fightStyleAttributes?.instinct,
            sumOfLevelAttributes(for: \.instinct, in: levelRandomAttributes),
            itemsAttributes?.instinct
        )
        
        hitPointsCalculationLabel.text = formattedText(
            fightStyleAttributes?.hitPoints,
            sumOfLevelAttributes(for: \.hitPoints, in: levelRandomAttributes),
            itemsAttributes?.hitPoints
        )
        
        manaPointsCalculationLabel.text = formattedText(
            fightStyleAttributes?.manaPoints,
            sumOfLevelAttributes(for: \.manaPoints, in: levelRandomAttributes),
            itemsAttributes?.manaPoints
        )
    }
    
    // MARK: Private methods
    
    // Helper function to format the text as "A+B+C X"
    private func formattedText(_ fightStyleValue: Int16?, _ levelValueSum: Int16, _ itemValue: Int16?) -> String {
        let a: Int16 = fightStyleValue ?? 0
        let b: Int16 = levelValueSum
        let c: Int16 = itemValue ?? 0
        let total = a + b + c
        return "\(total) \(c)+\(b)+\(a)"
    }
    
    // Helper function to sum level attributes for a specific property
    private func sumOfLevelAttributes(for keyPath: KeyPath<HeroAttributes, Int16>, in levelAttributes: [Int16: HeroAttributes]?) -> Int16 {
        guard let levelAttributes = levelAttributes else { return 0 }
        return levelAttributes.values.reduce(0) { $0 + $1[keyPath: keyPath] }
    }
}
