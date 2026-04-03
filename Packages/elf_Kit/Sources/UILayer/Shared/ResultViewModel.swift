//
//  ResultViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Generic ViewModel for displaying results (fishing, foraging, battle, etc.)
/// Simply holds a result value for presentation.
@MainActor
@Observable
public final class ResultViewModel<T: Sendable> {

    // MARK: - Properties

    public let result: T

    // MARK: - Initialization

    public init(result: T) {
        self.result = result
    }
}
