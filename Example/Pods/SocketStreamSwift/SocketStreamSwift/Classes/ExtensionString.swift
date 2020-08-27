//
//  ExtensionString.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2019/07/26.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

import CommonCrypto

class Digest {
    var set = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
}

 extension String {

    func replacing() -> String {
        return self.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\0", with: "")
    }

    func sha1Base64() -> String {
        let xInstance = Digest()
        self.data(using: String.Encoding.utf8)?.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(self.data(using: String.Encoding.utf8)?.count ?? 0), &xInstance.set)
        }
        return Data.init(xInstance.set).base64EncodedString()
    }
    
    func generateWebSocketKey() -> String {
        return NSUUID().uuidString.data(using: String.Encoding.utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
    }
}
