//
//  SocketStream.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2018/01/08.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

import CommonCrypto

public class SocketStream: NSObject {

    private let url: URL
    private let hostNumber: UInt32

    private var timer           : Timer?
    private var connected: Bool = false
    private var inputQueue      : [Data]?
    private var inputStream     : InputStream?
    private var outputStream    : OutputStream?
    private var mutableBuffer   : NSMutableData?

    private var compressionState = CompressionState()
    public weak var delegate     : SocketStreamDelegate?


    public init(url: URL, hostNumber: UInt32) {
        self.url        = url
        self.hostNumber = hostNumber
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changedAppStatus(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changedAppStatus(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    public func networkAccept() {
        guard let url = url.host else { return }

        var readStream : Unmanaged<CFReadStream>?
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
        
        if hostNumber == 443 {
            inputStream?.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: Stream.PropertyKey.socketSecurityLevelKey)
            outputStream?.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: Stream.PropertyKey.socketSecurityLevelKey)
            httpBodySetting()
        }
    }

    public func write(_ data: Data) {
        guard let outStream = outputStream else { return }
        let buffer = UnsafeRawPointer((data as NSData).bytes).assumingMemoryBound(to: UInt8.self)
        outStream.write(buffer, maxLength: data.count)
    }

    public func sendMessage(_ message: String) {
        let data = "\(message)".data(using: .utf8)
        _ = data?.withUnsafeBytes { _ in outputStream?.write(message, maxLength: message.utf8.count) }
    }

    public func cleanup() {
        if let stream = inputStream {
            stream.delegate = nil
            CFReadStreamSetDispatchQueue(stream, nil)
            stream.close()
        }
        if let stream = outputStream {
            stream.delegate = nil
            CFWriteStreamSetDispatchQueue(stream, nil)
            stream.close()
        }
        inputStream?.close()
        outputStream?.close()
    }

    public func dequeueWrite(_ data: Data) {
        self.timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(streamUpdate), userInfo: nil, repeats: true)
        dequeueWrite(data: data)
    }

    @objc public func streamUpdate() {
        cleanup()
        connected = false
        networkAccept()
    }

    @objc func changedAppStatus(_ notification: Notification) {
        if notification.name == UIApplication.didEnterBackgroundNotification {
             stopStream()
        } else if notification.name == UIApplication.willEnterForegroundNotification {
             streamUpdate()
        }
    }

    public func read() -> Data? {
        guard let stream = inputStream else {return nil}
        guard let buf = NSMutableData(capacity: Wss.maxReadLength) else {return nil}
        let buffer = UnsafeMutableRawPointer(mutating: buf.bytes).assumingMemoryBound(to: UInt8.self)
        let length = stream.read(buffer, maxLength: Wss.maxReadLength)
        if length < 1 { return nil }
        return Data(bytes: buffer, count: length)
    }
    
    public func stopStream() {
        inputStream?.close()
        outputStream?.close()
        self.timer?.invalidate()
    }

    private func httpBodySetting() {
        var request = URLRequest(url: url)
        request.setValue(url.absoluteString, forHTTPHeaderField: Wss.headerOrigin)
        request.setValue(Wss.headerUpgradeValue, forHTTPHeaderField: Wss.headerUpgrade)
        request.setValue(Wss.headerConnectionValue, forHTTPHeaderField: Wss.headerConnection)
        Wss.headerSecKey = generateWebSocketKey()
        request.setValue(Wss.headerVersionValue, forHTTPHeaderField: Wss.headerVersion)
        request.setValue(Wss.headerSecKey, forHTTPHeaderField: Wss.headerKey)

        let val = "permessage-deflate; client_max_window_bits; server_max_window_bits=15"
        request.setValue(val, forHTTPHeaderField: Wss.headerExtension)

        let hostValue = request.allHTTPHeaderFields?[Wss.headerHost] ?? "\(url.host!):\(hostNumber)"
        request.setValue(hostValue, forHTTPHeaderField: Wss.headerHost)

        var path = url.absoluteString
        let offset = (url.scheme?.count ?? 2) + 3
        path = String(path[path.index(path.startIndex, offsetBy: offset)..<path.endIndex])
        if let range = path.range(of: "/") {
            path = String(path[range.lowerBound..<path.endIndex])
        }

        var httpBody = "\(request.httpMethod ?? "GET") \(path) HTTP/1.1\r\n"
        if let headers = request.allHTTPHeaderFields {
            for (key, val) in headers {
                httpBody += "\(key): \(val)\r\n"
            }
        }
        httpBody += "\r\n"
        write(httpBody.data(using: .utf8)!)
    }

    private func generateWebSocketKey() -> String {
        let data = NSUUID().uuidString.data(using: String.Encoding.utf8)
        let baseKey = data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
        return baseKey
    }

    private func dequeueWrite(data: Data) {
        var offset = 2
        let firstByte: UInt8 = Wss.FinMask | Wss.textFrame
        
        let dataLength = data.count
        let frame = NSMutableData(capacity: dataLength + Wss.maxReadLength)
        
        let buffer = UnsafeMutableRawPointer(frame!.mutableBytes).assumingMemoryBound(to: UInt8.self)
        buffer[0] = firstByte
        buffer[1] = CUnsignedChar(dataLength)
        buffer[1] |= Wss.FinMask
        
        let maskKey = UnsafeMutablePointer<UInt8>(buffer + offset)
        _ = SecRandomCopyBytes(kSecRandomDefault, Int(MemoryLayout<UInt32>.size), maskKey)
        offset += MemoryLayout<UInt32>.size
        
        for i in 0..<dataLength {
            buffer[offset] = data[i] ^ maskKey[i % MemoryLayout<UInt32>.size]
            offset += 1
        }
        
        let writeBuffer = UnsafeRawPointer(frame!.bytes).assumingMemoryBound(to: UInt8.self)
        self.write(Data(bytes: writeBuffer, count: offset))
    }

    private func processInputStream() {
        let data = read()
        guard let d = data else { return }
        inputQueue = [Data]()
        inputQueue?.append(d)
        processDequeue()
    }

    private func processDequeue() {
        guard let data = inputQueue?[0] else { return }
        let buffer = UnsafeRawPointer((data as NSData).bytes).assumingMemoryBound(to: UInt8.self)
        guard connected == false else { processUnsafePointerInBuffer(buffer, bufferLen: data.count)
            return
        }
        processUnsafePointer(buffer, bufferLen: data.count)
    }

    private func processUnsafePointer(_ buffer: UnsafePointer<UInt8>, bufferLen: Int) {
        let code = processCheck(buffer, bufferLen: bufferLen)
        switch code {
        case 0 : break
        case -1: break
        default: break
        }
    }

    private func  processUnsafePointerInBuffer(_ pointer: UnsafePointer<UInt8>, bufferLen: Int) {
        let buffer = UnsafeBufferPointer(start: pointer, count: bufferLen)
        processOneRawMessage(inBuffer: buffer)
    }

    private func processCheck(_ buffer: UnsafePointer<UInt8>, bufferLen: Int) -> Int {
        if bufferLen > 0 {
            let code = processValidate(buffer, bufferLen: bufferLen)
            if code != 0 { return code }
            connected = true
            return 0
        }
        return -1
    }

    private func processValidate(_ buffer: UnsafePointer<UInt8>, bufferLen: Int) -> Int {
        guard let str = String(data: Data(bytes: buffer, count: bufferLen), encoding: .utf8) else { return -1 }
        let splitArr = str.components(separatedBy: "\r\n")
        var headers = [String: String]()

        splitArr.forEach { st in
            if st == "" {
                let responseSplit = st.components(separatedBy: .whitespaces)
                guard responseSplit.count > 1 else { return }
            } else {
                let responseSplit = st.components(separatedBy: ":")
                guard responseSplit.count > 1 else { return }
                let key = responseSplit[0].trimmingCharacters(in: .whitespaces)
                let val = responseSplit[1].trimmingCharacters(in: .whitespaces)
                headers[key.lowercased()] = val
            }
        }

        compressionState.decompressor = Decompressor()

        let sha = "\(Wss.headerSecKey)258EAFA5-E914-47DA-95CA-C5AB0DC85B11".sha1Base64()
        let acceptKey = headers[Wss.headerAccept.lowercased()]
        if sha != acceptKey ?? "" { return -1 }

        return 0
    }

    private func processOneRawMessage(inBuffer buffer: UnsafeBufferPointer<UInt8>) {
        guard let baseAddress = buffer.baseAddress else {return}
        let data: Data
        let offset = 2
        let len = (Wss.PayloadLenMask & baseAddress[1])

        do {
            data = try compressionState.decompressor?.decompress(bytes: baseAddress+offset, count: Int(len)) ?? Data()
        } catch {
            return
        }

        mutableBuffer = NSMutableData(data: data)
        _ = processResponse(mutableBuffer ?? NSMutableData())
        
    }

    private func processResponse(_ mutableBuffer: NSMutableData) {
        guard let str = String(data: mutableBuffer as Data, encoding: .utf8) else { return }
        delegate?.receivedMessage(message: Message(message: str))
    }

}

// MARK: StreamDelegate
extension SocketStream: StreamDelegate {

    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            if hostNumber == 443 {
                processInputStream()
            } else {
                readBytes(stream: aStream as? InputStream)
            }
        case Stream.Event.endEncountered: stopStream()
        case Stream.Event.errorOccurred: break
        case Stream.Event.hasSpaceAvailable: break
        default: break
        }
    }

}

extension SocketStream {

    private func readBytes(stream: InputStream? = nil) {

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Wss.maxReadLength)

        while stream?.hasBytesAvailable ?? false {

            let numberOfBytesRead = inputStream?.read(buffer, maxLength: Wss.maxReadLength)

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
