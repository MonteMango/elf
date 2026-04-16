//
//  StageContainer.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import SwiftUI

/// Common container for all character creation stage views
/// Provides consistent safe area handling and padding logic
struct StageContainer<Content: View>: View {
    let safeAreaInsets: EdgeInsets
    let content: (CGSize, EdgeInsets) -> Content

    init(safeAreaInsets: EdgeInsets, @ViewBuilder content: @escaping (CGSize, EdgeInsets) -> Content) {
        self.safeAreaInsets = safeAreaInsets
        self.content = content
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        GeometryReader { geometry in
            content(geometry.size, safeAreaInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
        }
    }
}

/// Standard padding values for stage views
enum StagePadding {
    static let standard: CGFloat = 10

    static func leading(_ safeArea: EdgeInsets) -> CGFloat {
         safeArea.leading
    }

    static func trailing(_ safeArea: EdgeInsets) -> CGFloat {
         safeArea.trailing
    }

    static func top() -> CGFloat {
        standard
    }

    static func bottom(_ safeArea: EdgeInsets) -> CGFloat {
         safeArea.bottom
    }
}

#Preview {
    StageContainer(safeAreaInsets: EdgeInsets()) { size, safeArea in
        VStack {
            Text("Stage Content")
                .padding(.top, StagePadding.top())

            Spacer()

            Text("Size: \(Int(size.width)) x \(Int(size.height))")
                .padding(.bottom, StagePadding.bottom(safeArea))
        }
        .background { Color.pink }
    }
}
