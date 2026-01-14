//
//  CalendarSection.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

public struct CalendarSection: View {
    let currentDay: CalendarDayData
    let upcomingDays: [CalendarDayData]
    var onTap: (() -> Void)?

    private let daySize: CGFloat = 45
    private let layerOffset: CGFloat = 22.5  // daySize / 2
    private let borderWidth: CGFloat = 3

    public init(
        currentDay: CalendarDayData,
        upcomingDays: [CalendarDayData],
        onTap: (() -> Void)? = nil
    ) {
        self.currentDay = currentDay
        self.upcomingDays = upcomingDays
        self.onTap = onTap
    }

    public var body: some View {
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
    private func dayCell(day: CalendarDayData, style: DayStyle) -> some View {
        ZStack {
            // Background with shadow (only for current style)
            Rectangle()
                .fill(day.backgroundColor)
                .frame(width: daySize, height: daySize)
                .shadow(
                    color: style == .current ? .black.opacity(0.3) : .clear,
                    radius: 4, x: 2, y: 2
                )

            // Border (strokeBorder keeps border inside frame)
            Rectangle()
                .strokeBorder(borderColor(for: style), lineWidth: style == .current ? borderWidth : 1)
                .frame(width: daySize, height: daySize)

            // Content
            VStack(spacing: 0) {
                if style == .current {
                    Text("day")
                        .font(.system(size: ElfFonts.Size.small, weight: .regular))
                        .foregroundColor(ElfColors.Text.secondary)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: style == .current ? ElfFonts.Size.title2 : ElfFonts.Size.headline, weight: .bold))
                    .foregroundColor(ElfColors.Text.primary)
            }
        }
    }

    private func borderColor(for style: DayStyle) -> Color {
        switch style {
        case .current:
            return ElfColors.Calendar.currentDayBorder
        case .upcoming, .future:
            return ElfColors.Calendar.upcomingDayBorder
        }
    }
}

#Preview {
    CalendarSection(
        currentDay: CalendarDayData(
            dayNumber: 1,
            backgroundColor: ElfColors.Calendar.normalDay
        ),
        upcomingDays: [
            CalendarDayData(dayNumber: 2, backgroundColor: ElfColors.Calendar.dungeonDay),
            CalendarDayData(dayNumber: 3, backgroundColor: ElfColors.Calendar.eventDay),
            CalendarDayData(dayNumber: 4, backgroundColor: ElfColors.Calendar.unknownDay)
        ],
        onTap: { print("Calendar tapped") }
    )
    .padding()
    .background { Color.yellow }
    .preferredColorScheme(.light)
}
