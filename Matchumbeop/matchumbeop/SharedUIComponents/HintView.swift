import SwiftUI

struct HintView: View {
    var body: some View {
        HStack(spacing: 10) {
            HintItem(color: Red, text: "맞춤법")
            HintItem(color: Green, text: "띄어쓰기")
            HintItem(color: Violet, text: "표준어 의심")
            HintItem(color: Blue, text: "통계적 교정")
        }
    }
}

struct HintItem: View {
    var color: Color
    var text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(text)
                .foregroundColor(.gray)
                .font(.system(size: 12, weight: .thin))
        }
    }
}

struct HintView_Previews: PreviewProvider {
    static var previews: some View {
        HintView()
    }
}
