//
//  NonEmptyArray.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// An array that is guaranteed to have at least one element.
///
/// Use this type when a function requires a non-empty collection,
/// making the function total (always returns a result) instead of
/// partial (may return nil for empty input).
///
/// ## Usage
/// ```swift
/// // Partial function — may return nil
/// func findBest(in videos: [Video]) -> Video?
///
/// // Total function — always returns a result
/// func findBest(in videos: NonEmptyArray<Video>) -> Video
/// ```
public struct NonEmptyArray<Element: Sendable>: Sendable {

    /// The first element (always exists)
    public let first: Element

    /// The remaining elements (may be empty)
    public let rest: [Element]

    /// The total number of elements
    public var count: Int { 1 + rest.count }

    /// Whether this collection has exactly one element
    public var isSingle: Bool { rest.isEmpty }

    /// The last element
    public var last: Element { rest.last ?? first }

    /// Creates a NonEmptyArray with a guaranteed first element
    /// - Parameters:
    ///   - first: The first element
    ///   - rest: Additional elements
    public init(_ first: Element, _ rest: Element...) {
        self.first = first
        self.rest = rest
    }

    /// Creates a NonEmptyArray with a guaranteed first element and array of rest
    /// - Parameters:
    ///   - first: The first element
    ///   - rest: Additional elements as array
    public init(first: Element, rest: [Element]) {
        self.first = first
        self.rest = rest
    }

    /// Attempts to create a NonEmptyArray from a regular array.
    /// Returns nil if the array is empty.
    /// - Parameter array: The source array
    public init?(_ array: [Element]) {
        guard let first = array.first else { return nil }
        self.first = first
        self.rest = Array(array.dropFirst())
    }

    /// Converts to a regular Swift array
    public var asArray: [Element] {
        [first] + rest
    }

    /// Returns true if all elements satisfy the predicate
    public func allSatisfy(_ predicate: (Element) -> Bool) -> Bool {
        predicate(first) && rest.allSatisfy(predicate)
    }

    /// Returns true if any element satisfies the predicate
    public func contains(where predicate: (Element) -> Bool) -> Bool {
        predicate(first) || rest.contains(where: predicate)
    }

    /// Maps each element using the transform function
    public func map<T: Sendable>(_ transform: (Element) -> T) -> NonEmptyArray<T> {
        NonEmptyArray<T>(first: transform(first), rest: rest.map(transform))
    }

    /// Appends an element to the end
    public func appending(_ element: Element) -> NonEmptyArray<Element> {
        NonEmptyArray(first: first, rest: rest + [element])
    }

    /// Prepends an element to the beginning
    public func prepending(_ element: Element) -> NonEmptyArray<Element> {
        NonEmptyArray(first: element, rest: [first] + rest)
    }

    /// Returns element at index, or nil if out of bounds
    public func safeElement(at index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return index == 0 ? first : rest[index - 1]
    }
}

// MARK: - Equatable

extension NonEmptyArray: Equatable where Element: Equatable {}

// MARK: - Hashable

extension NonEmptyArray: Hashable where Element: Hashable {}

// MARK: - Codable

extension NonEmptyArray: Codable where Element: Codable {
    public init(from decoder: Decoder) throws {
        let array = try [Element](from: decoder)
        guard let nonEmpty = NonEmptyArray(array) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected non-empty array"
                )
            )
        }
        self = nonEmpty
    }

    public func encode(to encoder: Encoder) throws {
        try asArray.encode(to: encoder)
    }
}

// MARK: - Sequence

extension NonEmptyArray: Sequence {
    public func makeIterator() -> IndexingIterator<[Element]> {
        asArray.makeIterator()
    }
}

// MARK: - Collection

extension NonEmptyArray: Collection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public func index(after i: Int) -> Int {
        i + 1
    }

    /// Required subscript for Collection conformance
    public subscript(position: Int) -> Element {
        precondition(position >= 0 && position < count, "Index out of bounds")
        return position == 0 ? first : rest[position - 1]
    }
}

// MARK: - RandomAccessCollection

extension NonEmptyArray: RandomAccessCollection {}
