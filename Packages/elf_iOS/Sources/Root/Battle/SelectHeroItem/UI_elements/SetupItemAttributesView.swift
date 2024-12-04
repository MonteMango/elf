//
//  SetupItemAttributesView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import elf_UIKit
import UIKit

internal final class SetupItemAttributesView: NiblessView {
    
    // MARK: UI Controls
    
    internal lazy var previousAttributesButton: ElfButton = {
        let button = ElfButton(buttonStyle: .selectItemPrevNextAttribute, centerText: "<")
        return button
    }()
    
    internal lazy var attributeLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .selectItemsAttributesLabel)
        return label
    }()
    
    internal lazy var nextAttributesButton: ElfButton = {
        let button = ElfButton(buttonStyle: .selectItemPrevNextAttribute, centerText: ">")
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
        addSubview(previousAttributesButton)
        addSubview(attributeLabel)
        addSubview(nextAttributesButton)
    }
    
    private func activateConstraints() {
        previousAttributesButton.translatesAutoresizingMaskIntoConstraints = false
        attributeLabel.translatesAutoresizingMaskIntoConstraints = false
        nextAttributesButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // previousAttributesButton
            previousAttributesButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            previousAttributesButton.topAnchor.constraint(equalTo: topAnchor),
            previousAttributesButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // attributeLabel
            attributeLabel.leadingAnchor.constraint(equalTo: previousAttributesButton.trailingAnchor),
            attributeLabel.topAnchor.constraint(equalTo: topAnchor),
            attributeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // nextAttributesButton
            nextAttributesButton.leadingAnchor.constraint(equalTo: attributeLabel.trailingAnchor),
            nextAttributesButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            nextAttributesButton.topAnchor.constraint(equalTo: topAnchor),
            nextAttributesButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
