//
//  TestModalScreen.swift
//  elf_iOS
//
//  Created by Claude Code on 14.11.25.
//

import SwiftUI

struct TestModalScreen: View {
    let navigationManager: AppNavigationManager

    var body: some View {
        ZStack {
            Color.green
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("hello i am model view")
                    .font(.title)
                    .foregroundColor(.white)

                Button(action: {
                    navigationManager.dismissModal()
                }) {
                    Text("Close Modal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
    }
}
