//
//  RootViewModel.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import Combine

public final class RootViewModel {
    
    // MARK: Properties
    
    private let itemsRepository: ItemsRepository
    
    @Published public private(set) var viewState: RootViewState = .menu
    
    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository
    }
    
    public func loadHeroItems() {
        Task(priority: .background) {
            do {
                try await itemsRepository.loadHeroItems()
            } catch {
                print("Failed to load hero items: \(error.localizedDescription)")
            }
        }
    }
}

extension RootViewModel: ViewStateDelegate {
    
    public typealias ViewStateType = RootViewState
    
    public func setViewState(_ state: RootViewState) {
        viewState = state
    }
}
