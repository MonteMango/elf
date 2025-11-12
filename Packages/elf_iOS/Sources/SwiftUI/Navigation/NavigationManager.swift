//
//  NavigationManager.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

internal protocol NavigationManager {
    associatedtype R: Route
    
    func push(_ route: R)
    func pop()
    func popToRoot()
    func popTo(index: Int)
    func replace(with route: R)
    func replaceStack(with routes: [R])
}
