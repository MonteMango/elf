//
//  ModalPresentationModifier.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import SwiftUI
import UIKit

struct ModalPresentationModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let modalContent: () -> ModalContent

    // Configuration
    private let widthRatio: CGFloat = 0.8
    private let heightRatio: CGFloat = 0.65
    private let maxHeightLimit: CGFloat = 500
    private let cornerRadius: CGFloat = 20
    private let dimOpacity: Double = 0.4

    @State private var isShowingView: Bool = false
    @State private var offset: CGFloat = UIScreen.main.bounds.height * 1.5
    @State private var backgroundOpacity: Double = 0
    @State private var isAnimatingDismiss: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            // Original content
            content

            // Modal presentation - keep visible during dismiss animation
            if isShowingView || isAnimatingDismiss {
                // Dimmed background
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()

                // Modal view
                GeometryReader { geometry in
                    // Calculate visual center with safe area
                    let safeTop = geometry.safeAreaInsets.top
                    let safeBottom = geometry.safeAreaInsets.bottom
                    let availableHeight = geometry.size.height - safeTop - safeBottom
                    let visualCenterY = safeTop + (availableHeight / 2)

                    // Calculate max height from available height (without safe area)
                    let calculatedMaxHeight = min(maxHeightLimit, availableHeight * heightRatio)

                    modalContent()
                        .frame(width: geometry.size.width * widthRatio)
                        .frame(maxHeight: calculatedMaxHeight)
                        .background(Color.white)
                        .cornerRadius(cornerRadius)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .position(
                            x: geometry.size.width / 2,
                            y: visualCenterY
                        )
                        .offset(y: offset)
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: isPresented) { oldValue, newValue in
            if newValue {
                // Opening: show view first, then animate
                isShowingView = true
                isAnimatingDismiss = false
                offset = UIScreen.main.bounds.height * 1.5
                backgroundOpacity = 0

                // Small delay to ensure view is in hierarchy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        offset = 0
                        backgroundOpacity = dimOpacity
                    }
                }
            } else {
                // Closing: animate first, then hide view
                isAnimatingDismiss = true

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = UIScreen.main.bounds.height * 1.5
                    backgroundOpacity = 0
                }

                // Hide view after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShowingView = false
                    isAnimatingDismiss = false
                }
            }
        }
    }
}

extension View {
    func customModal<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ModalPresentationModifier(isPresented: isPresented, modalContent: content))
    }
}
