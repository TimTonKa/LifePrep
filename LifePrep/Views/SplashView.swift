import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // 背景：優先使用 Assets 中的 "SplashBackground" 圖片，
            // 若尚未加入圖片則 fallback 至深色漸層
            if let _ = UIImage(named: "SplashBackground") {
                Image("SplashBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#0D1B0D") ?? .black,
                             Color(hex: "#1A3320") ?? .green.opacity(0.3),
                             Color(hex: "#0A120A") ?? .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            // 暗色遮罩，讓文字在圖片上也清晰
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App icon / logo
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 110, height: 110)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, Color(hex: "#52BE80") ?? .green],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("LifePrep")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("戰時生存準備指南")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(2)
                }

                Spacer()
                Spacer()

                // 底部載入指示
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(.white.opacity(0.6))
                    Text("初始化中…")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 48)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}
