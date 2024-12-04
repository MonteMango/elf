//
//  HeroItemCollectionViewCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 19.10.24.
//

import elf_UIKit
import UIKit

internal final class HeroItemCollectionViewCell: NiblessCollectionViewCell {
    
    // MARK: UI Controls
    
    internal lazy var itemImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    internal lazy var itemTitleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .itemTitle, text: "Item title")
        return label
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
        contentView.backgroundColor = UIColor.gray
        layer.borderWidth = 0.0
        layer.borderColor = UIColor.clear.cgColor
    }
    
    private func constructHierarchy() {
        contentView.addSubview(itemImageView)
        contentView.addSubview(itemTitleLabel)
    }
    
    private func activateConstraints() {
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        itemTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // itemImageView
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // itemTitleLabel
            itemTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            itemTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor)
        ])
    }
    
    private func configureControls() {
        
    }
}
