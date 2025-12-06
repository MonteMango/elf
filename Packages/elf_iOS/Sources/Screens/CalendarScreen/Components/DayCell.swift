//
//  DayCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import SwiftUI

/// A single day cell for calendar display
struct DayCell: View {
    let day: GameDay
    let isCurrentDay: Bool

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 4)
                .fill(day.dayType.backgroundColor)

            // Day number or symbol
            VStack(spacing: 2) {
                Text("day")
                    .font(.system(size: 10))
                    .foregroundStyle(.black.opacity(0.6))

                Text(displayText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            if isCurrentDay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.orange, lineWidth: 3)
            }
        }
        .scaleEffect(isCurrentDay ? 1.1 : 1.0)
        .shadow(
            color: isCurrentDay ? .black.opacity(0.3) : .clear,
            radius: isCurrentDay ? 8 : 0,
            x: 0,
            y: isCurrentDay ? 4 : 0
        )
    }

    private var displayText: String {
        day.dayType.displaySymbol ?? "\(day.dayNumber)"
    }
}

#Preview("Current Day") {
    DayCell(
        day: GameDay(dayNumber: 3, dayType: .normal),
        isCurrentDay: true
    )
    .frame(width: 80, height: 80)
    .padding()
}

#Preview("Day Types") {
    HStack(spacing: 10) {
        DayCell(day: GameDay(dayNumber: 1, dayType: .normal), isCurrentDay: false)
        DayCell(day: GameDay(dayNumber: 4, dayType: .dungeon), isCurrentDay: false)
        DayCell(day: GameDay(dayNumber: 8, dayType: .randomEvent), isCurrentDay: false)
        DayCell(day: GameDay(dayNumber: 16, dayType: .houseWar), isCurrentDay: false)
        DayCell(day: GameDay(dayNumber: 32, dayType: .unknown), isCurrentDay: false)
    }
    .frame(height: 60)
    .padding()
}
