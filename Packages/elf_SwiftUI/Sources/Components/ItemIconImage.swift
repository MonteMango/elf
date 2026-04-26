//
//  ItemIconImage.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI
import UIKit

/// Renders an equipment / inventory item icon.
///
/// Preferred form: pass a resolved `imageName` (asset catalog name) when the asset is
/// known to exist (or `nil` for the placeholder). Asset existence resolution belongs to
/// the data layer; this view stays declarative.
///
/// Convenience form: `init(uuid:size:)` probes the asset catalog using the
/// `uuid.uuidString.lowercased()` convention. Use this only when there is no place to
/// pre-resolve the name (no display DTO, no ViewModel). Each instantiation costs one
/// `UIImage(named:)` lookup.
public struct ItemIconImage: View {

    // MARK: - Properties

    let imageName: String?
    let size: CGFloat
    let placeholderScale: CGFloat
    let opacity: Double

    // MARK: - Init

    public init(
        imageName: String?,
        size: CGFloat,
        placeholderScale: CGFloat = 1.0,
        opacity: Double = 1.0
    ) {
        self.imageName = imageName
        self.size = size
        self.placeholderScale = placeholderScale
        self.opacity = opacity
    }

    /// Convenience initializer that resolves the asset name from a UUID by the
    /// `uuid.uuidString.lowercased()` convention and probes the asset catalog.
    /// Falls back to `nil` (placeholder) when no matching asset exists.
    public init(
        uuid: UUID,
        size: CGFloat,
        placeholderScale: CGFloat = 1.0,
        opacity: Double = 1.0
    ) {
        let candidate = uuid.uuidString.lowercased()
        self.imageName = UIImage(named: candidate) != nil ? candidate : nil
        self.size = size
        self.placeholderScale = placeholderScale
        self.opacity = opacity
    }

    // MARK: - Body

    public var body: some View {
        if let imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(opacity)
        } else {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * placeholderScale, height: size * placeholderScale)
                .foregroundStyle(.gray.opacity(0.5))
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ItemIconImage(imageName: nil, size: 40)
        ItemIconImage(imageName: "nonexistent-asset", size: 40)
        ItemIconImage(imageName: nil, size: 22)
    }
    .padding()
    .background(Color.white)
}
