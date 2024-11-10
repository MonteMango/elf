//
//  NiblessAlertView.swift
//  elf_UIKit
//
//  Created by Vitalii Lytvynov on 26.10.24.
//

import UIKit

open class NiblessAlertView: NiblessView {
    
    public var backgroundViewBottomConstraint: NSLayoutConstraint?
    public var backgroundViewCenterYConstraint: NSLayoutConstraint?
    
    // MARK: UI Controls
    
    public lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.borderWidth = 8.0
        view.layer.borderColor = UIColor.tertiarySystemGroupedBackground.cgColor
        return view
    }()
    
    public lazy var closeButton: ElfButton = {
        let button = ElfButton(buttonStyle: .close)
        return button
    }()
    
    // MARK: Initializer
    
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
    }
    
    open func styleView() {
        backgroundColor = UIColor.systemGreen.withAlphaComponent(0.0)
    }
    
    open func constructHierarchy() {
        addSubview(backgroundView)
        addSubview(closeButton)
    }
    
    open func activateConstraints() {
        backgroundViewBottomConstraint = backgroundView.centerYAnchor.constraint(equalTo: self.bottomAnchor, constant: 180)
        backgroundViewCenterYConstraint = backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor)
        guard let backgroundViewBottomConstraint = self.backgroundViewBottomConstraint else { return }
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            // backgroundView
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: 740),
            backgroundView.heightAnchor.constraint(equalToConstant: 300),
            backgroundViewBottomConstraint,
            
            // closeButton
            closeButton.centerXAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: backgroundView.topAnchor),
        ])
    }
}
