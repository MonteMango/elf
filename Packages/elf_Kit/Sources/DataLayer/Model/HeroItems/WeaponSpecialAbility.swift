//
//  SpecialAbility.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.04.25.
//

public enum WeaponSpecialAbility: Decodable {
    case passThroughBlock(probability: Float)
    case antiDodge(probability: Float)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case probability
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let probability = try container.decode(Float.self, forKey: .probability)
        
        switch type {
        case "passThroughBlock":
            self = .passThroughBlock(probability: probability)
        case "antiDodge":
            self = .antiDodge(probability: probability)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type \(type)")
        }
    }
}
