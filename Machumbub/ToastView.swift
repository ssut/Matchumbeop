import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(8)
    }
}
