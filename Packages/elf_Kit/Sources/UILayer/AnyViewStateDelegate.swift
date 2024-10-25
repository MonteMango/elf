//
//  AnyViewStateDelegate.swift
//
//
//  Created by Vitalii Lytvynov on 30.08.24.
//

public protocol ViewStateDelegate {
    associatedtype ViewStateType
    
    func setViewState(_ state: ViewStateType)
}

public final class AnyViewStateDelegate<ViewState>: ViewStateDelegate {
    private let _setViewState: (ViewState) -> Void
    
    public init<Delegate: ViewStateDelegate>(_ delegate: Delegate) where Delegate.ViewStateType == ViewState {
        self._setViewState = delegate.setViewState
    }
    
    public func setViewState(_ state: ViewState) {
        _setViewState(state)
    }
}
