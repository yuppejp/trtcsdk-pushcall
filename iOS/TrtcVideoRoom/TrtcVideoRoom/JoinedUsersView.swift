//
//  JoinedUsersView.swift
//  TrtcVideoRoom
//

import SwiftUI

struct JoinedUsersView: View {
    @EnvironmentObject var viewModel: TrtcViewModel

    var body: some View {
        BodyView(room: viewModel.room, defaults: viewModel.defaults)
    }
    
    struct BodyView: View {
        @ObservedObject var room: Room
        @ObservedObject var defaults: AppDefaults
        @State private var scrollViewContentSize: CGSize = .zero

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text("Room: #\(defaults.roomId)")
                    .font(.callout)
                Text("Online (\(room.users.filter({ $0.joined == true }).count))")
                ScrollView {
                    VStack (alignment: .leading) {
                        ForEach(room.users) { user in
                            UserView(user: user)
                        }
                    }
                    .background(
                        // ScrollView shrink to fit
                        // https://developer.apple.com/forums/thread/671690
                        GeometryReader { geometry -> Color in
                            DispatchQueue.main.async {
                                scrollViewContentSize = geometry.size
                            }
                            return Color.clear
                        }
                    )
                }
                .onChange(of: room.users.count) { _ in
                    withAnimation() {
                        room.users = room.users.sorted(by: {$0.joinedTime > $1.joinedTime})
                    }
                }
                .frame(maxHeight: scrollViewContentSize.height)
            }
            .font(.caption)
        }
    }
    
    struct UserView: View {
        @ObservedObject var user: RoomUser
        
        var body: some View {
            if user.joined {
                HStack(spacing: 2) {
                    Image(systemName: user.audioAvailable ? "mic.fill" : "mic.slash.fill")
                    Text(user.userId)
                }
            }
        }
    }
}

struct JoinedUserListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel(debugPreview: true)
        
        VStack {
            Button("add") {
                let user = RoomUser(userId: Util.generator(6), joined: true)
                viewModel.room.appendUser(user)
            }
            JoinedUsersView()
                .environmentObject(viewModel)
        }
    }
}
