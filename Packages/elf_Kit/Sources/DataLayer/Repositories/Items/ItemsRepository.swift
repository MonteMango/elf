//
//  ItemsRepository.swift
//
//
//  Created by Vitalii Lytvynov on 24.09.24.
//

import Combine

public protocol ItemsRepository {
    
    var heroItems: HeroItems? { get }
    var heroItemsPublisher: Published<HeroItems?>.Publisher { get }
    
    func loadHeroItems() async throws
}
