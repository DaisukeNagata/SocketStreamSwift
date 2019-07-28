//
//  SocketStreamProtocols.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2019/07/26.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

public protocol MessageInputDelegate { func sendMessage(message: String) }

public protocol SocketStreamDelegate: class { func receivedMessage(message: Message) }

public protocol ReadAndWriteToSocket: class {
    func read() ->Data?
    func stopStream()
    func streamUpdate()
    func write(_ data: Data)
    func dequeueWrite(_ data: Data)
    func sendMessage(_ message: String)
}

public protocol EroorUnconnected: class { func errorOccurred() }
