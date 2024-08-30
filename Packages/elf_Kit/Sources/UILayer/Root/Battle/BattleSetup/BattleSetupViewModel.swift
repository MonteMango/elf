//
//  BattleSetupViewModel.swift
//
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Foundation

public final class BattleSetupViewModel {
    
    private let rootViewStateDelegate: AnyViewStateDelegate<RootViewState>
    
    public init(rootViewStateDelegate: AnyViewStateDelegate<RootViewState>) {
        self.rootViewStateDelegate = rootViewStateDelegate
    }
    
    @objc
    public func closeButtonAction() {
        rootViewStateDelegate.setViewState(.menu)
    }
}
