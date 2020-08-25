//
//  Decompressor.swift
//  SwiftOnWebSocket
//
//  Created by 永田大祐 on 2019/07/27.
//  Copyright © 2018年 永田大祐. All rights reserved.
//

import Foundation
import zlib

class Decompressor {

    private var strm = z_stream()
    private var buffer = [UInt8](repeating: 0, count: 0x2000)
    private var compressionState = CompressionState()

    init?() {
        inflateInit2_(&strm, -CInt(compressionState.serverMaxWindowBits), ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))

    }


    func decompress(bytes: UnsafePointer<UInt8>, count: Int) throws -> Data {
        var decompressed = Data()
        try decompress(bytes: bytes, count: count, out: &decompressed)
        let tail:[UInt8] = [0x00, 0x00, 0xFF, 0xFF]
        try decompress(bytes: tail, count: tail.count, out: &decompressed)

        return decompressed
    }

    private func decompress(bytes: UnsafePointer<UInt8>, count: Int, out:inout Data) throws {

        strm.next_in = UnsafeMutablePointer<UInt8>(mutating: bytes)
        strm.avail_in = CUnsignedInt(count)

        strm.next_out = UnsafeMutablePointer<UInt8>(mutating: buffer)
        strm.avail_out = CUnsignedInt(buffer.count)

        let res = inflate(&strm, 0)
        guard res == Z_OK else { return }

        let byteCount = buffer.count - Int(strm.avail_out)
        out.append(buffer, count: byteCount)
    }

}
