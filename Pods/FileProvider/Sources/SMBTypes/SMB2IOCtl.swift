//
//  SMB2IOCtl.swift
//  ExtDownloader
//
//  Created by Amir Abbas Mousavian on 4/30/95.
//  Copyright © 1395 Mousavian. All rights reserved.
//

import Foundation

extension SMB2 {
    // MARK: SMB2 IOCTL
    
    /**
     * IOCtl usage is usually limited in SMB to pipe requests and duplicating file inside server
     */
    
    struct IOCtlRequest: SMBRequest {
        let header: Header
        let requestData:  IOCtlRequestProtocol?
        
        init(fileId: FileId ,ctlCode: IOCtlCode, requestData: IOCtlRequestProtocol?, flags: IOCtlRequest.Flags = []) {
            let offset = requestData != nil ? UInt32(sizeof(SMB2.Header.self) + sizeof(IOCtlRequest.Header.self)) : 0
            self.header = Header(size: 57, reserved: 0, _ctlCode: ctlCode.rawValue, fileId: fileId, inputOffset: offset, inputCount: UInt32((requestData?.data().length ?? 0)), maxInputResponse: 0, outputOffset: offset, outputCount: 0, maxOutputResponse: UInt32(Int32.max), flags: flags, reserved2: 0)
            self.requestData = requestData
        }
        
        func data() -> NSData {
            let result = NSMutableData(data: encode(self.header))
            if let reqData = requestData?.data() {
                result.appendData(reqData)
            }
            return result
        }
        
        struct Header {
            let size: UInt16
            private let reserved: UInt16
            private let _ctlCode: UInt32
            var ctlCode: IOCtlCode {
                return IOCtlCode(rawValue: _ctlCode)!
            }
            let fileId: FileId
            let inputOffset: UInt32
            let inputCount: UInt32
            let maxInputResponse: UInt32
            let outputOffset: UInt32
            let outputCount: UInt32
            let maxOutputResponse: UInt32
            let flags: IOCtlRequest.Flags
            private let reserved2: UInt32
        }
        
        struct Flags: OptionSetType {
            let rawValue: UInt32
            
            init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            static let IOCTL = Flags(rawValue: 0x00000000)
            static let FSCTL = Flags(rawValue: 0x00000001)
        }
    }
    
    struct IOCtlResponse: SMBResponse {
        let header: Header
        let responseData:  IOCtlResponseProtocol?
        
        init?(data: NSData) {
            self.header = decode(data)
            let responseRange = NSRange(location: Int(self.header.outputOffset - 64), length: Int(self.header.outputCount))
            let response = data.subdataWithRange(responseRange)
            switch self.header.ctlCode {
            case .SRV_COPYCHUNK, .SRV_COPYCHUNK_WRITE:
                self.responseData = IOCtlResponseData.SrvCopyChunk(data: response)
            case .SRV_ENUMERATE_SNAPSHOTS:
                self.responseData = IOCtlResponseData.SrvSnapshots(data: response)
            case .SRV_REQUEST_RESUME_KEY:
                self.responseData = IOCtlResponseData.ResumeKey(data: response)
            case .SRV_READ_HASH:
                self.responseData = IOCtlResponseData.ReadHash(data: response)
            case .QUERY_NETWORK_INTERFACE_INFO:
                self.responseData = IOCtlResponseData.NetworkInterfaceInfo(data: response)
            case .VALIDATE_NEGOTIATE_INFO:
                self.responseData = IOCtlResponseData.ValidateNegotiateInfo(data: response)
            default:
                self.responseData = nil
            }
        }
        
        struct Header {
            let size: UInt16
            private let reserved: UInt16
            private let _ctlCode: UInt32
            var ctlCode: IOCtlCode {
                return IOCtlCode(rawValue: _ctlCode)!
            }
            let fileId: FileId
            let inputOffset: UInt32
            let inputCount: UInt32
            let outputOffset: UInt32
            let outputCount: UInt32
            private let flags: UInt32
            private let reserved2: UInt32
        }
    }
    
    enum IOCtlCode: UInt32 {
        case DFS_GET_REFERRALS              = 0x00060194
        case DFS_GET_REFERRALS_EX           = 0x000601B0
        case SET_REPARSE_POINT              = 0x000900A4
        case FILE_LEVEL_TRIM                = 0x00098208
        case PIPE_PEEK                      = 0x0011400C
        case PIPE_WAIT                      = 0x00110018
        /// PIPE_TRANSCEIVE is valid only on a named pipe with mode set to FILE_PIPE_MESSAGE_MODE.
        case PIPE_TRANSCEIVE                = 0x0011C017
        /// Get ResumeKey used by the client to uniquely identify the source file in an FSCTL_SRV_COPYCHUNK or FSCTL_SRV_COPYCHUNK_WRITE request.
        case SRV_REQUEST_RESUME_KEY         = 0x00140078
        /// Get all the revision time-stamps that are associated with the Tree Connect share in which the open resides
        case SRV_ENUMERATE_SNAPSHOTS        = 0x00144064
        /// Reads a chunk of file for performing server side copy operations.
        case SRV_COPYCHUNK                  = 0x001440F2
        /// Retrieve data from the Content Information File associated with a specified file, not valid for the SMB 2.0.2 dialect.
        case SRV_READ_HASH                  = 0x001441BB
        /// Writes the chunk of file for performing server side copy operations.
        case SRV_COPYCHUNK_WRITE            = 0x001480F2
        /// Request resiliency for a specified open file, not valid for the SMB 2.0.2 dialect.
        case LMR_REQUEST_RESILIENCY         = 0x001401D4
        /// Get server network interface info e.g. link speed and socket address information
        case QUERY_NETWORK_INTERFACE_INFO   = 0x001401FC
        /// Request validation of a previous SMB 2 NEGOTIATE, valid for SMB 3.0 and SMB 3.0.2 dialects.
        case VALIDATE_NEGOTIATE_INFO        = 0x00140204
    }
    
    struct IOCtlRequestData {
        struct CopyChunk: IOCtlRequestProtocol {
            let sourceKey: (UInt64, UInt64, UInt64)
            let chunkCount: UInt32
            let chunks: [Chunk]
            
            func data() -> NSData {
                let result = NSMutableData(data: encode(sourceKey))
                result.appendData(encode(chunkCount))
                var reserved: UInt32 = 0
                result.appendData(encode(&reserved))
                return NSData()
            }
            
            struct Chunk {
                let sourceOffset: UInt64
                let targetOffset: UInt64
                let length: UInt32
                private let reserved: UInt32
                
                func data() -> NSData {
                    return encode(self)
                }
            }
        }
        
        struct ReadHash: IOCtlRequestProtocol {
            let _hashType: UInt32
            var hashType: IOCtlHashType {
                return IOCtlHashType(rawValue: _hashType) ?? .PEER_DIST
            }
            let _hashVersion: UInt32
            var hashVersion: IOCtlHashVersion {
                return IOCtlHashVersion(rawValue: _hashVersion) ?? .VER_1
            }
            let _hashRetrievalType: UInt32
            var hashRetrievalType: IOCtlHashRetrievalType {
                return IOCtlHashRetrievalType(rawValue: _hashRetrievalType) ?? .FILE_BASED
            }
            let length: UInt32
            let offset: UInt64
            
            init(offset: UInt64, length: UInt32, hashType: IOCtlHashType = .PEER_DIST, hashVersion: IOCtlHashVersion = .VER_1, hashRetrievalType: IOCtlHashRetrievalType = .FILE_BASED) {
                self._hashType = hashType.rawValue
                self._hashVersion = hashVersion.rawValue
                self._hashRetrievalType = hashRetrievalType.rawValue
                self.length = length
                self.offset = offset
            }
            
            func data() -> NSData {
                return encode(self)
            }
        }
        
        struct ResilencyRequest: IOCtlRequestProtocol {
            let timeout: UInt32
            private let reserved: UInt32
            
            /// The requested time the server holds the file open after a disconnect before releasing it. This time is in milliseconds.
            init(timeout: UInt32) {
                self.timeout = timeout
                self.reserved = 0
            }
            
            func data() -> NSData {
                return encode(self)
            }
        }
        
        struct ValidateNegotiateInfo: IOCtlRequestProtocol {
            let header: ValidateNegotiateInfo.Header
            let dialects: [UInt16]
            
            init(dialects: [UInt16], guid: uuid_t, capabilities: IOCtlCapabilities, securityMode: UInt16) {
                self.header = Header(capabilities: capabilities, guid: guid, securityMode: securityMode, dialectCount: UInt16(dialects.count))
                self.dialects = dialects
            }
            
            func data() -> NSData {
                let result = NSMutableData(data: encode(self.header))
                dialects.forEach { result.appendData(encode($0)) }
                return result
            }
            
            struct Header {
                let capabilities: IOCtlCapabilities
                /// Client's GUID
                let guid: uuid_t
                let securityMode: UInt16
                let dialectCount: UInt16
            }
        }
    }
    
    struct IOCtlResponseData {
        // SRV_COPYCHUNK, SRV_COPYCHUNK_WRITE
        struct SrvCopyChunk: IOCtlResponseProtocol {
            let chunksCount: UInt32
            let chunksBytesWritten: UInt32
            let totalBytesWriiten: UInt32
            
            init?(data: NSData) {
                self = decode(data)
            }
        }
        
        // SRV_ENUMERATE_SNAPSHOTS
        struct SrvSnapshots: IOCtlResponseProtocol {
            let count: UInt32
            let snapshots: [SMBTime]
            
            init?(data: NSData) {
                self.count = decode(data)
                let returnedCount: UInt32 = decode(data.subdataWithRange(NSRange(location: 4, length: 4)))
                //let size: UInt32 = decode(data.subdataWithRange(NSRange(location: 8, length: 4)))
                var snapshots = [SMBTime]()
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "'@GMT-'yyyy'.'MM'.'dd'-'HH'.'mm'.'ss"
                for i in 0..<Int(returnedCount) {
                    let offset = 24 + i * 48
                    if data.length < offset + 48 {
                        return nil
                    }
                    let datestring = String(data: data.subdataWithRange(NSRange(location: offset, length: 48)), encoding: NSUTF16StringEncoding)
                    if let datestring = datestring, let date = dateFormatter.dateFromString(datestring) {
                        snapshots.append(SMBTime(date: date))
                    }
                }
                self.snapshots = snapshots
            }
        }
        
        struct ResumeKey: IOCtlResponseProtocol {
            let key: (UInt64, UInt64, UInt64)
            private let contextLength: UInt32
            private let context: UInt32
            
            init?(data: NSData) {
                self = decode(data)
            }
        }
        
        struct ReadHash: IOCtlResponseProtocol {
            // TODO: Implement IOCTL READ_HASH
            
            init?(data: NSData) {
                self = decode(data)
            }
        }
        
        struct NetworkInterfaceInfo: IOCtlResponseProtocol {
            let items: [NetworkInterfaceInfo.Item]
            
            init?(data: NSData) {
                let count = data.length / sizeof(Item)
                guard count > 0 else {
                    return nil
                }
                var items = [Item]()
                for i in 0..<count {
                    let itemdata = data.subdataWithRange(NSRange(location: i * sizeof(Item), length: sizeof(Item)))
                    items.append(decode(itemdata))
                }
                self.items = items
            }
            
            struct Item {
                /// The offset, in bytes, from the beginning of this structure to the beginning of a subsequent 8-byte aligned network interface.
                let next: UInt32
                /// specifies the network interface index.
                let ifIndex: UInt32
                let capability: IOCtlCapabilities
                private let reserved: UInt32
                /// Speed of the network interface in bits per second
                let linkSpeed: UInt64
                private let sockaddrStorage:   (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
                var family: sa_family_t {
                    return sockaddrStorage.1
                }
                
                static let ipv4: sa_family_t = 0x02
                static let ipv6: sa_family_t = 0x17
                
                var sockaddr: sockaddr_in {
                    var sockaddrStorage = self.sockaddrStorage
                    let data = NSData(bytes: &sockaddrStorage, length: 16)
                    return decode(data)
                }
                
                var sockaddr6: sockaddr_in6 {
                    var sockaddrStorage = self.sockaddrStorage
                    let data = NSData(bytes: &sockaddrStorage, length: 28)
                    return decode(data)
                }
            }
        }
        
        struct ValidateNegotiateInfo: IOCtlResponseProtocol {
            let capabilities: IOCtlCapabilities
            let guid: uuid_t
            let securityMode: UInt16
            private let _dialect: UInt16
            var dialect: (major: Int, minor: Int) {
                return (major: Int(_dialect & 0xFF), minor: Int(_dialect >> 8))
            }
            
            init?(data: NSData) {
                self = decode(data)
            }
        }
    }
    
    struct IOCtlCapabilities: OptionSetType {
        let rawValue: UInt32
        
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        static let RSS_CAPABLE  = IOCtlCapabilities(rawValue: 0x00000001)
        static let RDMA_CAPABLE = IOCtlCapabilities(rawValue: 0x00000002)
    }
    
    enum IOCtlHashType: UInt32 {
        case PEER_DIST = 0x00000001
    }
    
    enum IOCtlHashVersion: UInt32 {
        case VER_1 = 0x00000001
        case VER_2 = 0x00000002
    }
    
    enum IOCtlHashRetrievalType: UInt32 {
        case HASH_BASED = 0x00000001
        case FILE_BASED = 0x00000002
    }
}