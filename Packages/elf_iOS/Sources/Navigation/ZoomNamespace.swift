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
    internal var farmZoomNamespace: Namespace.ID? {
        get { self[FarmZoomNamespaceKey.self] }
        set { self[FarmZoomNamespaceKey.self] = newValue }
    }

    internal var questZoomNamespace: Namespace.ID? {
        get { self[QuestZoomNamespaceKey.self] }
        set { self[QuestZoomNamespaceKey.self] = newValue }
    }
}

// MARK: - Zoom Transition Modifiers

/// Applies matchedTransitionSource if namespace is available
internal struct ZoomSourceModifier: ViewModifier {
    internal let id: String
    internal let namespace: Namespace.ID?

    internal func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// Applies navigationTransition zoom if namespace is available
internal struct ZoomTransitionModifier: ViewModifier {
    internal let sourceID: String
    internal let namespace: Namespace.ID?

    internal func body(content: Content) -> some View {
        if let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content.navigationTransition(.automatic)
        }
    }
}
