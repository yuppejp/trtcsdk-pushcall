//
//  NavigationBar.swift
//  TrtcVideoRoom
//

import SwiftUI


struct LeadingNavigationBar: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    
    var body: some View {
        HStack {
            NavigationLink(destination: AppSettingView(defaults: viewModel.defaults)
                .navigationTitle("Settings")
            ) {
//                Image(systemName: "gearshape")
//                    .foregroundColor(.primary)
                HStack(spacing: 1) {
                    Image(systemName: "person")
                    Text(viewModel.defaults.userId)
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
        }
        .font(.footnote)
    }
}

struct TrailingNavigationBar: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    var toggleSheet: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                if viewModel.videoAvailable {
                    viewModel.muteLocalVideo(mute: true)
                } else {
                    viewModel.muteLocalVideo(mute: false)
                }
            }) {
                Image(systemName: viewModel.videoAvailable ? "video.fill" : "video.slash.fill")
                    .tint(.primary)
            }

//            Button(action: {
//                viewModel.switchCamera()
//            }) {
//                Image(systemName: "arrow.triangle.2.circlepath")
//                    .tint(.primary)
//            }
            
            Button(action: {
                if viewModel.audioAvailable {
                    viewModel.muteLocalAudio(mute: true)
                } else {
                    viewModel.muteLocalAudio(mute: false)
                }
            }) {
                Image(systemName: viewModel.audioAvailable ? "mic.fill" : "mic.slash.fill")
                    .tint(.primary)
            }
            
            Button(action: {
                viewModel.fetchRoomUsers(roomId: viewModel.defaults.roomId)
                toggleSheet()
            }) {
                Image(systemName: "person.crop.rectangle.badge.plus")
                    .foregroundColor(.primary)
            }
            

            NavigationLink(destination: MeetingScheduleView(meetingList: MeetingList(meetings: []))
                .navigationTitle("Meeting Schedule")
            ) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.primary)
            }


            Button(action: {
                if viewModel.joined {
                    viewModel.exitRoom()
                } else {
                    viewModel.enterRoom(userId: viewModel.defaults.userId, roomId: viewModel.defaults.roomId)
                }
            }) {
                HStack(spacing: 2) {
                    Image(systemName: viewModel.joined ? "phone.down.fill" : "phone.fill")
                        .tint(.primary)
                    Text(viewModel.joined ? "Leave" : "Join")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.joined ? .red : .green)
        }
        .font(.footnote)
    }
}

struct NavigationBar: View {
    var body: some View {
        HStack {
            //LeadingNavigationBar()
            //Spacer()
            TrailingNavigationBar(toggleSheet: {})
        }
    }
}

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel(debugPreview: true)
        
        NavigationBar()
            .padding()
            .environmentObject(viewModel)
    }
}
