//
//  SocketStream.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2018/01/08.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

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

public class SocketStream: NSObject {

    let url: URL
    let hostNumber: UInt32


    public init(url: URL, hostNumber: UInt32) {
        self.url = url
        self.hostNumber = hostNumber
        super.init()
    }

    public weak var delegate: SocketStreamDelegate?

    private let maxReadLength = 4096
    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    public func networkAccept() {

        guard let url = url.host else { return }
    
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           url as CFString,
                                           hostNumber,
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

    private func stopStream() {
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
