//
//  AnyViewStateDelegate.swift
//
//
//  Created by Vitalii Lytvynov on 30.08.24.
//

public protocol ViewStateDelegate {
    associatedtype viewStateType
    func setViewState(_ state: viewStateType)
}

public final class AnyViewStateDelegate<T>: ViewStateDelegate {
    private let _setViewState: (T) -> Void
    
    public init<Delegate: ViewStateDelegate>(_ delegate: Delegate) where Delegate.viewStateType == T {
        self._setViewState = delegate.setViewState
    }
    
    public func setViewState(_ state: T) {
        _setViewState(state)
    }
}
