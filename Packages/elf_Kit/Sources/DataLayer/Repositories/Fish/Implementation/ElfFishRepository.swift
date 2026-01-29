//
//  ElfFishRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation
import os.log

public final class ElfFishRepository: FishRepository {

    // MARK: - Properties

    private static let log = OSLog(subsystem: "com.elfy.kit", category: "FishRepository")
    private let base: BaseCollectionRepository<FishData>

    // MARK: - Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        self.base = BaseCollectionRepository(
            loadData: dataLoader.loadFishData,
            log: Self.log,
            resourceName: "Fish.json"
        )
    }

    // MARK: - FishRepository

    public func getFish(id: FishID) -> Fish? {
        base.getItem(id: id)
    }

    public func getAllFish() -> [Fish] {
        base.getAllItems()
    }

}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `_fishData` is a value type, `base` contains immutable dictionaries.
extension ElfFishRepository: @unchecked Sendable {}
