//
//  ItemsRepository.swift
//
//
//  Created by Vitalii Lytvynov on 24.09.24.
//

import Foundation

public protocol ItemsRepository: Sendable {

    var heroItems: HeroItems { get }

    func getHeroItem(_ id: UUID) -> Item?
}
