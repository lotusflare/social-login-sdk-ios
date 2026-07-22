import SwiftUI

enum SocialBrandColors {
    static let googleBorder = Color(red: 0.45, green: 0.47, blue: 0.46)
    static let googleText = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let facebookBlue = Color(red: 0.09, green: 0.47, blue: 0.95)
    static let facebookText = Color.white
}

struct GoogleLogoMark: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: 3.2)
                .rotationEffect(.degrees(-45))

            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.98, green: 0.74, blue: 0.02), lineWidth: 3.2)
                .rotationEffect(.degrees(45))

            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.13, green: 0.59, blue: 0.24), lineWidth: 3.2)
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 3.2)
                .rotationEffect(.degrees(225))

            Rectangle()
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                .frame(width: 7, height: 3)
                .offset(x: 2)

            Rectangle()
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                .frame(width: 3, height: 7)
                .offset(x: 2, y: -2)
        }
        .frame(width: 18, height: 18)
    }
}

struct FacebookLogoMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
            Text("f")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(SocialBrandColors.facebookBlue)
                .offset(y: -1)
        }
        .frame(width: 20, height: 20)
    }
}
