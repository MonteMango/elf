//
//  CalendarService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var calendarService: any CalendarService {
        get { self[CalendarServiceKey.self] }
        set { self[CalendarServiceKey.self] = newValue }
    }
}

private enum CalendarServiceKey: DependencyKey {
    static var liveValue: any CalendarService { DefaultCalendarService() }
}
