//
//  MainView.swift
//  TrtcVideoRoom
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                TrtcLocalVideoView(available: viewModel.videoAvailable, isFrontCamera: viewModel.isFrontCamera)
                    //.edgesIgnoringSafeArea(.all) // Expand the display area to the safe area
                    .onAppear {
                        viewModel.switchCamera(viewModel.defaults.isFrontCamera)
                    }
                VStack {
                    HStack(alignment: .top) {
                        JoinedUsersView()
                            .padding(4)
                            .background(.background.opacity(0.5))
                            .cornerRadius(8)
                        Spacer()
                        RemoteUsersVideoView()
                            .frame(maxHeight: .infinity, alignment: .topTrailing)
                    }
                    ChatView(room: viewModel.room)
                        .cornerRadius(8)
                        .frame(maxHeight: geometry.size.height * 0.3, alignment: .bottom)
                    ErrorView()
                }
                .padding()
            }
            .onAppear() {
                if viewModel.defaults.userId.isEmpty {
                    viewModel.defaults.userId = "user_" + Util.generator(4)
                    viewModel.registerDeviceToken()
                }
            }
        }
    }
    
    struct ErrorView: View {
        @EnvironmentObject var viewModel: TrtcViewModel
        
        var body: some View {
            if (!viewModel.errMessage.isEmpty) {
                Text(viewModel.errMessage)
                    .font(.caption)
                    .backgroundStyle(.background.opacity(0.5))
                
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel(debugPreview: true)
        
        MainView()
            .environmentObject(viewModel)
    }
}
