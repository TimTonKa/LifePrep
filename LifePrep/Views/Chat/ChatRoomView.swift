import SwiftUI
import PhotosUI

struct ChatRoomView: View {
    let room: ChatRoom
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var callVM: VoiceCallViewModel
    @State private var messageText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCallView = false

    var displayName: String {
        if room.isGroup { return room.name }
        let otherId = room.memberIds.first(where: { $0 != chatVM.currentUserId }) ?? ""
        return room.memberNames[otherId] ?? room.name
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            inputBar
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    callVM.startCall(roomId: room.id, remoteUserName: displayName)
                    showCallView = true
                } label: {
                    Image(systemName: "phone.fill")
                }
            }
        }
        .fullScreenCover(isPresented: $showCallView) {
            VoiceCallView(remoteUserName: displayName)
                .environmentObject(callVM)
        }
        .onAppear { chatVM.startObservingMessages(roomId: room.id) }
        .onDisappear { chatVM.stopObservingMessages() }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    chatVM.sendImage(roomId: room.id, imageData: data)
                }
            }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatVM.messages) { message in
                        MessageBubble(message: message, isMe: message.senderId == chatVM.currentUserId)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: chatVM.messages.count) { _, _ in
                if let last = chatVM.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            // Image sharing requires Firebase Storage (Blaze plan)
            // PhotosPicker(selection: $selectedPhotoItem, matching: .images) { ... }

            TextField("訊息…", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                chatVM.sendMessage(roomId: room.id, text: messageText)
                messageText = ""
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .green)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .background(.regularMaterial)
    }
}

struct MessageBubble: View {
    let message: FirebaseMessage
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

                if message.messageType == .image, let urlStr = message.imageURL,
                   let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                            .frame(maxWidth: 240, maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } placeholder: {
                        ProgressView().frame(width: 100, height: 100)
                    }
                } else {
                    Text(message.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isMe ? Color.green : Color(.systemGray5))
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
