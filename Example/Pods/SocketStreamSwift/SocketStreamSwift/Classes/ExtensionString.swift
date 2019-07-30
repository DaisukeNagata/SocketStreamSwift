//
//  ExtensionString.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2019/07/26.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

import CommonCrypto

 extension String {

    func replacing() -> String {
        return self.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\0", with: "")
    }

    func sha1Base64() -> String {
        var data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data.init(digest).base64EncodedString()
    }
    
    func generateWebSocketKey() -> String {
        let data = NSUUID().uuidString.data(using: String.Encoding.utf8)
        let baseKey = data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
        return baseKey
    }
}
