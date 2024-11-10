//
//  BattleSetupScreenView.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_UIKit
import UIKit

internal final class BattleSetupScreenView: NiblessView {
    
    // MARK: UI Controls
    
    internal lazy var closeButton: ElfButton = {
        let button = ElfButton(buttonStyle: .close)
        return button
    }()
    
    // user
    
    internal lazy var userSelectFightStyleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .battleTitleLabel, text: "Fight style")
        return label
    }()
    
    internal lazy var userSelectFightStyleStackView: SelectFightStyleStackView = {
        let stackView = SelectFightStyleStackView()
        return stackView
    }()
    
    internal lazy var userLevelLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .battleTitleLabel, text: "Level")
        return label
    }()
    
    internal lazy var userLevelView: HeroLevelView = {
        let view = HeroLevelView()
        return view
    }()
    
    internal lazy var userHeroItemsView: HeroItemsView = {
        let view = HeroItemsView()
        return view
    }()
    
    internal lazy var userAttributesView: PlayerAttributesView = {
        let view = PlayerAttributesView()
        return view
    }()
    
    // bot
    
    internal lazy var botSelectFightStyleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .battleTitleLabel, text: "Fight style")
        return label
    }()
    
    internal lazy var botSelectFightStyleStackView: SelectFightStyleStackView = {
        let stackView = SelectFightStyleStackView()
        return stackView
    }()
    
    internal lazy var botLevelLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .battleTitleLabel, text: "Level")
        return label
    }()
    
    internal lazy var botLevelView: HeroLevelView = {
        let view = HeroLevelView()
        return view
    }()
    
    internal lazy var botHeroItemsView: HeroItemsView = {
        let view = HeroItemsView()
        return view
    }()
    
    internal lazy var botAttributesView: BotAttributesView = {
        let view = BotAttributesView()
        return view
    }()
    
    // common
    
    internal lazy var separatorView: NiblessView = {
        let view = NiblessView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return view
    }()
    
    internal lazy var fightButton: ElfButton = {
        let button = ElfButton(buttonStyle: .actionButton, centerText: "Battle")
        button.isEnabled = false
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
        backgroundColor = UIColor.systemBackground
    }
    
    private func constructHierarchy() {
        addSubview(closeButton)
        
        addSubview(userSelectFightStyleLabel)
        addSubview(userSelectFightStyleStackView)
        addSubview(userLevelLabel)
        addSubview(userLevelView)
        addSubview(userHeroItemsView)
        addSubview(userAttributesView)
        
        addSubview(botSelectFightStyleLabel)
        addSubview(botSelectFightStyleStackView)
        addSubview(botLevelLabel)
        addSubview(botLevelView)
        addSubview(botHeroItemsView)
        addSubview(botAttributesView)
        
        addSubview(fightButton)
        addSubview(separatorView)
    }
    
    private func activateConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        userSelectFightStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        userSelectFightStyleStackView.translatesAutoresizingMaskIntoConstraints = false
        userLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        userLevelView.translatesAutoresizingMaskIntoConstraints = false
        userHeroItemsView.translatesAutoresizingMaskIntoConstraints = false
        userAttributesView.translatesAutoresizingMaskIntoConstraints = false
        
        botSelectFightStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        botSelectFightStyleStackView.translatesAutoresizingMaskIntoConstraints = false
        botLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        botLevelView.translatesAutoresizingMaskIntoConstraints = false
        botHeroItemsView.translatesAutoresizingMaskIntoConstraints = false
        botAttributesView.translatesAutoresizingMaskIntoConstraints = false
        
        fightButton.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // closeButton
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 30),
            
            // userSelectFightStyleLabel
            userSelectFightStyleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            userSelectFightStyleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 50),
            
            // userSelectFightStyleStackView
            userSelectFightStyleStackView.topAnchor.constraint(equalTo: userSelectFightStyleLabel.bottomAnchor, constant: 5),
            userSelectFightStyleStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 50),
            
            // userLevelLabel
            userLevelLabel.centerXAnchor.constraint(equalTo: userLevelView.centerXAnchor),
            userLevelLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            
            // userLevelView
            userLevelView.leadingAnchor.constraint(equalTo: userSelectFightStyleStackView.trailingAnchor, constant: 50),
            userLevelView.topAnchor.constraint(equalTo: userLevelLabel.bottomAnchor, constant: 5),
            
            //userHeroItemsView
            userHeroItemsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            userHeroItemsView.topAnchor.constraint(equalTo: userSelectFightStyleStackView.bottomAnchor, constant: 20),
            
            // userAttributesView
            userAttributesView.leadingAnchor.constraint(equalTo: userHeroItemsView.trailingAnchor, constant: 15),
            userAttributesView.bottomAnchor.constraint(equalTo: fightButton.topAnchor, constant: -15),
            
            // botSelectFightStyleLabel
            botSelectFightStyleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            botSelectFightStyleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            
            // botSelectFightStyleStackView
            botSelectFightStyleStackView.topAnchor.constraint(equalTo: botSelectFightStyleLabel.bottomAnchor, constant: 5),
            botSelectFightStyleStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            
            // botLevelLabel
            botLevelLabel.centerXAnchor.constraint(equalTo: botLevelView.centerXAnchor),
            botLevelLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            
            // botLevelView
            botLevelView.trailingAnchor.constraint(equalTo: botSelectFightStyleStackView.leadingAnchor, constant: -50),
            botLevelView.topAnchor.constraint(equalTo: botLevelLabel.bottomAnchor, constant: 5),
            
            // botHeroItemsView
            botHeroItemsView.trailingAnchor.constraint(equalTo: trailingAnchor,constant: -20),
            botHeroItemsView.topAnchor.constraint(equalTo: botSelectFightStyleStackView.bottomAnchor, constant: 20),
            
            // botAttributesView
            botAttributesView.trailingAnchor.constraint(equalTo: botHeroItemsView.leadingAnchor, constant: -15),
            botAttributesView.bottomAnchor.constraint(equalTo: fightButton.topAnchor, constant: -15),
            
            // fightButton
            fightButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            fightButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // separatorView
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: fightButton.topAnchor, constant: -15),
            separatorView.centerXAnchor.constraint(equalTo: fightButton.centerXAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 2)
        ])
    }
}
