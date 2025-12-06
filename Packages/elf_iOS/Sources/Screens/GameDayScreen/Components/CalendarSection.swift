//
//  CalendarSection.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import SwiftUI

struct CalendarSection: View {
    let currentDay: GameDay
    let upcomingDays: [GameDay]
    var onTap: (() -> Void)?

    private let daySize: CGFloat = 45
    private let layerOffset: CGFloat = 22.5  // daySize / 2
    private let borderWidth: CGFloat = 3

    var body: some View {
        ZStack(alignment: .leading) {
            // Background days (furthest back first)
            ForEach(Array(upcomingDays.enumerated().reversed()), id: \.element.id) { index, day in
                let offsetIndex = index + 1
                let isLastDay = index == upcomingDays.count - 1

                dayCell(day: day, style: isLastDay ? .future : .upcoming)
                    .offset(x: layerOffset * CGFloat(offsetIndex))
            }

            // Current day (front, no offset)
            dayCell(day: currentDay, style: .current)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
        }
        .frame(width: totalWidth, height: daySize, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var totalWidth: CGFloat {
        // daySize + offset for each upcoming day
        daySize + (layerOffset * CGFloat(upcomingDays.count))
    }

    private enum DayStyle {
        case current
        case upcoming
        case future
    }

    @ViewBuilder
    private func dayCell(day: GameDay, style: DayStyle) -> some View {
        ZStack {
            // Background
            Rectangle()
                .fill(backgroundColor(for: style))
                .frame(width: daySize, height: daySize)

            // Border
            Rectangle()
                .stroke(borderColor(for: style), lineWidth: style == .current ? borderWidth : 1)
                .frame(width: daySize, height: daySize)

            // Content
            VStack(spacing: 0) {
                if style == .current {
                    Text("day")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.gray)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: style == .current ? 24 : 18, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }

    private func backgroundColor(for style: DayStyle) -> Color {
        switch style {
        case .current:
            return .white
        case .upcoming:
            return Color(white: 0.9)
        case .future:
            return Color(red: 0.9, green: 0.85, blue: 0.95)  // light purple
        }
    }

    private func borderColor(for style: DayStyle) -> Color {
        switch style {
        case .current, .upcoming:
            return .orange
        case .future:
            return Color(white: 0.8)
        }
    }
}

#Preview {
    CalendarSection(
        currentDay: GameDay(dayNumber: 1, dayType: .normal),
        upcomingDays: [
            GameDay(dayNumber: 2, dayType: .dungeon),
            GameDay(dayNumber: 3, dayType: .normal),
            GameDay(dayNumber: 4, dayType: .houseWar)
        ],
        onTap: { print("Calendar tapped") }
    )
    .padding()
    .background { Color.yellow }
    .preferredColorScheme(.light)
}
