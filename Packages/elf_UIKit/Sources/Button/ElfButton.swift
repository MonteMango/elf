//
//  ElfButton.swift
//
//
//  Created by Vitalii Lytvynov on 17.05.24.
//

import UIKit

public final class ElfButton: UIControl {
    
    // MARK: Properties
    
    private let BUTTON_ANIMATION_DURATION: TimeInterval = 0.2
    
    private let buttonStyle: ElfButtonStyle
    
    // MARK: Initializer
    
    public init(buttonStyle: ElfButtonStyle, centerText: String? = nil) {
        self.buttonStyle = buttonStyle
        super.init(frame: .zero)
        configureStyle(centerText: centerText)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureStyle(centerText: String? = nil, centerImage: UIImage? = nil) {
        
        self.backgroundColor = buttonStyle.backgroundColor
        self.tintColor = buttonStyle.tintColor
        self.layer.borderWidth = buttonStyle.borderWidth
        self.layer.borderColor = buttonStyle.borderColor?.cgColor
        self.layer.cornerRadius = buttonStyle.cornerRadius ?? 0.0
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: buttonStyle.width),
            heightAnchor.constraint(equalToConstant: buttonStyle.height)
        ])
        
        switch buttonStyle {
        case .menu:
            addCenterLabel(labelStyle: .menuButtonTitle, text: centerText)
        case .close:
            addCenterImageView(centerImage)
        case .selectFightStyle:
            addCenterImageView(centerImage)
        }
    }
    
    private func addCenterLabel(labelStyle: ElfLabelStyle, text: String? = nil) {
        let centerLabel = ElfLabel(labelStyle: labelStyle, text: text)
        addSubview(centerLabel)
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func addCenterImageView(_ image: UIImage?) {
        let imageView = UIImageView()
        imageView.image = image
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    // MARK: State properties
    
    public override var isSelected: Bool {
        didSet {
            updateAppearance(for: isSelected ? .selected : .normal)
        }
    }
    
    public override var isHighlighted: Bool {
        didSet {
            if isSelected {
                updateAppearance(for: .selected)
            } else {
                updateAppearance(for: isHighlighted ? .highlighted : .normal)
            }
        }
    }

    public override var isEnabled: Bool {
        didSet {
            updateAppearance(for: isEnabled ? .normal : .disabled)
        }
    }
    
    private func updateAppearance(for state: UIControl.State) {
        UIView.animate(withDuration: BUTTON_ANIMATION_DURATION) {
            switch state {
            case .selected:
                self.backgroundColor = self.buttonStyle.selectedBackgroundColor
                self.tintColor = self.buttonStyle.selectedTintColor
                self.layer.borderColor = self.buttonStyle.selectedBorderColor?.cgColor
                self.layer.borderWidth = self.buttonStyle.selectedBorderWidth
            case .highlighted:
                self.backgroundColor = self.buttonStyle.highlightedBackgroundColor
                self.tintColor = self.buttonStyle.highlightedTintColor
            case .disabled:
                self.alpha = 0.4
            default:
                self.backgroundColor = self.buttonStyle.backgroundColor
                self.tintColor = self.buttonStyle.tintColor
                self.layer.borderColor = self.buttonStyle.borderColor?.cgColor
                self.layer.borderWidth = self.buttonStyle.borderWidth
                self.alpha = 1.0
            }
        }
    }
}
