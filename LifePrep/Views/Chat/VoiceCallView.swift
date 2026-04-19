import SwiftUI

struct VoiceCallView: View {
    let remoteUserName: String
    @EnvironmentObject var callVM: VoiceCallViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemGray6), Color(.systemBackground)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Text(String(remoteUserName.prefix(1)).uppercased())
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.green)
                }

                VStack(spacing: 8) {
                    Text(remoteUserName)
                        .font(.title.bold())
                    statusText
                }

                Spacer()

                // Notice for internet calls
                if callVM.callState == .calling || callVM.callState == .ringing {
                    Text("📡 網路語音通話需要整合 WebRTC 函式庫\n（詳見 WebRTCSignalingService.swift）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // End call button
                Button {
                    callVM.endCall()
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 72, height: 72)
                        Image(systemName: "phone.down.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onChange(of: callVM.callState) { _, state in
            if state == .ended { dismiss() }
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch callVM.callState {
        case .calling:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.6)
                Text("撥號中…")
            }
            .foregroundStyle(.secondary)
        case .ringing:
            Text("等待接聽…").foregroundStyle(.secondary)
        case .connected:
            Text(callVM.formattedDuration)
                .font(.title3.monospacedDigit())
                .foregroundStyle(.green)
        case .ended:
            Text("通話結束").foregroundStyle(.secondary)
        case .idle:
            EmptyView()
        }
    }
}
