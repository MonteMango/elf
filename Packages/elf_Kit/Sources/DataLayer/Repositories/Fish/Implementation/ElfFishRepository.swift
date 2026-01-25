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
    private let _fishData: FishData
    private let fishLookup: [UUID: Fish]
    private let effectLookup: [String: EffectDefinition]

    // MARK: - Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        // Load data synchronously from bundle
        let data: Data
        do {
            data = try dataLoader.loadFishData()
        } catch {
            os_log("Could not load Fish.json, using empty data: %{public}@", log: Self.log, type: .error, error.localizedDescription)
            data = Self.createEmptyFishJSON()
        }

        // Decode JSON
        let fishData: FishData
        do {
            fishData = try JSONDecoder().decode(FishData.self, from: data)
        } catch {
            os_log("Failed to decode fish data, using empty fallback: %{public}@", log: Self.log, type: .error, error.localizedDescription)
            fishData = FishData(version: "1.0-empty", effects: [], areas: [:], fish: [])
        }

        self._fishData = fishData

        // Build fish lookup cache
        var fLookup: [UUID: Fish] = [:]
        for fish in fishData.fish {
            fLookup[fish.id] = fish
        }
        self.fishLookup = fLookup

        // Build effect lookup cache (keyed by effectType)
        var eLookup: [String: EffectDefinition] = [:]
        for effect in fishData.effects {
            eLookup[effect.effectType] = effect
        }
        self.effectLookup = eLookup
    }

    // MARK: - FishRepository

    public var fishData: FishData {
        return _fishData
    }

    public func getFish(id: UUID) -> Fish? {
        return fishLookup[id]
    }

    public func getAllFish() -> [Fish] {
        return _fishData.fish
    }

    public func getFishForArea(_ areaId: String) -> [Fish] {
        guard let area = _fishData.areas[areaId] else {
            return []
        }

        return area.fish.compactMap { fishId in
            fishLookup[fishId]
        }
    }

    public func getEffectDefinition(_ id: String) -> EffectDefinition? {
        return effectLookup[id]
    }

    // MARK: - Private Helpers

    private static func createEmptyFishJSON() -> Data {
        let emptyJSON = """
        {
            "version": "1.0-empty",
            "effects": [],
            "areas": {},
            "fish": []
        }
        """
        return Data(emptyJSON.utf8)
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `_fishData` is a value type, lookups are immutable dictionaries of value types.
extension ElfFishRepository: @unchecked Sendable {}
