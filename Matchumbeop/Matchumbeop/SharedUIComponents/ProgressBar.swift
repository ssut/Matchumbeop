import SwiftUI

struct ProgressBar: View {
    @Binding var progress: Double
    @Binding var isError: Bool
    @State private var isVisible = true
    
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                Rectangle()
                    .fill(isError ? Color.red.opacity(0.75) : Color.blue.opacity(0.8))
                    .frame(width: CGFloat(self.progress / 100) * geometry.size.width)
                    .animation(.easeOut(duration: 0.2), value: progress)
                    .animation(.easeInOut(duration: 0.2), value: isError)
            }
            .frame(height: 4)
            .background(.clear)
            .cornerRadius(2)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: isVisible)
        }
        .onChange(of: progress) { newValue in
            if newValue >= 100 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isVisible = false
                    }
                }
            } else {
                withAnimation {
                    isVisible = true
                }
            }
        }
    }
}
