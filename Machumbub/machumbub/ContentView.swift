import SwiftUI
import Combine
import Foundation
import SwiftSoup

struct ContentView: View {
     @StateObject var appState = AppState.shared
     
     @State private var textLimit = 1800 // hard-limit (TODO: 풀기?)
     @State private var isSettingsButtonHovered = false
     
     @FocusState private var isTextEditorFocused: Bool
     
     private let analytics: Analytics = MachumbubAnalytics.shared
     
     var body: some View {
          VStack(spacing: 10) {
               TextEditor(text: $appState.text)
                    .focused($isTextEditorFocused)
                    .textEditorStyle(.plain)
                    .autocorrectionDisabled()
                    .lineSpacing(2)
                    .font(.system(size: 14))
                    .background(alignment: .topLeading) {
                         if appState.text.isEmpty {
                              Text("맞춤법 검사를 원하는 단어나 문장을 입력해 주세요.\n검사: command + return (⌘ + ↩)")
                                   .lineSpacing(2)
                                   .padding(.leading, 6)
                                   .font(.system(size: 14))
                                   .foregroundColor(Color(.systemGray))
                         }
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                            Button(action: {
                                 appState.openSettings()
                            }) {
                                Image(systemName: "gearshape")
                                      .foregroundColor(.secondary)
                            }
                            .accessibilityHint("설정")
                            .buttonStyle(BorderlessButtonStyle())
                            .animation(.easeInOut, value: 0.1)
                            .background(.clear)
                            .opacity(isSettingsButtonHovered ? 1 : 0.5)
                            .onHover { isHovered in
                                 isSettingsButtonHovered = isHovered
                                 if isHovered {
                                      NSCursor.arrow.push()
                                 } else {
                                      NSCursor.pop()
                                 }
                            }
                    }
                    .overlay(alignment: .bottomTrailing) {
                         Text("\(appState.text.count)")
                              .font(.system(size: 12))
                              .foregroundColor(Color(.systemGray))
                              .shadow(
                                   color: Color.primary.opacity(0.2),
                                   radius: 1,
                                   x: 0,
                                   y: 0
                              )
                              .padding(.trailing, 6)
                              .padding(.bottom, 6)
                              .onChange(of: appState.text) {
                                   if appState.text.count > textLimit {
                                        appState.text = String(appState.text.prefix(textLimit))
                                   }
                              }
                    }
                    .onKeyPress { press in
                         if (!appState.isLoading && press.key == KeyEquivalent.return && press.modifiers.contains(EventModifiers.command)) {
                              Task {
                                   await self.appState.checkSpelling(text: appState.text)
                                   self.analytics.send(.spellChecked(method: .inApp, length: appState.text.count))
                              }
                              return .handled
                         }
                         return .ignored
                    }
                    .frame(height: 200)
                    .onAppear {
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                              isTextEditorFocused = true
                         }
                    }
               
               if appState.isLoading {
                    ProgressView()
                         .padding(.vertical, 10)
               } else if let errorMessage = appState.errorMessage {
                    Text(errorMessage)
                         .foregroundColor(.red)
                         .padding(.vertical, 10)
               } else if let result = appState.result {
                    Divider()
                    VStack {
                         DraggableTextView(attributedText: NSAttributedString(result), font: .systemFont(ofSize: 14))
                              .padding(.horizontal, 4)
                              .padding(.vertical, 2)
                              .background(Color(NSColor.windowBackgroundColor))
                         
                         HStack {
                              HintView()
                                   .padding(.leading, 4)
                              Spacer()
                              Button(action: {
                                   NSPasteboard.general.clearContents()
                                   let plainText = String(result.characters)
                                   NSPasteboard.general.setString(plainText, forType: .string)
                                   
                                   appState.showToast = true
                                   DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        appState.showToast = false
                                   }
                                   
                                   self.analytics.send(.textCopied)
                              }) {
                                   Text("복사")
                              }
                              //                               .buttonStyle(BorderlessButtonStyle())
                              .padding(.horizontal, 4)
                         }
                         //                          HintView()
                         .frame(height: 10)
                         .padding(.bottom, 2)
                    }
                    .frame(maxHeight: 280)
               }
          }
          .padding(12)
          .background(Color(NSColor.windowBackgroundColor))
          .cornerRadius(12)
          .shadow(radius: 10)
          //            .frame(minWidth: 480, minHeight: 0, maxHeight: .infinity, alignment: .top)
          .frame(width: 480, height: calculateHeight(), alignment: .top)
          .overlay(
               VStack {
                    Spacer()
                    if appState.showToast {
                         ToastView(message: "클립보드에 복사되었습니다.")
                              .padding(.bottom, 20)
                              .transition(.opacity)
                    }
               }
                    .animation(.easeInOut(duration: 0.3), value: appState.showToast)
          )
     }
     
     private func calculateHeight() -> CGFloat {
          let resultHeight = appState.result != nil ? 300 : 0
          return CGFloat(225 + resultHeight)
     }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
