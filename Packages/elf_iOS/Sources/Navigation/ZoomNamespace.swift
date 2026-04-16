//
//  ZoomNamespace.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

// MARK: - Environment Keys

private struct FarmZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

private struct QuestZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var farmZoomNamespace: Namespace.ID? {
        get { self[FarmZoomNamespaceKey.self] }
        set { self[FarmZoomNamespaceKey.self] = newValue }
    }

    var questZoomNamespace: Namespace.ID? {
        get { self[QuestZoomNamespaceKey.self] }
        set { self[QuestZoomNamespaceKey.self] = newValue }
    }
}

// MARK: - Zoom Transition Modifiers

/// Applies matchedTransitionSource if namespace is available
struct ZoomSourceModifier: ViewModifier {
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
struct ZoomTransitionModifier: ViewModifier {
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
