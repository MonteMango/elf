//
//  Battle.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

public final class Battle {
    public let leftTeam: [HeroConfiguration]
    public let rightTeam: [HeroConfiguration]

    public init(leftTeam: [HeroConfiguration], rightTeam: [HeroConfiguration]) {
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
    }
}
