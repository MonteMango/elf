//
//  AttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Foundation

/// Composite protocol that combines all attribute-related services
///
/// This protocol aggregates focused interfaces for:
/// - Fight style attributes
/// - Random level attributes
/// - Item attributes
public protocol AttributeService: FightStyleAttributeProvider,
                                  RandomAttributeGenerator,
                                  ItemAttributeAggregator {}
