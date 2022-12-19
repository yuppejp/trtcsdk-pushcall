//
//  TrtcUserSig.swift
//  VideoSwiftUISample
//

import Foundation
import CommonCrypto
import zlib

let SDKAPPID: Int = MY_SDKAPPID
let SECRETKEY: String = MY_SECRETKEY
let EXPIRETIME: Int = 10 * 60 // seconds

class TrtcUserSig {
    
    class func genTestUserSig(identifier: String) -> String {
        let current = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970
        let TLSTime: CLong = CLong(floor(current))
        var obj: [String: Any] = [
            "TLS.ver": "2.0",
            "TLS.identifier": identifier,
            "TLS.sdkappid": SDKAPPID,
            "TLS.expire": EXPIRETIME,
            "TLS.time": TLSTime
        ]
        let keyOrder = [
            "TLS.identifier",
            "TLS.sdkappid",
            "TLS.time",
            "TLS.expire"
        ]
        var stringToSign = ""
        keyOrder.forEach { (key) in
            if let value = obj[key] {
                stringToSign += "\(key):\(value)\n"
            }
        }
        print("string to sign: \(stringToSign)")
        let sig = hmac(stringToSign)
        obj["TLS.sig"] = sig!
        print("sig: \(String(describing: sig))")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: obj, options: .sortedKeys) else { return "" }
        
        let bytes = jsonData.withUnsafeBytes { (result) -> UnsafePointer<Bytef> in
            return result.bindMemory(to: Bytef.self).baseAddress!
        }
        let srcLen: uLongf = uLongf(jsonData.count)
        let upperBound: uLong = compressBound(srcLen)
        let capacity: Int = Int(upperBound)
        let dest: UnsafeMutablePointer<Bytef> = UnsafeMutablePointer<Bytef>.allocate(capacity: capacity)
        var destLen = upperBound
        let ret = compress2(dest, &destLen, bytes, srcLen, Z_BEST_SPEED)
        if ret != Z_OK {
            print("[Error] Compress Error \(ret), upper bound: \(upperBound)")
            dest.deallocate()
            return ""
        }
        let count = Int(destLen)
        let result = self.base64URL(data: Data.init(bytesNoCopy: dest, count: count, deallocator: .free))
        return result
    }
    
    class func hmac(_ plainText: String) -> String? {
        let cKey = SECRETKEY.cString(using: String.Encoding.ascii)
        let cData = plainText.cString(using: String.Encoding.ascii)
        
        let cKeyLen = SECRETKEY.lengthOfBytes(using: .ascii)
        let cDataLen = plainText.lengthOfBytes(using: .ascii)
        
        var cHMAC = [CUnsignedChar].init(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        let pointer = cHMAC.withUnsafeMutableBufferPointer { (unsafeBufferPointer) in
            return unsafeBufferPointer
        }
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), cKey!, cKeyLen, cData, cDataLen, pointer.baseAddress)
        let data = Data.init(bytes: pointer.baseAddress!, count: cHMAC.count)
        return data.base64EncodedString(options: [])
    }
    
    class func base64URL(data: Data) -> String {
        let result = data.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        var final = ""
        result.forEach { (char) in
            switch char {
            case "+":
                final += "*"
            case "/":
                final += "-"
            case "=":
                final += "_"
            default:
                final += "\(char)"
            }
        }
        return final
    }
}
