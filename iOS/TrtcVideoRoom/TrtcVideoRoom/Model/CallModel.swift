//
//  CallModel.swift
//  TrtcVideoRoom
//

import Foundation
import AVFoundation
import CallKit
import UIKit

final class CallModel: NSObject {
    private let controller = CXCallController()
    private let provider: CXProvider
    private var uuid = UUID()

    // singleton
    static let shared = CallModel(supportsVideo: true)
    
    private init(supportsVideo: Bool = false) {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.supportsVideo = supportsVideo
        
        // The icon image should be a square with side length of 40 points
        // https://developer.apple.com/documentation/callkit/cxproviderconfiguration/2274376-icontemplateimagedata
        if let image = UIImage(named: "person.crop.circle-40x40") {
            providerConfiguration.iconTemplateImageData = image.pngData()
        }
        
        provider = CXProvider(configuration: providerConfiguration)
    }

    func setup(_ delegate: CXProviderDelegate) {
        provider.setDelegate(delegate, queue: nil)
    }

    func StartCall(_ hasVideo: Bool = false) {
        uuid = UUID()
        let handle = CXHandle(type: .generic, value: "name1")
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction(action: startCallAction)
        controller.request(transaction) { error in
            if let error = error {
                print("CXStartCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func IncomingCall(_ hasVideo: Bool = false, displayText: String) {
        uuid = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: displayText)
        update.hasVideo = hasVideo
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("reportNewIncomingCall error: \(error.localizedDescription)")
            }
        }
    }

    func EndCall() {
        let action = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: action)
        controller.request(transaction) { error in
            if let error = error {
                print("CXEndCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func Connecting() {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: nil)
    }

    func Connected() {
        provider.reportOutgoingCall(with: uuid, connectedAt: nil)
    }

    func ConfigureAudioSession() {
        // Setup AudioSession
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [])
    }
}

// MARK: DEBUG

extension CallModel {
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaServerReset),
                                               name: AVAudioSession.mediaServicesWereResetNotification,
                                               object: nil)
    }

    @objc func handleRouteChange(notification: Notification) {
        print("handleRouteChange: \(notification)")
    }

    @objc func handleInterruption(notification: Notification) {
        print("handleInterruption: \(notification)")
    }

    @objc func handleMediaServerReset(notification: Notification) {
        print("handleMediaServerReset: \(notification)")
    }
}
