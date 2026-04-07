//
//  ImageDownsampler.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import ImageIO
import UIKit

/// Downsamples images to a target size, reducing memory footprint and GPU work.
///
/// Three loading paths ordered by efficiency:
/// - `downsample(url:...)` — best: never loads full-res into memory
/// - `downsample(data:...)` — good: works with any Data source
/// - `downsample(assetNamed:...)` — for Asset Catalog images; uses UIGraphicsImageRenderer
///    to avoid the JPEG re-encode round-trip.
///
/// All methods are `async` and `nonisolated`. Caller is responsible for ensuring
/// they are invoked from a background context (e.g. SwiftUI `.task {}`, which
/// runs its `@Sendable` closure on the cooperative pool). A debug `assert` verifies
/// background execution.
public struct ImageDownsampler: Sendable {

    public init() {}

    // MARK: - From File URL (optimal)

    /// Downsample directly from a file URL.
    /// Never decodes full-resolution image into memory — CGImageSource reads only
    /// the pixels needed for the target size.
    public func downsample(url: URL, targetSize: CGSize, scale: CGFloat) async -> UIImage? {
        if Task.isCancelled { return nil }
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
            return nil
        }
        return Self.createThumbnail(from: source, targetSize: targetSize, scale: scale)
    }

    // MARK: - From Data

    /// Downsample from raw image data (JPEG, PNG, etc.).
    /// Does not cache the full-resolution image.
    public func downsample(data: Data, targetSize: CGSize, scale: CGFloat) async -> UIImage? {
        if Task.isCancelled { return nil }
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        return Self.createThumbnail(from: source, targetSize: targetSize, scale: scale)
    }

    // MARK: - From Asset Catalog

    /// Downsample an image from the Asset Catalog by name.
    ///
    /// Asset Catalog images are compiled into Assets.car and have no file URL.
    /// This method loads via UIImage(named:) and redraws into a smaller bitmap
    /// context using UIGraphicsImageRenderer — avoiding the expensive JPEG
    /// encode/decode round-trip that CGImageSource would require.
    ///
    /// For best performance, prefer placing large images in the Resources directory
    /// and using `downsample(url:...)` instead.
    public func downsample(assetNamed name: String, targetSize: CGSize, scale: CGFloat) async -> UIImage? {
        if Task.isCancelled { return nil }
        guard let image = UIImage(named: name) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // MARK: - Private

    private static func createThumbnail(from source: CGImageSource, targetSize: CGSize, scale: CGFloat) -> UIImage? {
        let maxPixel = max(targetSize.width, targetSize.height) * scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
