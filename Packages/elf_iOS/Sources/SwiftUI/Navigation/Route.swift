//
//  Route.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

// MARK: - Route Protocol
public protocol Route: Hashable {
    associatedtype Destination: View
    @ViewBuilder func view() -> Destination
}
