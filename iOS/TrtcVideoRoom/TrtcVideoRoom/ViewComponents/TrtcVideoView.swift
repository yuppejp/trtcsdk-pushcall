//
//  TrtcLocalVideoView.swift
//  VideoSwiftUISample
//

import Foundation
import SwiftUI
import TXLiteAVSDK_TRTC

struct TrtcLocalVideoView: UIViewControllerRepresentable {
    var available: Bool
    var isFrontCamera: Bool
    private let trtcCloud: TRTCCloud = TRTCCloud.sharedInstance()

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .lightGray
        return viewController
    }
    
    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        if available {
            trtcCloud.startLocalPreview(isFrontCamera, view: viewController.view)
            
            let encParams = TRTCVideoEncParam()
            encParams.videoResolution = ._640_360
            encParams.videoBitrate = 550
            encParams.videoFps = 15
            trtcCloud.setVideoEncoderParam(encParams)
            viewController.view.layer.opacity = 1
        } else {
            trtcCloud.stopLocalPreview()
            viewController.view.layer.opacity = 0.2
        }
    }
    
    final class Coordinator: NSObject {
        let parent: TrtcLocalVideoView
        init(_ parent: TrtcLocalVideoView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    static func dismantleUIView(_ viewController: UIViewController, coordinator: Coordinator) {
        coordinator.parent.trtcCloud.stopLocalPreview()
    }
}

struct TRTCRemoteVideoView: UIViewControllerRepresentable {
    let remoteUserId: String
    private let trtcCloud: TRTCCloud = TRTCCloud.sharedInstance()

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .gray //.lightGray
        return viewController
    }
    
    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        trtcCloud.startRemoteView(remoteUserId, streamType:.small, view: viewController.view)
    }
    
    final class Coordinator: NSObject {
        let parent: TRTCRemoteVideoView
        init(_ parent: TRTCRemoteVideoView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    static func dismantleUIView(_ viewController: UIViewController, coordinator: Coordinator) {
        coordinator.parent.trtcCloud.stopRemoteView(coordinator.parent.remoteUserId, streamType: .small)
    }
}
