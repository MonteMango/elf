//
//  NiblessCollectionViewCell.swift
//  elf_UIKit
//
//  Created by Vitalii Lytvynov on 20.10.24.
//

import UIKit

open class NiblessCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Methods
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @available(*, unavailable,
                message: "Loading this cell from a nib is unsupported in favor of initializer dependency injection."
    )
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Loading this cell from a nib is unsupported in favor of initializer dependency injection.")
    }
    
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}
