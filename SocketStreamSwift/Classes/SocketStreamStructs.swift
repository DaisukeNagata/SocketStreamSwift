//
//  SocketStreamStructs.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2019/07/26.
//

public struct Message {
    public let message: String
    init(message: String) { self.message = message.replacing() }
}

struct Wss {
    static let headerUpgrade         = "Upgrade"
    static let headerUpgradeValue    = "websocket"
    static let headerHost            = "Host"
    static let headerConnection      = "Connection"
    static let headerConnectionValue = "Upgrade"
    static let headerProtocol        = "Sec-WebSocket-Protocol"
    static let headerVersion         = "Sec-WebSocket-Version"
    static let headerVersionValue    = "13"
    static let headerExtension       = "Sec-WebSocket-Extensions"
    static let headerKey             = "Sec-WebSocket-Key"
    static let headerOrigin          = "Origin"
    static let headerAccept          = "Sec-WebSocket-Accept"
    static var headerSecKey          = ""
}

struct CompressionState {
    var serverMaxWindowBits = 15
    var decompressor:Decompressor? = nil
}
