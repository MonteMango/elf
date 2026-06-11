//
//  GameDay+CalendarDayData.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI

extension GameDay {
    var calendarDayData: CalendarDayData {
        CalendarDayData(
            id: id.rawValue,
            dayNumber: dayNumber,
            backgroundColor: ElfColors.Calendar.dayColor(for: dayType.rawValue)
        )
    }
}
