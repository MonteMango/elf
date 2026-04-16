//
//  QuestZoomNamespace.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

// MARK: - QuestZoomNamespace Environment Key

private struct QuestZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var questZoomNamespace: Namespace.ID? {
        get { self[QuestZoomNamespaceKey.self] }
        set { self[QuestZoomNamespaceKey.self] = newValue }
    }
}

// MARK: - Zoom Transition Modifiers

/// Applies matchedTransitionSource if namespace is available
struct QuestZoomSourceModifier: ViewModifier {
    let id: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// Applies navigationTransition zoom if namespace is available
struct QuestZoomTransitionModifier: ViewModifier {
    let sourceID: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content.navigationTransition(.automatic)
        }
    }
}
