//
//  RemoteUsersVideoView.swift
//  VideoSwiftUISample
//

import SwiftUI

struct RemoteUsersVideoView: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    
    var body: some View {
        BodyView(room: viewModel.room)
    }
    
    struct BodyView: View {
        @EnvironmentObject var viewModel: TrtcViewModel
        @ObservedObject var room: Room

        var body: some View {
            GeometryReader { geometry in
                let videoSize = CGSize(width: 100, height: 150)
                let gridPadding = CGPoint(x: 4, y: 4)
                let gredCol = room.users.filter({$0.joined == true}).count < 5 ? 1 : (geometry.size.width > 300 ? 2 : 1)

                ScrollView {
                    let columns: [GridItem] = Array(
                        repeating: GridItem(.fixed(videoSize.width), spacing: gridPadding.x, alignment: .top),
                        count: gredCol)
                    LazyVGrid(columns: columns, alignment: .trailing, spacing: gridPadding.y) {
                        ForEach(room.users) { user in
                            RemoteVideoView(user: user)
                                .frame(width: videoSize.width, height: videoSize.height)
                                .background(.background.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
                .onChange(of: room.users.filter({$0.joined}).count) { _ in
                    print("***** onChange: joined: count: \(room.users.filter({$0.videoAvailable}).count)")
                    withAnimation() {
                        room.users = room.users.sorted(by: {$0.lastVideoAvailableTime < $1.lastVideoAvailableTime})
                        room.users = room.users.sorted(by: {$0.lastVideoAvailableTime > $1.lastVideoAvailableTime})
                    }
                }
                .onChange(of: room.users.filter({$0.videoAvailable}).count) { _ in
                    print("***** onChange: videoAvailable: count: \(room.users.filter({$0.videoAvailable}).count)")
                    withAnimation() {
                        room.users = room.users.sorted(by: {$0.lastVideoAvailableTime > $1.lastVideoAvailableTime})
                    }
                }
            }
        }
    }
    
    
    struct RemoteVideoView: View {
        @ObservedObject var user: RoomUser
        
        var body: some View {
            if user.videoAvailable && !user.me {
                ZStack(alignment: .bottom) {
                    if user.videoAvailable {
                        TRTCRemoteVideoView(remoteUserId: user.userId)
                    } else {
                        Image(systemName: "video.slash.fill")
                    }
                    CaptionView(user: user)
                }
            }
        }
    }
    
    struct CaptionView: View {
        @ObservedObject var user: RoomUser
        
        var body: some View {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                        .frame(maxHeight: .infinity)
                    BodyView(user: user)
                        .frame(maxWidth: geometry.size.width)
                        .background(.background.opacity(0.3))
                        .padding(4)
                }
            }
        }
        
        struct BodyView: View {
            @ObservedObject var user: RoomUser
            
            var body: some View {
                HStack(spacing: 2) {
                    Image(systemName: user.audioAvailable ? "mic.fill" : "mic.slash.fill")
                        .font(.caption)
                    Text(user.userId)
                        .font(.caption)
                }
            }
        }
    }
    
    struct RemoteUserView_Previews: PreviewProvider {
        static var previews: some View {
            let viewModel = TrtcViewModel(debugPreview: true)
            var lastUserId = ""

            ZStack(alignment: .topTrailing) {
                VStack {
                    Button("add user") {
                        lastUserId = Util.generator(6)
                        let user = RoomUser(userId: lastUserId, videoAvailable: true)
                        viewModel.room.appendUser(user)
                    }
                    Button("togle videoAvailable") {
                        if let user = viewModel.room.firstUser("lastUserId") {
                            user.videoAvailable.toggle()
                        }
                    }
                    Button("togle audioAvailable") {
                        if let user = viewModel.room.firstUser("lastUserId") {
                            user.audioAvailable.toggle()
                        }
                    }
                    HStack {
                        Spacer()
                            .frame(maxHeight: .infinity)
                        RemoteUsersVideoView()
                            .frame(maxHeight: .infinity, alignment: .topTrailing)
                            .environmentObject(viewModel)
                    }
                }
                .padding()
            }
        }
    }
}
