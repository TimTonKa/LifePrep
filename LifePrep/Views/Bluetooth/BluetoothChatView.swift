import SwiftUI
import MultipeerConnectivity
import PhotosUI

struct BluetoothChatView: View {
    @EnvironmentObject var btVM: BluetoothViewModel
    @State private var messageText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPeerSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar
                Divider()
                messagesList
                inputBar
            }
            .navigationTitle("藍牙通訊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showPeerSheet = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    btVM.isInCall
                        ? Button(action: btVM.endVoiceCall) {
                            Label("結束通話", systemImage: "phone.down.fill")
                                .foregroundStyle(.red)
                        }
                        : Button(action: btVM.startVoiceCall) {
                            Label("語音通話", systemImage: "phone.fill")
                                .foregroundStyle(btVM.connectedPeers.isEmpty ? .gray : .green)
                        }
                }
            }
            .sheet(isPresented: $showPeerSheet) { PeerDiscoverySheet().environmentObject(btVM) }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        btVM.sendImage(data)
                    }
                }
            }
        }
        .onAppear { btVM.start() }
        .onDisappear { btVM.stop() }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(btVM.connectedPeers.isEmpty ? Color.orange : Color.green)
                .frame(width: 10, height: 10)
            if btVM.connectedPeers.isEmpty {
                Text("尋找附近裝置中… 確保對方也開啟 LifePrep")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("已連線：" + btVM.connectedPeers.map { $0.displayName }.joined(separator: "、"))
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            Spacer()
            if btVM.isInCall {
                Label("通話中", systemImage: "waveform")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(btVM.messages) { message in
                        BTPeerMessageBubble(message: message,
                                            isMe: message.senderId == btVM.multipeerService.myDisplayName)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: btVM.messages.count) { _, _ in
                if let last = btVM.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            TextField("藍牙訊息…", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                btVM.sendText(messageText)
                messageText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(canSend ? .green : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(.regularMaterial)
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespaces).isEmpty && !btVM.connectedPeers.isEmpty
    }
}

struct BTPeerMessageBubble: View {
    let message: PeerMessage
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if message.type == .image, let imageData = message.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240, maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if message.type == .voiceStart {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill").foregroundStyle(.green)
                        Text("開始語音通話")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if message.type == .voiceStop {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.down.fill").foregroundStyle(.red)
                        Text("通話結束")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(message.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isMe ? Color.blue : Color(.systemGray5))
                        .foregroundStyle(isMe ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }
}

struct PeerDiscoverySheet: View {
    @EnvironmentObject var btVM: BluetoothViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("附近的裝置") {
                    if btVM.discoveredPeers.isEmpty {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("搜尋中…請確保對方也開啟此 App")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(btVM.discoveredPeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundStyle(.blue)
                                Text(peer.displayName)
                                Spacer()
                                if btVM.connectedPeers.contains(peer) {
                                    Label("已連線", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Button("連線") { btVM.invite(peer) }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                }

                Section("已連線") {
                    if btVM.connectedPeers.isEmpty {
                        Text("尚未連線任何裝置").foregroundStyle(.secondary)
                    } else {
                        ForEach(btVM.connectedPeers, id: \.self) { peer in
                            Label(peer.displayName, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("裝置搜尋")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

extension PeerMessage: Identifiable {}
