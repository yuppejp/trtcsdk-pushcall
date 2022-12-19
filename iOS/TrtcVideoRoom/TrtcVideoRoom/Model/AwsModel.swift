//
//  AwsModel.swift
//  TrtcVideoRoom
//

import Foundation

let apiGateway = MY_apiGateway

struct AwsResponseHeader: Codable {
    let statusCode: Int
    let body: String
}

// VOIP Push
struct RegisterEndpointRequest: Codable {
    var command: String = "RegisterEndpoint"
    let deviceToken: String
    let customUserData: CustomUserData
    
    struct CustomUserData: Codable {
        let userId: String
        let roomId: Int
    }
}
struct RegisterEndpointResponse: Codable {
    let userId: String
    let roomId: Int
    let users: [String]
}

struct PushCallRequest: Codable {
    var command: String = "PushCall"
    let userIds: [String]
    let message: String
}
struct PushCallResponse: Codable {
}

struct FetchRoomUsersRequest: Codable {
    var command: String = "FetchRoomUsers"
    let roomId: Int
}
struct FetchRoomUsersResponse: Codable {
    let roomId: Int
    let users: [String]
}

// DynamoDB
struct WriteMeetingRequest: Codable {
    var command: String = "WriteMeeting"
    let roomId: String
    let subject: String
    let startDate: String // timeIntervalSince1970 as string
}
struct WriteMeetingResponse: Codable {
}

struct DeleteMeetingRequest: Codable {
    var command: String = "DeleteMeeting"
    let id: String
}
struct DeleteMeetingResponse: Codable {
}

struct ScanMeetingsRequest: Codable {
    var command: String = "ScanMeetings"
    let roomId: String
}
struct ScanMeetingsResponse: Codable {
    let Count: Int
    let Items: [MeetingItem]
    
    struct MeetingItem: Codable {
        let id: ID
        let subject: Value
        let startDate: Value
        let roomId: Value
        let meetingStatus: Value
        
        struct ID: Codable {
            let n: String

            enum CodingKeys: String, CodingKey {
                case n = "N"
            }
        }
        
        struct Value: Codable {
            let S: String?
            let N: Int?
        }
    }
}

class AwsModel {
    func register(roomId: Int, userId: String, deviceToken: String) async throws -> [RoomUser]? {
        // request parameter
        let customUserData = RegisterEndpointRequest.CustomUserData(userId: userId, roomId: roomId)
        let input = RegisterEndpointRequest(deviceToken: deviceToken, customUserData: customUserData)
        let encoder = JSONEncoder()
        let json = try encoder.encode(input)
        //print("*** register input:" + String(bytes: json, encoding: .utf8)!)
        
        // post request
        let data = try await HttpModel.shared.post(urlString: apiGateway, body: json)
        
        // parsing the response
        let decoder = JSONDecoder()
        let response = try decoder.decode(AwsResponseHeader.self, from: data)
        let bodyData = response.body.data(using: .utf8)
        
        let body = try decoder.decode(RegisterEndpointResponse.self, from: bodyData!)
        //            print("*** userId: \(body.userId)")
        //            print("*** roomId: \(body.roomId)")
        //            print("*** users: \(body.users)")
        
        // response contains array of userId
        var users: [RoomUser] = []
        for userId in body.users {
            users.append(RoomUser(userId: userId))
        }
        return users
    }
    
    func pushCall(userIds: [String], message: String) async throws {
        // request parameter
        let input = PushCallRequest(userIds: userIds, message: message)
        let encoder = JSONEncoder()
        let json = try encoder.encode(input)
        //        print("*** register input:" + String(bytes: json, encoding: .utf8)!)
        
        // post request
        let data = try await HttpModel.shared.post(urlString: apiGateway, body: json)
        print("*** pushCall response:" + String(bytes: data, encoding: .utf8)!)
    }
    
    func fetchRoomUsers(roomId: Int) async throws  -> [RoomUser]? {
        // request parameter
        let input = FetchRoomUsersRequest(roomId: roomId)
        let encoder = JSONEncoder()
        let json = try encoder.encode(input)
        
        // post request
        let data = try await HttpModel.shared.post(urlString: apiGateway, body: json)
        
        // parsing the response
        let decoder = JSONDecoder()
        let response = try decoder.decode(AwsResponseHeader.self, from: data)
        let bodyData = response.body.data(using: .utf8)
        let body = try decoder.decode(FetchRoomUsersResponse.self, from: bodyData!)
        
        // response contains array of userId
        var users: [RoomUser] = []
        for userId in body.users {
            users.append(RoomUser(userId: userId))
        }
        return users
    }
    
    
    func writeMeeting(roomId: Int, subject: String, startDate: Date) async throws {
        let roomIdString = String(roomId)
        let dateString = String(Int64(startDate.timeIntervalSince1970) * 1000)
        
        // request parameter
        let input = WriteMeetingRequest(roomId: roomIdString, subject: subject, startDate: dateString)
        let encoder = JSONEncoder()
        let json = try encoder.encode(input)
        
        // post request
        let data = try await HttpModel.shared.post(urlString: apiGateway, body: json)
        
        // parsing the response
        let decoder = JSONDecoder()
        let response = try decoder.decode(AwsResponseHeader.self, from: data)
        print("*** writeMeeting: \(response)")
    }
    
    func deleteMeeting(id: Int) async throws {
        // request parameter
        let stringId = String(id)
        print("*** stringId: \(stringId)")
        let input = DeleteMeetingRequest(id: stringId)
        let encoder = JSONEncoder()
        let json = try encoder.encode(input)
        
        // post request
        let data = try await HttpModel.shared.post(urlString: apiGateway, body: json)
        
        // parsing the response
        let decoder = JSONDecoder()
        let response = try decoder.decode(AwsResponseHeader.self, from: data)
        print("*** deleteMeeting: \(response)")
    }
    
    func scanMeeting(roomId: Int) async throws -> [Meeting] {
        // request parameter
        let input = ScanMeetingsRequest(roomId: String(roomId))
        let encoder = JSONEncoder()
        let json = try encoder.encode(input)
        
        // post request
        let data = try await HttpModel.shared.post(urlString: apiGateway, body: json)

        // parsing the response
        let decoder = JSONDecoder()
        let response = try decoder.decode(AwsResponseHeader.self, from: data)
        print("*** scanMeeting: response: \(response)")

        let bodyData = response.body.data(using: .utf8)
        let body = try decoder.decode(ScanMeetingsResponse.self, from: bodyData!)
        
        // perse response body
        var mettings: [Meeting] = []
        for item in body.Items {
            let id = Int(item.id.n) ?? 0
            let roomId = Int(item.roomId.S!) ?? 0
            let subject = item.subject.S!
            let meetingStatus = item.meetingStatus.S!
            let since1970 = Double(item.startDate.S!) ?? 0.0
            let startDate = Date(timeIntervalSince1970: (since1970 / 1000.0))
            let meeting = Meeting(itemId: id, roomId: roomId, subject: subject, startDate: startDate, meetingStatus: meetingStatus)
            mettings.append(meeting)
        }
        
        return mettings
    }
}
