//
//  ControlPanelView.swift
//  VideoSwiftUISample
//

import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject var viewModel: TrtcViewModel

    var body: some View {
        VStack {
            StatusView()
            ControlView()
            ErrorView()
        }
        .padding()
    }
    
    struct StatusView: View {
        @EnvironmentObject var viewModel: TrtcViewModel

        var body: some View {
            HStack {
                //Label(defaults.userId, systemImage: "person")
                //Spacer()
                Text("Room: #\(viewModel.defaults.roomId) (+\(viewModel.roomUsers.count) Joined)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    struct ControlView: View {
        @EnvironmentObject var viewModel: TrtcViewModel

        var body: some View {
            HStack {
                Spacer()

                Button(action: {
                    if viewModel.videoAvailable {
                        viewModel.muteLocalVideo(mute: true)
                    } else {
                        viewModel.muteLocalVideo(mute: false)
                    }
                }, label: {
                    Image(systemName: viewModel.videoAvailable ? "video.fill" : "video.slash.fill")
                })
                .tint(.primary)
                .padding(.trailing)

                Button(action: {
                    viewModel.switchCamera()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                })
                .disabled(!viewModel.videoAvailable)
                .tint(.primary)
                .padding(.trailing)
                
                Button(action: {
                    if viewModel.audioAvailable {
                        viewModel.muteLocalAudio(mute: true)
                    } else {
                        viewModel.muteLocalAudio(mute: false)
                    }
                }, label: {
                    Image(systemName: viewModel.audioAvailable ? "mic.fill" : "mic.slash.fill")
                })
                .tint(.primary)
                .padding(.trailing)
                
                Button(action: {
                    if viewModel.joined {
                        viewModel.exitRoom()
                    } else {
                        viewModel.enterRoom(userId: viewModel.defaults.userId, roomId: viewModel.defaults.roomId)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text(viewModel.joined ? "Leave" : "Join")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.joined ? .red : .green)
            }
        }
    }

    struct ErrorView: View {
        @EnvironmentObject var viewModel: TrtcViewModel
        
        var body: some View {
            HStack {
                if !viewModel.errMessage.isEmpty {
                    Text(viewModel.errMessage)
                }
            }
        }
    }
}

struct ControlPanelView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel()

        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                    .frame(maxHeight: .infinity)
                ControlPanelView()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
            .padding()
        }
        .environmentObject(viewModel)
    }
}
