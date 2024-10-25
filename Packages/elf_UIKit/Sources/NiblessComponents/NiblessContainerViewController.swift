//
//  NiblessContainerViewController.swift
//
//
//  Created by Vitalii Lytvynov on 04.05.24.
//

import UIKit

open class NiblessContainerViewController: NiblessViewController {
    
    let ANIMATION_DURATION: TimeInterval = 0.3
    
    public func addViewController(_ viewController: NiblessViewController) {
        addChild(viewController)
        viewController.didMove(toParent: self)
    }
    
    public func removeViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    public func showViewController(_ viewController: NiblessViewController) {
        guard let view = viewController.view else { return }
        view.removeFromSuperview()
        view.alpha = 0.0
        self.view.addSubview(view)
        
        configureViewControllerLayout(viewController)
        
        UIView.animate(withDuration: ANIMATION_DURATION) {
            view.alpha = 1.0
        }
    }
    
    public func hideViewController(_ viewController: UIViewController) {
        guard let view = viewController.view else { return }
        UIView.animate(withDuration: ANIMATION_DURATION, animations: {
            view.alpha = 0.0
        }) { (_) in
            view.removeFromSuperview()
        }
    }
    
    public func showAlertViewController(_ viewController: NiblessViewController) {
        guard let view = viewController.view else { return }
        view.removeFromSuperview()
        self.view.addSubview(view)
        
        configureAlertViewControllerLayout(viewController)
    }
    
    open func configureViewControllerLayout(_ viewController: NiblessViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: -27),
            viewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 27),
            viewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    open func configureAlertViewControllerLayout(_ viewController: NiblessViewController) {
        let rootViewController = getRootViewController()
        let topPadding = rootViewController?.view.safeAreaInsets.top ?? 0.0
        let bottomPadding = rootViewController?.view.safeAreaInsets.bottom ?? 0.0
        let leftPadding = rootViewController?.view.safeAreaInsets.left ?? 0.0
        let rightPadding = rootViewController?.view.safeAreaInsets.right ?? 0.0
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: -topPadding),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -leftPadding),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: rightPadding),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomPadding)
        ])
    }
}

internal extension UIViewController {
    func getRootViewController() -> UIViewController? {
        var currentViewController: UIViewController? = self
        
        while let parent = currentViewController?.parent {
            currentViewController = parent
        }
        
        return currentViewController
    }
}
