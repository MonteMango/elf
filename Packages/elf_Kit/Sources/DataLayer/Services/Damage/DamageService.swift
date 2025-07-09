//
//  DamageService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public protocol DamageService {
    func getMinMaxStrengthDamage(_ strengthAttribute: Int16) async -> (minDmg: Int16, maxDmg: Int16)?
}
