//
//  EmptyHeroItemCollectionViewCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 21.10.24.
//

import elf_UIKit
import UIKit

internal final class EmptyHeroItemCollectionViewCell: NiblessCollectionViewCell {
    
    // MARK: UI Controls
    
    internal lazy var itemImageView: UIImageView = {
        let view = UIImageView()
        return view
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
    }
    
    private func activateConstraints() {
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // itemImageView
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func configureControls() {
        
    }
}
