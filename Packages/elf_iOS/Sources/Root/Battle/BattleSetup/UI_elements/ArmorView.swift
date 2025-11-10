//
//  ArmorView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 02.05.25.
//

import elf_UIKit
import UIKit

internal final class ArmorView: NiblessView {
    
    // MARK: UI Controls
    
    // top
    
    internal lazy var topArmorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "armor")
        return imageView
    }()
    
    internal lazy var topArmorLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .armorTitleLabel)
        label.text = "0"
        return label
    }()
    
    // left
    
    internal lazy var leftArmorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "armor")
        return imageView
    }()
    
    internal lazy var leftArmorLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .armorTitleLabel)
        label.text = "0"
        return label
    }()
    
    // middle
    
    internal lazy var middleArmorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "armor")
        return imageView
    }()
    
    internal lazy var middleArmorLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .armorTitleLabel)
        label.text = "0"
        return label
    }()
    
    // right
    
    internal lazy var rightArmorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "armor")
        return imageView
    }()
    
    internal lazy var rightArmorLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .armorTitleLabel)
        label.text = "0"
        return label
    }()
    
    // bottom
    
    internal lazy var bottomArmorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "armor")
        return imageView
    }()
    
    internal lazy var bottomArmorLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .armorTitleLabel)
        label.text = "0"
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
        alpha = 0.35
    }
    
    private func constructHierarchy() {
        addSubview(topArmorImageView)
        addSubview(leftArmorImageView)
        addSubview(middleArmorImageView)
        addSubview(rightArmorImageView)
        addSubview(bottomArmorImageView)
        
        addSubview(topArmorLabel)
        addSubview(leftArmorLabel)
        addSubview(middleArmorLabel)
        addSubview(rightArmorLabel)
        addSubview(bottomArmorLabel)
    }
    
    private func activateConstraints() {
        topArmorImageView.translatesAutoresizingMaskIntoConstraints = false
        leftArmorImageView.translatesAutoresizingMaskIntoConstraints = false
        middleArmorImageView.translatesAutoresizingMaskIntoConstraints = false
        rightArmorImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomArmorImageView.translatesAutoresizingMaskIntoConstraints = false
        
        topArmorLabel.translatesAutoresizingMaskIntoConstraints = false
        leftArmorLabel.translatesAutoresizingMaskIntoConstraints = false
        middleArmorLabel.translatesAutoresizingMaskIntoConstraints = false
        rightArmorLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomArmorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            // topArmorImageView
            topArmorImageView.topAnchor.constraint(equalTo: topAnchor),
            topArmorImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            
            // leftArmorImageView
            leftArmorImageView.leftAnchor.constraint(equalTo: leftAnchor),
            leftArmorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // middleArmorImageView
            middleArmorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            middleArmorImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // rightArmorImageView
            rightArmorImageView.rightAnchor.constraint(equalTo: rightAnchor),
            rightArmorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // bottomArmorImageView
            bottomArmorImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomArmorImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // topArmorLabel
            topArmorLabel.centerXAnchor.constraint(equalTo: topArmorImageView.centerXAnchor),
            topArmorLabel.centerYAnchor.constraint(equalTo: topArmorImageView.centerYAnchor),
            
            // leftArmorLabel
            leftArmorLabel.centerXAnchor.constraint(equalTo: leftArmorImageView.centerXAnchor),
            leftArmorLabel.centerYAnchor.constraint(equalTo: leftArmorImageView.centerYAnchor),
            
            // middleArmorLabel
            middleArmorLabel.centerXAnchor.constraint(equalTo: middleArmorImageView.centerXAnchor),
            middleArmorLabel.centerYAnchor.constraint(equalTo: middleArmorImageView.centerYAnchor),
            
            // rightArmorLabel
            rightArmorLabel.centerXAnchor.constraint(equalTo: rightArmorImageView.centerXAnchor),
            rightArmorLabel.centerYAnchor.constraint(equalTo: rightArmorImageView.centerYAnchor),
            
            // bottomArmorLabel
            bottomArmorLabel.centerXAnchor.constraint(equalTo: bottomArmorImageView.centerXAnchor),
            bottomArmorLabel.centerYAnchor.constraint(equalTo: bottomArmorImageView.centerYAnchor),
        ])
    }
}
