//
//  ShieldSpecialAbility.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 25.04.25.
//

public enum ShieldSpecialAbility: Decodable {
    case antiCrit(probability: Float)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case probability
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let probability = try container.decode(Float.self, forKey: .probability)
        
        switch type {
        case "antiCrit":
            self = .antiCrit(probability: probability)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type \(type)")
        }
    }
}
