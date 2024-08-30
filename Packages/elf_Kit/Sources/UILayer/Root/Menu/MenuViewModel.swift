//
//  MenuViewModel.swift
//  
//
//  Created by Vitalii Lytvynov on 17.05.24.
//

import Foundation

public final class MenuViewModel {
    
    private let rootViewStateDelegate: AnyViewStateDelegate<RootViewState>
    
    public init(rootViewStateDelegate: AnyViewStateDelegate<RootViewState>) {
        self.rootViewStateDelegate = rootViewStateDelegate
    }
    
    // MARK: Actions
    
    @objc
    public func fightButtonAction() {
        print("Fight button pressed")
        self.rootViewStateDelegate.setViewState(.battle)
    }
}
