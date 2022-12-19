//
//  RemoteUser.swift
//  VideoSwiftUISample
//

import Foundation
import SwiftUI
import TXLiteAVSDK_TRTC
import CallKit
import PushKit

class Room: Identifiable, ObservableObject {
    @Published var users: [RoomUser] = []
    @Published var messages: [RoomMessage] = []

    func appendUser(_ user: RoomUser) {
        if users.first(where: {$0.userId == user.userId}) == nil {
            users.append(user)
        }
    }
    
    func removeUser(_ userId: String) {
        users.removeAll(where: {$0.userId == userId} )
    }
    
    func firstUser(_ userId: String? = nil) -> RoomUser? {
        if userId == nil {
            return users.first
        } else {
            if let user = users.first(where: { $0.userId == userId }) {
                return user
            }
        }
        return nil
    }
    
    func resetAllUser() {
        for user in users {
            user.joined = false
            user.videoAvailable = false
            user.audioAvailable = false
            user.me = false
        }
    }
}

class RoomUser: Identifiable, ObservableObject {
    var id = UUID()
    var userId: String
    var joinedTime = Date()
    var lastVideoAvailableTime = Date()
    var me: Bool
    @Published var joined: Bool
    @Published var videoAvailable: Bool
    @Published var audioAvailable: Bool
    
    init(userId: String, me: Bool = false, joined: Bool = false, videoAvailable: Bool = false, audioAvailable: Bool = false) {
        self.userId = userId
        self.me = me
        self.joined = joined
        self.videoAvailable = videoAvailable
        self.audioAvailable = audioAvailable
    }
    
    func setJoined(_ joined: Bool) {
        self.joined = joined
        if joined {
            self.joinedTime = Date()
        }
    }
}

struct RoomMessage: Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var userName: String
    var text: String
}

struct CustomCmdMsg: Codable {
    var userId: String // from userId
    var text: String // message body
}

class TrtcViewModel: NSObject, ObservableObject {
    @Published var room = Room()
    @Published var errMessage = ""
    @Published var joined = false
    @Published var audioAvailable = true
    @Published var videoAvailable = true
    @Published var isFrontCamera = true
    @Published var defaults = AppDefaults()
    let awsModel = AwsModel()
    private var trtcCloud: TRTCCloud = TRTCCloud.sharedInstance()
    private let callModel = CallModel.shared
    private var deviceToken: String = ""
    
    override init() {
        // https://stackoverflow.com/questions/28187261/ios-swift-fatal-error-use-of-unimplemented-initializer-init
        super.init()
        setup()
    }
    
    init(debugPreview: Bool = false) {
        super.init()
        setup(debugPreview: debugPreview)
    }
    
    func setup(debugPreview: Bool = false) {
        trtcCloud.delegate = self
        setupMockData(debugPreview)
    }
    
    func setupMockData(_ debugPreview: Bool) {
        // mock user
        if (debugPreview || !defaults.awsEnabled) {
            for i in 1..<30 {
                let user = RoomUser(userId: "user\(i)")
                room.appendUser(user)
            }
            if let me = room.users.first {
                me.me = true
                me.joined = true
                me.audioAvailable = true
                me.videoAvailable = true
            }
            let count = room.users.count / 2
            for i in 1..<count {
                let user = room.users[i]
                user.joined = true
                user.audioAvailable = true
                user.videoAvailable = true
            }
        }
        
        // mock chat message
        if debugPreview {
            for i in 1..<4 {
                room.messages.append(RoomMessage(userName: "user" + String(i), text: "message" + String(i)))
            }
            room.messages.append(RoomMessage(userName: defaults.userId, text: "reply message"))
        }
    }
    
    func enterRoom(userId: String, roomId: Int) {
        errMessage = ""
        
        // stop the video once
        videoAvailable = false
        trtcCloud.stopLocalPreview()
        
        let params = TRTCParams()
        params.sdkAppId = UInt32(SDKAPPID)
        params.roomId = UInt32(roomId)
        params.userId = userId
        params.role = .anchor
        params.userSig = TrtcUserSig.genTestUserSig(identifier: userId) as String
        trtcCloud.enterRoom(params, appScene: .videoCall)
        trtcCloud.startLocalAudio(.music)
        
        //callModel.StartCall(true)
    }
    
    func exitRoom() {
        trtcCloud.stopLocalAudio()
        //trtcCloud.stopLocalPreview()
        trtcCloud.exitRoom()
        
        //callModel.EndCall()
    }
    
    func muteLocalAudio(mute: Bool) {
        trtcCloud.muteLocalAudio(mute)
        audioAvailable = !mute
    }
    
    func muteLocalVideo(mute: Bool) {
        trtcCloud.muteLocalVideo(.big, mute: mute)
        videoAvailable = !mute
    }
    
    func switchCamera(_ isFrontCamera: Bool? = nil) {
        if let isFrontCamera = isFrontCamera {
            self.isFrontCamera = isFrontCamera
        } else {
            self.isFrontCamera.toggle()
        }
        trtcCloud.getDeviceManager().switchCamera(self.isFrontCamera)
    }
    
    func sendMessage(text: String) {
        do {
            let userId = defaults.userId
            let msg = CustomCmdMsg(userId: userId, text: text)
            let encoder = JSONEncoder()
            let json = try encoder.encode(msg)
            trtcCloud.sendCustomCmdMsg(1, data: json, reliable: false, ordered: false)
            room.messages.append(RoomMessage(userName: userId, text: text))
        } catch {
            errMessage = error.localizedDescription
        }
    }
    
    func pushCall(userIds: [String], message: String) {
        Task {
            do {
                try await awsModel.pushCall(userIds: userIds, message: message)
            } catch {
                errMessage = error.localizedDescription
            }
        }
    }
    
    func registerDeviceToken(deviceToken: String? = nil) {
        if let deviceToken = deviceToken {
            self.deviceToken = deviceToken
        }
        Task {
            if let users = try await awsModel.register(roomId: defaults.roomId, userId: defaults.userId, deviceToken: self.deviceToken) {
                // The list of room members is stored in AWS and the list is returned
                // append room user array when not registerd
                DispatchQueue.main.async {
                    self.updateRoomUsers(users: users)
                }
            }
        }
    }
    
    func fetchRoomUsers(roomId: Int) {
        Task {
            if let users = try await awsModel.fetchRoomUsers(roomId: defaults.roomId) {
                DispatchQueue.main.async {
                    self.updateRoomUsers(users: users)
                }
            }
        }
    }
    
    func updateRoomUsers(users: [RoomUser]) {
        for user in users {
            if self.room.firstUser(user.userId) == nil {
                self.room.appendUser(user)
            }
        }
        
        // mark myself when same userId
        if let user = self.room.firstUser(self.defaults.userId) {
            user.me = true
        }
    }
}

extension TrtcViewModel: TRTCCloudDelegate {
    func onEnterRoom(_ result: Int) {
        print("*** onEnterRoom: result: \(result)")
        joined = true
        videoAvailable = true
        
        if let me = room.firstUser(defaults.userId) {
            me.setJoined(true)
        } else {
            let me = RoomUser(userId: defaults.userId, me:true, joined: true, videoAvailable: videoAvailable, audioAvailable: audioAvailable)
            room.appendUser(me)
        }

        room.messages.append(RoomMessage(userName: defaults.userId, text: "enter room"))
    }
    
    func onExitRoom(_ reason: Int) {
        print("*** onExitRoom: reason: \(reason)")
        joined = false
        room.resetAllUser()
        
        callModel.EndCall()

        room.messages.append(RoomMessage(userName: defaults.userId, text: "exit room"))
    }
    
    func onRemoteUserEnterRoom(_ userId: String) {
        print("*** onRemoteUserEnterRoom: userId: \(userId)")
        if let user = room.firstUser(userId) {
            user.setJoined(true)
        } else {
            let user = RoomUser(userId: userId)
            user.setJoined(true)
            room.appendUser(user)
        }
        room.messages.append(RoomMessage(userName: userId, text: "enter room"))
    }
    
    func onRemoteUserLeaveRoom(_ userId: String, reason: Int) {
        print("*** onRemoteUserLeaveRoom: userId: \(userId), reason: \(reason)")
        if let user = room.firstUser(userId) {
            user.setJoined(false)
        }
        room.messages.append(RoomMessage(userName: userId, text: "exit room"))
    }
    
    func onUserAudioAvailable(_ userId: String, available: Bool) {
        print("*** onUserAudioAvailable: userId: \(userId), available: \(available)")
        if let user = room.firstUser(userId) {
            user.audioAvailable = available
        }
    }
    
    func onUserVideoAvailable(_ userId: String, available: Bool) {
        print("*** onUserVideoAvailable: userId: \(userId), available: \(available)")
        if let user = room.firstUser(userId) {
            if available {
                user.lastVideoAvailableTime = Date()
            }
            user.videoAvailable = available
        }
    }
    
    func onRecvCustomCmdMsgUserId(_ userId: String, cmdID: Int, seq: UInt32, message: Data) {
        print("*** onRecvCustomCmdMsgUserId: userId: \(userId), cmdID: \(cmdID), seq: \(seq)")
        do {
            let decoder = JSONDecoder()
            let msg = try decoder.decode(CustomCmdMsg.self, from: message)
            print("*** message: \(msg.userId): \(msg.text)")
            room.messages.append(RoomMessage(userName: msg.userId, text: msg.text))
        } catch {
            errMessage = error.localizedDescription
        }
    }
    
    func onError(_ errCode: TXLiteAVError, errMsg: String?, extInfo: [AnyHashable : Any]?) {
        if let msg = errMsg {
            self.errMessage = msg
        } else {
            self.errMessage = ""
        }
        print("*** onError: \(errCode): \(self.errMessage)")
    }
}

extension TrtcViewModel: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        setupPushKit()
        return true
    }
    
    func setupPushKit() {
        print("test: setupPushKit()")
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: .main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }
}

extension TrtcViewModel: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("*** pushRegistry: didUpdate pushCredentials")
        let deviceToken = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("*** device token: \(deviceToken)")
        
        if defaults.awsEnabled {
            // register device token on AWS
            registerDeviceToken(deviceToken: deviceToken)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("*** didInvalidatePushTokenFor")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("*** didReceiveIncomingPushWith")
        let dictionary = payload.dictionaryPayload as NSDictionary
        let aps = dictionary["aps"] as! NSDictionary
        let alert = aps["alert"]
        if let message = alert as? String {
            callModel.IncomingCall(true, displayText: "\(message)@room\(defaults.roomId)")
        } else {
            callModel.IncomingCall(true, displayText: "room\(defaults.roomId)")
        }
        enterRoom(userId: defaults.userId, roomId: defaults.roomId)
    }
}


