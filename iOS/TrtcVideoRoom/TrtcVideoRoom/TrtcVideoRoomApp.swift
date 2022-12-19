//
//  TrtcVideoRoomApp.swift
//  TrtcVideoRoom
//

import SwiftUI
import CallKit
import PushKit

@main
struct TrtcVideoRoomApp: App {
    //@UIApplicationDelegateAdaptor(MyAppDelegate.self) var appDelegate
    @UIApplicationDelegateAdaptor(TrtcViewModel.self) var viewModel

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

//class MyAppDelegate: NSObject, UIApplicationDelegate {
//    let callModel = CallModel(supportsVideo: false)
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        setupPushKit()
//        return true
//    }
//
//    func setupPushKit() {
//        print("test: setupPushKit()")
//        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: .main)
//        voipRegistry.delegate = self
//        voipRegistry.desiredPushTypes = [.voIP]
//    }
//}
//
//extension MyAppDelegate: PKPushRegistryDelegate {
//    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
//        print("test: didUpdate pushCredentials")
//        let pkid = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
//        print("your device token: \(pkid)")
//    }
//
//    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
//        print("test: didInvalidatePushTokenFor")
//    }
//
//    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
//        print("test: didReceiveIncomingPushWith")
//        callModel.IncomingCall()
//    }
//}
//
