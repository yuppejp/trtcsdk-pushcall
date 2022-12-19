//
//  CallRoomUserView.swift
//  TrtcVideoRoom
//

import SwiftUI

class ToggleItem: Identifiable, ObservableObject {
    let id = UUID()
    let user: RoomUser
    @Published var toggle: Bool
    
    init(user: RoomUser, toggle: Bool) {
        self.user = user
        self.toggle = toggle
    }
}

struct CallRoomUserView: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    @State private var inputText = "all gather!"
    @State private var items: [ToggleItem] = []
    var toggleSheet: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            List {
                Section {
                    ScrollView {
                        ForEach(items.filter({ $0.user.joined == false })) { item in
                            UserItmeView(item: item)
                                .padding(.trailing)
                        }
                    }
                    .frame(maxHeight: geometry.size.height * 0.3)
                    .padding(4)
                    
                    VStack {
                        HStack {
                            Text("Message:")
                            TextField("Input Message...", text: $inputText)
                                .keyboardType(.default)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(4)
                        }
                        
                        Button(action: {
                            var userIds: [String] = []
                            for item in items {
                                if item.toggle && !item.user.joined {
                                    userIds.append(item.user.userId)
                                }
                            }
                            if userIds.count > 0 {
                                viewModel.pushCall(userIds: userIds, message: inputText)
                                toggleSheet()
                            }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .tint(.primary)
                                Text("Call To")
                            }
                        }
                        .disabled(inputText.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                    }
                    //.disabled(!viewModel.joined || viewModel.room.users.filter({ $0.joined == false }).count == 0)
                    
                } header: {
                    HStack {
                        Image(systemName: "icloud.slash")
                        Text("Offline")
                    }
                    .font(.headline)
                }
                
                
                Section {
                    ScrollView {
                        ForEach(items.filter({$0.user.joined == true})) { item in
                            UserItmeView(item: item)
                        }
                    }
                    .frame(maxHeight: geometry.size.height * 0.3)
                    .padding(4)
                } header: {
                    HStack {
                        Image(systemName: "checkmark.icloud")
                        Text("Online")
                    }
                    .font(.headline)
                }
            }
            .onAppear {
                withAnimation() {
                    let users = viewModel.room.users.sorted(by: { $0.userId < $1.userId })
                    for user in users {
                        let item = ToggleItem(user: user, toggle: false)
                        items.append(item)
                    }
                }
            }
        }
    }
    
    struct UserItmeView: View {
        var item: ToggleItem
        @State private var toggle = false
        
        var body: some View {
            HStack {
                Image(systemName: item.user.joined ? "person.wave.2.fill" : "person")
                if item.user.me {
                    Text(item.user.userId + " (me)")
                        .font(.callout)
                } else {
                    if item.user.joined {
                        Text(item.user.userId)
                            .font(.callout)
                    } else {
                        Toggle(isOn: $toggle) {
                            VStack(alignment: .leading) {
                                Text(item.user.userId)
                            }
                        }
                        .onChange(of: toggle) { _ in
                            item.toggle = toggle
                        }
                    }
                }
            }
            .onAppear {
                toggle = item.toggle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RoomUserListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel(debugPreview: true)
        
        CallRoomUserView(toggleSheet: {})
            .environmentObject(viewModel)
    }
}
