//
//  ProgressionServiceTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//
//  Progression is derived from stored total XP (TDD: XP is the single source of truth,
//  level is always computed). These tests pin the character curve
//  [0, 100, 225, 375, 550, 750, 975, 1225, 1500, 1800, 2125, 2475] and the legacy
//  farming curve to concrete literals so a curve change is always a deliberate,
//  test-visible edit.
//

import Testing
@testable import elf_Kit

@Suite("Character progression", .tags(.progression))
struct CharacterProgressionTests {

    private let sut = ElfProgressionService()

    @Test("Level from total XP", arguments: [
        (0, 1), (99, 1),
        (100, 2), (224, 2),
        (225, 3), (374, 3),
        (549, 4), (550, 5),
        (1799, 9), (1800, 10),
        (2124, 10), (2125, 11), (2474, 11),
        (2475, 12), (9999, 12),
        (-100, 1)
    ])
    func level(totalExp: Int, expectedLevel: Int) {
        #expect(sut.calculateLevel(currentExp: totalExp) == expectedLevel)
    }

    @Test("expToNextLevel returns the next cumulative threshold, 0 at cap", arguments: [
        (0, 100), (100, 225), (225, 375),
        (2125, 2475), (2475, 0), (9999, 0)
    ])
    func expToNextLevel(totalExp: Int, expected: Int) {
        #expect(sut.expToNextLevel(currentExp: totalExp) == expected)
    }

    @Test("expProgress is the fraction within the current level, 1.0 at cap", arguments: [
        (0, 0.0), (50, 0.5), (100, 0.0), (300, 0.5), (2475, 1.0), (9999, 1.0)
    ])
    func expProgress(totalExp: Int, expected: Double) {
        #expect(abs(sut.expProgress(currentExp: totalExp) - expected) < 0.0001)
    }

    @Test("totalExp(forLevel:) returns the level's entry threshold, clamped", arguments: [
        (0, 0), (1, 0), (2, 100), (3, 225), (12, 2475), (13, 2475), (99, 2475)
    ])
    func totalExpForLevel(level: Int, expected: Int) {
        #expect(sut.totalExp(forLevel: level) == expected)
    }

    @Test("totalExp(forLevel:) round-trips through calculateLevel for every level")
    func totalExpRoundTrip() {
        for level in 1...12 {
            #expect(sut.calculateLevel(currentExp: sut.totalExp(forLevel: level)) == level)
        }
    }

    @Test("experienceTransition brackets a level-up correctly")
    func experienceTransition() {
        // 90 XP (L1) + 40 = 130 XP (L2, entry 100).
        let transition = sut.experienceTransition(previousExp: 90, gained: 40)
        #expect(transition.previousLevel == 1)
        #expect(transition.previousExp == 90)
        #expect(transition.previousExpToNext == 100)
        #expect(transition.newLevel == 2)
        #expect(transition.newExp == 130)
        #expect(transition.newExpToNext == 225)
    }
}

@Suite("Farming progression (legacy 50-XP mapping preserved)", .tags(.progression))
struct FarmingProgressionTests {

    private let sut = ElfProgressionService()

    @Test("Farming level from skill XP", arguments: [
        (0, 1), (99, 1),
        (100, 2), (149, 2),
        (150, 3),
        (549, 10), (550, 11),
        (600, 12), (9999, 12)
    ])
    func farmingLevel(exp: Int, expectedLevel: Int) {
        #expect(sut.farmingLevel(exp: exp) == expectedLevel)
    }

    @Test("Farming progress within the current level", arguments: [
        (0, 0.0), (50, 0.5), (100, 0.0), (125, 0.5), (600, 1.0)
    ])
    func farmingProgress(exp: Int, expected: Double) {
        #expect(abs(sut.farmingProgress(exp: exp) - expected) < 0.0001)
    }
}
