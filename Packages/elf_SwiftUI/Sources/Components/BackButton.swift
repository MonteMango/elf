//
//  BackButton.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import SwiftUI

public struct BackButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.backward")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.orange)
        }
    }
}

#Preview {
    BackButton {
        print("Back tapped")
    }
}
