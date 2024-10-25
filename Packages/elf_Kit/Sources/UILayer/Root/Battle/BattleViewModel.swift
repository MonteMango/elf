//
//  BattleViewModel.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Combine

public final class BattleViewModel {
    
    @Published public private(set) var viewState: BattleViewState = .setup
    
    public init() { }
}

extension BattleViewModel: ViewStateDelegate {
    
    public typealias ViewStateType = BattleViewState
    
    public func setViewState(_ state: BattleViewState) {
        viewState = state
    }
}
