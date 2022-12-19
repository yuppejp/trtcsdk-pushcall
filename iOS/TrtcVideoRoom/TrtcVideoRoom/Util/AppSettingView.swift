//
//  AppSettingView.swift
//  TrtcVideoRoom
//

import SwiftUI

class AppDefaults: ObservableObject {
        @AppStorage("userId") var userId = ""
        @AppStorage("roomId") var roomId = 1
        @AppStorage("isFrontCamera") var isFrontCamera = true
        @AppStorage("awsEnabled") var awsEnabled = true
}

struct AppSettingView: View {
    @StateObject var defaults: AppDefaults
    @State private var selectionValue: Int? = nil

    var body: some View {
        VStack {
            Form {
                Section(header: Text("User Name")) {
                    VStack {
                        TextField("",text: $defaults.userId)
                    }
                }
                Section(header: Text("Room ID")) {
                    Stepper(value: $defaults.roomId, in: 1...100, step: 1) {
                        Text(defaults.roomId, format: .number)
                    }
                }
                Section(header: Text("Device")) {
                    Toggle(isOn: $defaults.isFrontCamera) {
                        VStack(alignment: .leading) {
                            Text("Use Front Camera")
                        }
                    }
                }
                
                Section(header: Text("Debug")) {
                    Toggle(isOn: $defaults.awsEnabled) {
                        VStack(alignment: .leading) {
                            Text("Enable AWS Access")
                        }
                    }
                }
            }
        }
    }
}

struct AppSettingView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingView(defaults: AppDefaults())
    }
}
