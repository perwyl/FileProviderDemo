//
//  SMB2FileOperation.swift
//  ExtDownloader
//
//  Created by Amir Abbas Mousavian on 4/30/95.
//  Copyright © 1395 Mousavian. All rights reserved.
//

import Foundation

extension SMB2 {
    // MARK: SMB2 Read
    
    struct ReadRequest: SMBRequest {
        let size: UInt16
        private let padding: UInt8
        let flags: ReadRequest.Flags
        let length: UInt32
        let offset: UInt64
        let fileId: FileId
        let minimumLength: UInt32
        private let _channel: UInt32
        var channel: Channel {
            return Channel(rawValue: _channel) ?? .NONE
        }
        let remainingBytes: UInt32
        private let channelInfoOffset: UInt16
        private let channelInfoLength: UInt16
        private let channelBuffer: UInt8
        
        init (fileId: FileId, offset: UInt64, length: UInt32, flags: ReadRequest.Flags = [], minimumLength: UInt32 = 0, remainingBytes: UInt32 = 0, channel: Channel = .NONE) {
            self.size = 49
            self.padding = 0
            self.flags = flags
            self.length = length
            self.offset = offset
            self.fileId = fileId
            self.minimumLength = minimumLength
            self._channel = channel.rawValue
            self.remainingBytes = remainingBytes
            self.channelInfoOffset = 0
            self.channelInfoLength = 0
            self.channelBuffer = 0
        }
        
        func data() -> NSData {
            return encode(read)
        }
        
        struct Flags: OptionSetType {
            let rawValue: UInt8
            
            init(rawValue: UInt8) {
                self.rawValue = rawValue
            }
            
            static let UNBUFFERED = Flags(rawValue: 0x01)
        }
    }
    
    struct ReadRespone: SMBResponse {
        struct Header {
            let size: UInt16
            let offset: UInt8
            private let reserved: UInt8
            let length: UInt32
            let remaining: UInt32
            private let reserved2: UInt32
            
        }
        let header: ReadRespone.Header
        let buffer: NSData
        
        init?(data: NSData) {
            guard data.length > 16 else {
                return nil
            }
            self.header = decode(data)
            let headersize = sizeof(Header)
            self.buffer = data.subdataWithRange(NSRange(location: headersize, length: data.length - headersize))
        }
    }
    
    enum Channel: UInt32 {
        case NONE                   = 0x00000000
        case RDMA_V1                = 0x00000001
        case RDMA_V1_INVALIDATE     =  0x00000002
    }
    
    // MARK: SMB2 Write
    
    struct WriteRequest: SMBRequest {
        let header: WriteRequest.Header
        let channelInfo: ChannelInfo?
        let fileData: NSData
        
        struct Header {
            let size: UInt16
            let dataOffset: UInt16
            let length: UInt32
            let offset: UInt64
            let fileId: FileId
            private let _channel: UInt32
            var channel: Channel {
                return Channel(rawValue: _channel) ?? .NONE
            }
            let remainingBytes: UInt32
            let channelInfoOffset: UInt16
            let channelInfoLength: UInt16
            let flags: WriteRequest.Flags
        }
        
        init(fileId: FileId, offset: UInt64, remainingBytes: UInt32 = 0, data: NSData, channel: Channel = .NONE, channelInfo: ChannelInfo? = nil, flags: WriteRequest.Flags = []) {
            var channelInfoOffset: UInt16 = 0
            var channelInfoLength: UInt16 = 0
            if channel != .NONE, let channelInfo = channelInfo {
                channelInfoOffset = UInt16(sizeof(SMB2.Header.self) + sizeof(WriteRequest.Header.self))
                channelInfoLength = UInt16(sizeof(channelInfo.dynamicType))
            }
            let dataOffset = UInt16(sizeof(SMB2.Header.self) + sizeof(WriteRequest.Header.self)) + channelInfoLength
            self.header = WriteRequest.Header(size: UInt16(49), dataOffset: dataOffset, length: UInt32(data.length), offset: offset, fileId: fileId, _channel: channel.rawValue, remainingBytes: remainingBytes, channelInfoOffset: channelInfoOffset, channelInfoLength: channelInfoLength, flags: flags)
            self.channelInfo = channelInfo
            self.fileData = data
        }
        
        func data() -> NSData {
            let result = NSMutableData(data: encode(self.header))
            if let channelInfo = channelInfo {
                result.appendData(channelInfo.data())
            }
            result.appendData(fileData)
            return result
        }
        
        struct Flags: OptionSetType {
            let rawValue: UInt32
            
            init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            static let THROUGH      = Flags(rawValue: 0x00000001)
            static let UNBUFFERED   = Flags(rawValue: 0x00000002)
        }
    }
    
    struct WriteResponse: SMBResponse {
        let size: UInt16
        private let reserved: UInt16
        let writtenBytes: UInt32
        private let remaining: UInt32
        private let channelInfoOffset: UInt16
        private let channelInfoLength: UInt16
        
        init?(data: NSData) {
            self = decode(data)
        }
    }
    
    struct ChannelInfo: SMBRequest {
        let offset: UInt64
        let token: UInt32
        let length: UInt32
        
        func data() -> NSData {
            return encode(data)
        }
    }
    
    // MARK: SMB2 Lock
    
    struct LockElement: SMBRequest {
        let offset: UInt64
        let length: UInt64
        let flags: LockElement.Flags
        private let reserved: UInt32
        
        func data() -> NSData {
            return encode(self)
        }
        
        struct Flags: OptionSetType {
            let rawValue: UInt32
            
            init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            static let SHARED_LOCK      = Flags(rawValue: 0x00000001)
            static let EXCLUSIVE_LOCK   = Flags(rawValue: 0x00000002)
            static let UNLOCK           = Flags(rawValue: 0x00000004)
            static let FAIL_IMMEDIATELY = Flags(rawValue: 0x00000010)
        }
    }
    
    struct LockRequest: SMBRequest {
        let header: LockRequest.Header
        let locks: [LockElement]
        
        init(fileId: FileId,locks: [LockElement], lockSequenceNumber : Int8 = 0, lockSequenceIndex: UInt32 = 0) {
            self.header = LockRequest.Header(size: 48, lockCount: UInt16(locks.count), lockSequence: UInt32(lockSequenceNumber << 28) + lockSequenceIndex, fileId: fileId)
            self.locks = locks
        }
        
        func data() -> NSData {
            let result = NSMutableData(data: encode(header))
            for lock in locks {
                result.appendData(encode(lock))
            }
            return result
        }
        
        struct Header {
            let size: UInt16
            private let lockCount: UInt16
            let lockSequence: UInt32
            let fileId : FileId
        }
    }
    
    struct LockResponse: SMBResponse {
        let size: UInt16
        let reserved: UInt16
        
        init() {
            self.size = 4
            self.reserved = 0
        }
        
        init? (data: NSData) {
            self = decode(data)
        }
    }
    
    // MARK: SMB2 Cancel
    
    struct CancelRequest: SMBRequest {
        let size: UInt16
        let reserved: UInt16
        
        init() {
            self.size = 4
            self.reserved = 0
        }
        
        func data() -> NSData {
            return encode(self)
        }
    }

}