//
//  HttpModel.swift
//  TrtcVideoRoom
//

import Foundation

class HttpModel {
    static let shared = HttpModel()
    
    private init() {
    }
    
    func post(urlString: String, body: Data) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw AppHttpError.invalidUrlString
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AppHttpError.invalidResponse
            }
            
            switch response.statusCode {
            case 200 ..< 400:
                //let jsonStr =  String(bytes: data, encoding: .utf8)!
                return data
            case 400 ..< 400:
                throw AppHttpError.clientError(response.statusCode)
            case 500... :
                throw AppHttpError.serverError(response.statusCode)
            default:
                throw AppHttpError.statusError(response.statusCode)
            }
        } catch {
            throw AppHttpError.requestError(error)
        }
    }

    func post(urlString: String, body: Dictionary<String, Any>) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw AppHttpError.invalidUrlString
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw AppHttpError.invalidResponse
            }
            
            switch response.statusCode {
            case 200 ..< 400:
                //let jsonStr =  String(bytes: data, encoding: .utf8)!
                return data
            case 400 ..< 400:
                throw AppHttpError.clientError(response.statusCode)
            case 500... :
                throw AppHttpError.serverError(response.statusCode)
            default:
                throw AppHttpError.statusError(response.statusCode)
            }
        } catch {
            throw AppHttpError.requestError(error)
        }
    }
}

enum AppHttpError: LocalizedError {
    case invalidUrlString
    case invalidResponse
    case responseError
    case noData
    case clientError(_ statusCode: Int)
    case serverError(_ statusCode: Int)
    case statusError(_ statusCode: Int)
    case requestError(_ error: Error)

    var errorDescription: String? {
        switch self {
        case .invalidUrlString: return "invalid url string"
        case .invalidResponse:  return "invalid response"
        case .responseError:    return "response error"
        case .noData:           return "no data"
        case .clientError:      return "client error"
        case .serverError:      return "server error"
        case .statusError:      return "status error"
        case .requestError:     return "request error"
        }
    }
}
