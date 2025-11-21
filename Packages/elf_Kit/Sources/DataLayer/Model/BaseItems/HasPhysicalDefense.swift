//
//  HasPhysicalDefense.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

public protocol HasPhysicalDefense {
    var physicalDefensePoint: Int16 { get }
    var protectParts: [BodyPart] { get }
}
