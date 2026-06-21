//
//  PointStatusFormatter+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var pointStatusFormatter: any PointStatusFormatter {
        get { self[PointStatusFormatterKey.self] }
        set { self[PointStatusFormatterKey.self] = newValue }
    }
}

private enum PointStatusFormatterKey: DependencyKey {
    static var liveValue: any PointStatusFormatter { DefaultPointStatusFormatter() }
}
