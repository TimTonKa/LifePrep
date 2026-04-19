import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var callVM: VoiceCallViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showNewChat = false
    @State private var newEmail = ""
    @State private var newName = ""
    @State private var showGroupSheet = false
    @State private var groupName = ""

    var body: some View {
        NavigationStack {
            Group {
                if !networkMonitor.isConnected {
                    offlinePlaceholder
                } else if chatVM.rooms.isEmpty {
                    ContentUnavailableView("尚無對話", systemImage: "bubble.left.and.bubble.right",
                                          description: Text("點擊右上角 + 開始新對話"))
                } else {
                    roomsList
                }
            }
            .navigationTitle("線上通訊")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button { showNewChat = true } label: {
                            Label("私人對話", systemImage: "person")
                        }
                        Button { showGroupSheet = true } label: {
                            Label("建立群組", systemImage: "person.3")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!networkMonitor.isConnected)
                }
            }
            .sheet(isPresented: $showNewChat) { newDirectChatSheet }
            .sheet(isPresented: $showGroupSheet) { newGroupSheet }
        }
        .onAppear { chatVM.startObservingRooms() }
        .onDisappear { chatVM.stopObservingRooms() }
    }

    private var roomsList: some View {
        List(chatVM.rooms) { room in
            NavigationLink(destination: ChatRoomView(room: room)
                .environmentObject(chatVM)
                .environmentObject(callVM)) {
                RoomRowView(room: room, currentUserId: chatVM.currentUserId)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { chatVM.startObservingRooms() }
    }

    private var offlinePlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("無網路連線")
                .font(.title2.bold())
            Text("線上通訊需要網路連線\n請使用「藍牙通訊」標籤進行離線通訊")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var newDirectChatSheet: some View {
        NavigationStack {
            Form {
                Section("對方資訊") {
                    TextField("顯示名稱", text: $newName)
                    TextField("使用者 UID（由對方提供）", text: $newEmail)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("新增對話")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showNewChat = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("建立") {
                        chatVM.createDirectRoom(withUserId: newEmail, withUserName: newName)
                        newEmail = ""; newName = ""
                        showNewChat = false
                    }
                    .disabled(newEmail.isEmpty || newName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var newGroupSheet: some View {
        NavigationStack {
            Form {
                Section("群組名稱") {
                    TextField("例如：家庭緊急群組", text: $groupName)
                }
                Section {
                    Text("建立群組後，可在群組資訊中邀請成員")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("建立群組")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showGroupSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("建立") {
                        chatVM.createGroupRoom(name: groupName, memberIds: [], memberNames: [:])
                        groupName = ""
                        showGroupSheet = false
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct RoomRowView: View {
    let room: ChatRoom
    let currentUserId: String

    var displayName: String {
        if room.isGroup { return room.name }
        let otherId = room.memberIds.first(where: { $0 != currentUserId }) ?? ""
        return room.memberNames[otherId] ?? room.name
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(room.isGroup ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: room.isGroup ? "person.3.fill" : "person.fill")
                    .foregroundStyle(room.isGroup ? .blue : .green)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.headline)
                    Spacer()
                    Text(room.lastMessageTime.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(room.lastMessage.isEmpty ? "開始對話" : room.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
