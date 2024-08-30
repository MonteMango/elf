//
//  RootViewModel.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import Combine

public final class RootViewModel {
    
    @Published public private(set) var viewState: RootViewState = .menu
    
    public init() { }
}

extension RootViewModel: ViewStateDelegate {
    public typealias StateType = RootViewState
    
    public func setViewState(_ state: RootViewState) {
        viewState = state
    }
}
