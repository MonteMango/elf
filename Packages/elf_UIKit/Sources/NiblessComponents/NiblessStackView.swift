//
//  NiblessStackView.swift
//
//
//  Created by Vitalii Lytvynov on 08.09.24.
//

import UIKit

open class NiblessStackView: UIStackView {
    
    // MARK: - Methods
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(arrangedSubviews views: [UIView]) {
        super.init(frame: .zero)
        views.forEach { self.addArrangedSubview($0) }
    }

    @available(*, unavailable,
                message: "Loading this view from a nib is unsupported in favor of initializer dependency injection."
    )
    public required init(coder: NSCoder) {
        fatalError("Loading this view from a nib is unsupported in favor of initializer dependency injection.")
    }
}
