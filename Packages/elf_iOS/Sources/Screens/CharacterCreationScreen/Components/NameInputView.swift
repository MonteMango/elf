//
//  NameInputView.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_SwiftUI
import SwiftUI

/// Stage 2: Enter character name
struct NameInputView: View {
    @Binding var characterName: String
    @Binding var validationError: String?
    let safeAreaInsets: EdgeInsets
    let onRandomName: () -> Void
    let onNameChanged: () -> Void

    var isTextFieldFocused: FocusState<Bool>.Binding

    var body: some View {
        StageContainer(safeAreaInsets: safeAreaInsets) { _, safeArea in
            VStack(spacing: 20) {
                // Name input row
                HStack {
                    // Random name button with error indicator
                    Button(action: {
                        onRandomName()
                    }) {
                        Text("random name")
                            .font(ElfFonts.Component.nameInputLabel)
                            .foregroundStyle(.white)
                            .frame(width: 100, height: 36)
                            .background(Color.green.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .overlay(alignment: .trailing) {
                        // Error indicator button - dismisses keyboard
                        if validationError != nil {
                            Button(action: {
                                isTextFieldFocused.wrappedValue = false
                            }) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                    .frame(width: 45, height: 45)
                                    .contentShape(Rectangle())
                            }
                            .offset(x: 50)
                        }
                    }
                    .zIndex(1)

                    TextField(
                        "",
                        text: $characterName,
                        prompt: Text("Enter name...")
                            .foregroundStyle(.gray)
                    )
                    .font(ElfFonts.Component.nameInput)
                    .foregroundStyle(validationError != nil ? .red : .black)
                    .multilineTextAlignment(.center)
                    .focused(isTextFieldFocused)
                    .onChange(of: characterName) { _, _ in
                        onNameChanged()
                    }

                    Spacer()
                        .frame(width: 100)
                }
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(validationError != nil ? .red : .gray.opacity(0.5))
                }
                .padding(StagePadding.standard)
                .padding(.leading, safeArea.leading)
                .padding(.trailing, safeArea.trailing)

                // Inline validation error
                if let error = validationError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.leading, StagePadding.leading(safeArea))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(.top, StagePadding.top())
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused.wrappedValue = false
            }
        }
    }
}

#Preview {
    @Previewable @FocusState var isFocused: Bool

    NameInputView(
        characterName: .constant("Asuna Yuuki"),
        validationError: .constant("Name should contains only letter"),
        safeAreaInsets: EdgeInsets(),
        onRandomName: {},
        onNameChanged: {},
        isTextFieldFocused: $isFocused
    )
}
