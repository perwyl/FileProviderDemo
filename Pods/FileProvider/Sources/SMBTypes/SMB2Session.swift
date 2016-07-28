//
//  SMB2NegotiationTypes.swift
//  ExtDownloader
//
//  Created by Amir Abbas Mousavian on 4/30/95.
//  Copyright © 1395 Mousavian. All rights reserved.
//

import Foundation

extension SMB2 {
    // MARK: SMB2 Negotiating
    
    struct NegotiateRequest: SMBRequest {
        let request: NegotiateRequest.Header
        let dialects: [UInt16]
        let contexts: [(type: NegotiateContextType, data: NSData)]
        
        init(request: NegotiateRequest.Header, dialects: [UInt16] = [0x0202], contexts: [(type: NegotiateContextType, data: NSData)] = []) {
            self.request = request
            self.dialects = dialects
            self.contexts = contexts
        }
        
        func data() -> NSData {
            var request = self.request
            request.dialectCount = UInt16(dialects.count)
            let dialectData = NSMutableData()
            for dialect in dialects {
                var dialect = dialect
                dialectData.appendBytes(&dialect, length: 2)
            }
            let pad = ((1024 - dialectData.length) % 8)
            dialectData.increaseLengthBy(pad)
            request.contextOffset = UInt32(sizeof(request.dynamicType.self)) + UInt32(dialectData.length)
            request.contextCount = UInt16(contexts.count)
            
            let contextData = NSMutableData()
            for context in contexts {
                var contextType = context.type.rawValue
                contextData.appendBytes(&contextType, length: 2)
                var dataLen = UInt16(context.data.length)
                contextData.increaseLengthBy(4)
                contextData.appendBytes(&dataLen, length: 2)
            }
            let result = NSMutableData(data: encode(&request))
            result.appendData(dialectData)
            result.appendData(contextData)
            return result
        }
        
        struct Header {
            var size: UInt16
            var dialectCount: UInt16
            let singing: NegotiateSinging
            private let reserved: UInt16
            let capabilities: GlobalCapabilities
            let guid: uuid_t
            var contextOffset: UInt32
            var contextCount: UInt16
            private let reserved2: UInt16
            var clientStartTime: SMBTime {
                let time = UInt64(contextOffset) + (UInt64(contextCount) << 32) + (UInt64(contextCount) << 48)
                return SMBTime(time: time)
            }
            
            init(singing: NegotiateSinging = [.ENABLED], capabilities: GlobalCapabilities, guid: uuid_t? = nil, clientStartTime: SMBTime? = nil) {
                self.size = 36
                self.dialectCount = 0
                self.singing = singing
                self.reserved = 0
                self.capabilities = capabilities
                self.guid = guid ?? (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                if let clientStartTime = clientStartTime {
                    let time = clientStartTime.time
                    self.contextOffset = UInt32(time & 0xffffffff)
                    self.contextCount = UInt16(time & 0x0000ffff00000000 >> 32)
                    self.reserved2 = UInt16(time >> 48)
                } else {
                    self.contextOffset = 0
                    self.contextCount = 0
                    self.reserved2 = 0
                }
            }
        }
    }
    
    struct NegotiateResponse: SMBResponse {
        let header: NegotiateResponse.Header
        let buffer: NSData?
        let contexts: [(type: NegotiateContextType, data: NSData)]
        
        init? (data: NSData) {
            if data.length < 64 {
                return nil
            }
            self.header = decode(data)
            if Int(header.size) != 65 {
                return nil
            }
            let bufOffset = Int(self.header.bufferOffset) - sizeof(SMB2.Header.self)
            let bufLen = Int(self.header.bufferLength)
            if bufOffset > 0 && bufLen > 0 && data.length >= bufOffset + bufLen {
                self.buffer = data.subdataWithRange(NSRange(location: bufOffset, length: bufLen))
            } else {
                self.buffer = nil
            }
            let contextCount = Int(self.header.contextCount)
            let contextOffset = Int(self.header.contextOffset) - sizeof(SMB2.Header.self)
            if  contextCount > 0 &&  contextOffset > 0 {
                // TODO: NegotiateResponse context support for SMB3
                self.contexts = []
            } else {
                self.contexts = []
            }
        }
        
        struct Header {
            let size: UInt16
            let singing: NegotiateSinging
            let dialect: UInt16
            let contextCount: UInt16
            let serverGuid: uuid_t
            let capabilities: GlobalCapabilities
            let maxTransactSize: UInt32
            let maxReadSize: UInt32
            let maxWriteSize: UInt32
            let systemTime: SMBTime
            let serverStartTime: SMBTime
            let bufferOffset: UInt16
            let bufferLength: UInt16
            let contextOffset: UInt32
        }
    }
    
    struct NegotiateSinging: OptionSetType {
        let rawValue: UInt16
        
        init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        static let ENABLED   = NegotiateSinging(rawValue: 0x0001)
        static let REQUIRED  = NegotiateSinging(rawValue: 0x0002)
    }
    
    struct NegotiateContextType: OptionSetType {
        let rawValue: UInt16
        
        init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        static let PREAUTH_INTEGRITY_CAPABILITIES   = NegotiateContextType(rawValue: 0x0001)
        static let ENCRYPTION_CAPABILITIES          = NegotiateContextType(rawValue: 0x0002)
    }
    
    struct GlobalCapabilities: OptionSetType {
        let rawValue: UInt32
        
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        static let DFS                  = GlobalCapabilities(rawValue: 0x00000001)
        static let LEASING              = GlobalCapabilities(rawValue: 0x00000002)
        static let LARGE_MTU            = GlobalCapabilities(rawValue: 0x00000004)
        static let MULTI_CHANNEL        = GlobalCapabilities(rawValue: 0x00000008)
        static let PERSISTENT_HANDLES   = GlobalCapabilities(rawValue: 0x00000010)
        static let DIRECTORY_LEASING    = GlobalCapabilities(rawValue: 0x00000020)
        static let ENCRYPTION           = GlobalCapabilities(rawValue: 0x00000040)
    }
    
    // MARK: SMB2 Session Setup
    
    struct SessionSetupRequest: SMBRequest {
        let header: SessionSetupRequest.Header
        let buffer: NSData?
        
        init(header: SessionSetupRequest.Header, buffer: NSData) {
            self.header = header
            self.buffer = buffer
        }
        
        func data() -> NSData {
            var header = self.header
            header.bufferOffset = UInt16(sizeof(SMB2.Header.self) + sizeof(SessionSetupRequest.Header.self))
            header.bufferLength = UInt16(buffer?.length ?? 0)
            let result = NSMutableData(data: encode(&header))
            if let buffer = self.buffer {
                result.appendData(buffer)
            }
            return result
        }
        
        struct Header {
            let size: UInt16
            let flags: SessionSetupRequest.Flags
            let signing: SessionSetupSinging
            let capabilities: GlobalCapabilities
            private let channel: UInt32
            var bufferOffset: UInt16
            var bufferLength: UInt16
            let sessionId: UInt64
            
            init(sessionId: UInt64, flags: SessionSetupRequest.Flags = [], singing: SessionSetupSinging, capabilities: GlobalCapabilities) {
                self.size = 25
                self.flags = flags
                self.signing = singing
                self.capabilities = capabilities
                self.channel = 0
                self.bufferOffset = 0
                self.bufferLength = 0
                self.sessionId = sessionId
            }
        }
        
        /// Works the client implements the SMB 3.x dialect family
        struct Flags: OptionSetType {
            let rawValue: UInt8
            
            init(rawValue: UInt8) {
                self.rawValue = rawValue
            }
            
            static let BINDING = NegotiateSinging(rawValue: 0x01)
        }
    }
    
    struct SessionSetupResponse: SMBResponse {
        let header: SessionSetupResponse.Header
        let buffer: NSData?
        
        init? (data: NSData) {
            if data.length < 64 {
                return nil
            }
            self.header = decode(data)
            if Int(header.size) != 9 {
                return nil
            }
            let bufOffset = Int(self.header.bufferOffset) - sizeof(SMB2.Header.self)
            let bufLen = Int(self.header.bufferLength)
            if bufOffset > 0 && bufLen > 0 && data.length >= bufOffset + bufLen {
                self.buffer = data.subdataWithRange(NSRange(location: bufOffset, length: bufLen))
            } else {
                self.buffer = nil
            }
        }
        
        struct Header {
            let size: UInt16
            let flags: SessionSetupResponse.Flags
            let bufferOffset: UInt16
            let bufferLength: UInt16
        }
        
        struct Flags: OptionSetType {
            let rawValue: UInt16
            
            init(rawValue: UInt16) {
                self.rawValue = rawValue
            }
            
            static let IS_GUEST     = Flags(rawValue: 0x0001)
            static let IS_NULL      = Flags(rawValue: 0x0002)
            static let ENCRYPT_DATA = Flags(rawValue: 0x0004)
        }
    }
    
    struct SessionSetupSinging: OptionSetType {
        let rawValue: UInt8
        
        init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        static let ENABLED   = NegotiateSinging(rawValue: 0x01)
        static let REQUIRED  = NegotiateSinging(rawValue: 0x02)
    }
    
    // MARK: SMB2 Log off
    
    struct LogOff: SMBRequest, SMBResponse {
        let size: UInt16
        let reserved: UInt16
        
        init() {
            self.size = 4
            self.reserved = 0
        }
        
        init? (data: NSData) {
            self = decode(data)
        }
        
        func data() -> NSData {
            return encode(self)
        }
    }
    
    // MARK: SMB2 Echo
    
    struct Echo: SMBRequest, SMBResponse {
        let size: UInt16
        let reserved: UInt16
        
        init() {
            self.size = 4
            self.reserved = 0
        }
        
        init? (data: NSData) {
            self = decode(data)
        }
        
        func data() -> NSData {
            return encode(self)
        }
    }
}