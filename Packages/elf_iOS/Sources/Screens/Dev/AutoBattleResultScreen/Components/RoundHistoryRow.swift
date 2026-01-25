//
//  RoundHistoryRow.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import elf_Kit
import SwiftUI

internal struct RoundHistoryRow: View {
    let round: AutoBattleRoundResult

    @State private var isExpanded: Bool = false

    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerButton
            if isExpanded {
                detailsView
            }
        }
    }

    // MARK: - Header Button

    private var headerButton: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack {
                Text("Round \(round.roundNumber)")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                hpChanges

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var hpChanges: some View {
        HStack(spacing: 16) {
            Text("Bot1: \(round.bot1StartHP) → \(round.bot1EndHP)")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Text("Bot2: \(round.bot2StartHP) → \(round.bot2EndHP)")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    // MARK: - Details View

    private var detailsView: some View {
        HStack(spacing: 20) {
            botDetails(
                name: "Bot1",
                attackPoints: round.bot1AttackPoints,
                defensePoints: round.bot1DefensePoints,
                damageDealt: round.bot1DamageDealt,
                damageTaken: round.bot1DamageTaken
            )

            Spacer()

            botDetails(
                name: "Bot2",
                attackPoints: round.bot2AttackPoints,
                defensePoints: round.bot2DefensePoints,
                damageDealt: round.bot2DamageDealt,
                damageTaken: round.bot2DamageTaken
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }

    private func botDetails(
        name: String,
        attackPoints: [BodyPart],
        defensePoints: [BodyPart],
        damageDealt: Int,
        damageTaken: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .bold()
                .foregroundStyle(.white)

            detailText("Attack", attackPoints.map { $0.rawValue }.joined(separator: ", "))
            detailText("Defense", defensePoints.map { $0.rawValue }.joined(separator: ", "))
            detailText("Damage Dealt", "\(damageDealt)")
            detailText("Damage Taken", "\(damageTaken)")
        }
    }

    private func detailText(_ label: String, _ value: String) -> some View {
        Text("\(label): \(value)")
            .font(.caption)
            .foregroundStyle(.gray)
    }
}
