//
//  FishingResultViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

@Observable
@MainActor
public final class FishingResultViewModel {

    // MARK: - Properties

    public let result: FishingResult

    // MARK: - Initialization

    public init(result: FishingResult) {
        self.result = result
    }
}
