//
//  SocketStream.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2018/01/08.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func replacing() -> String {
        return self.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\0", with: "")
    }
}

public struct Message {
    public let message: String
    init(message: String) { self.message = message.replacing() }
}

public protocol MessageInputDelegate { func sendMessage(message: String) }

public protocol SocketStreamDelegate: class { func receivedMessage(message: Message) }

public protocol SocketToHost: class { var host: String {get}; var hostNumber: UInt32 {get} }

public class SocketStream: NSObject {

    public weak var socket: SocketToHost?
    public weak var delegate: SocketStreamDelegate?

    var inputStream: InputStream?
    var outputStream: OutputStream?

    let maxReadLength = 1024

    public func networkAccept() {
        guard  let soc = socket else { return }
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           soc.host as CFString,
                                           soc.hostNumber,
                                           &readStream,
                                           &writeStream)

        inputStream = readStream?.takeRetainedValue()
        outputStream = writeStream?.takeRetainedValue()

        inputStream?.delegate = self
        outputStream?.delegate = self

        inputStream?.schedule(in: .main, forMode: RunLoop.Mode.common)
        outputStream?.schedule(in: .main, forMode: RunLoop.Mode.common)

        inputStream?.open()
        outputStream?.open()

    }

    public func sendMessage(message: String) {
        let data = "\(message)".data(using: .utf8)
        _ = data?.withUnsafeBytes { _ in outputStream?.write(message, maxLength: message.utf8.count) }
    }

    func stopStream() {
        inputStream?.close()
        outputStream?.close()
    }
}

extension SocketStream: StreamDelegate {

    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable: readBytes(stream: aStream as? InputStream)
        case Stream.Event.endEncountered: stopStream()
        case Stream.Event.errorOccurred: break
        case Stream.Event.hasSpaceAvailable: break
        default: break
        }
    }

    private func readBytes(stream: InputStream? = nil) {

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)

        while stream?.hasBytesAvailable ?? false {

            let numberOfBytesRead = inputStream?.read(buffer, maxLength: maxReadLength)

            if numberOfBytesRead ?? 0 < 0 {
                if let _ = inputStream?.streamError { break }
            }

            if let message = processedAccpect(buffer: buffer, length: numberOfBytesRead ?? 0) { delegate?.receivedMessage(message: message) }
        }
    }

    private func processedAccpect(buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Message? {
        guard let stringArray = String(bytesNoCopy: buffer,
                                       length: length,
                                       encoding: .utf8,
                                       freeWhenDone: true)?.components(separatedBy: ":"),
            
            let message = stringArray.last else { return nil }
        return Message(message: message)
    }

}
