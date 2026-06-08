//
//  AttributeRandomizer.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

/// Picks a random combat attribute kind, used by `AttributeService` to roll
/// the +4/level random pool. Returns the typed enum (no stringly-typed API).
public protocol AttributeRandomizer: Sendable {
    func nextAttribute() -> RandomAttributeKind
}
