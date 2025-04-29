//
//  ElfLabel.swift
//
//
//  Created by Vitalii Lytvynov on 18.05.24.
//

import UIKit

public final class ElfLabel: UILabel {
    
    // MARK: Properties
    
    private let labelStyle: ElfLabelStyle
    
    // MARK: Initializer
    
    public init(labelStyle: ElfLabelStyle, text: String? = nil) {
        self.labelStyle = labelStyle
        super.init(frame: .zero)
        configureStyle(text: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureStyle(text: String? = nil) {
        self.textAlignment = labelStyle.textAlignment
        self.font = labelStyle.font
        self.numberOfLines = labelStyle.numberOfLines
        self.lineBreakMode = labelStyle.lineBreakMode
        self.adjustsFontSizeToFitWidth = labelStyle.adjustsFontSizeToFitWidth
        self.text = text
    }
}
