//
//  Item.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import Foundation

public protocol Item: Decodable {
    var id: UUID { get }
    var title: String { get }
    var tier: Int16 { get }
}
