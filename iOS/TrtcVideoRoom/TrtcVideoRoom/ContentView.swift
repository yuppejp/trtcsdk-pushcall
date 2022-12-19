//
//  ContentView.swift
//  TrtcVideoRoom
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    @State var showSheetView = false
    
    var body: some View {
        NavigationView {
            MainView()
                .navigationBarTitleDisplayMode(.inline)
                //.navigationBarTitle(Text("Title"), displayMode: .inline)
                .navigationBarItems(
                    leading: LeadingNavigationBar(),
                    trailing: TrailingNavigationBar(toggleSheet: {
                        showSheetView.toggle()
                    })

                )
        }
        .sheet(isPresented: $showSheetView) {
            SheetView(showSheetView: self.$showSheetView)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // disable iPad pain
    }
    
    struct SheetView: View {
        @EnvironmentObject var viewModel: TrtcViewModel
        @Binding var showSheetView: Bool

        var body: some View {
            NavigationView {
                CallRoomUserView(toggleSheet: {
                    showSheetView.toggle()
                })
                    .navigationBarTitle(Text("Room: #\(viewModel.defaults.roomId)"), displayMode: .inline)
                    .navigationBarItems(
                        trailing:
                            Button(action: {
                                self.showSheetView = false
                            }) {
                                Text("Close").bold()
                            })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel(debugPreview: true)
        
        ContentView()
            .environmentObject(viewModel)
    }
}

