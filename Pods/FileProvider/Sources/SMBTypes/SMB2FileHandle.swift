//
//  SMB2CreateClose.swift
//  ExtDownloader
//
//  Created by Amir Abbas Mousavian on 4/30/95.
//  Copyright © 1395 Mousavian. All rights reserved.
//

import Foundation

extension SMB2 {
    // MARK: SMB2 Create
    
    struct CreateRequest: SMBRequest {
        let header: CreateRequest.Header
        let name: String?
        let contexts: [CreateContext]
        
        init (header: CreateRequest.Header, name: String? = nil, contexts: [CreateContext] = []) {
            self.header = header
            self.name = name
            self.contexts = contexts
        }
        
        func data() -> NSData {
            var header = self.header
            var offset = 0x78 //UInt16(sizeof(SMB2.Header.self) + sizeof(CreateContext.Header.self) - 1)
            let body = NSMutableData()
            if let name = self.name, let nameData = name.dataUsingEncoding(NSUTF8StringEncoding) {
                header.nameOffset = UInt16(offset)
                header.nameLength = UInt16(nameData.length)
                offset += nameData.length
                body.appendData(nameData)
            }
            if contexts.count > 0 {
                // TODO: Context CreateRequest implementation, 8 bit allign offset
                header.contextOffset = UInt32(offset)
                
                
                header.contextLength = 0
                //result.appendData(nameData)
            }
            let result = NSMutableData(data: encode(&header))
            result.appendData(body)
            return result
        }
        
        struct Header {
            let size: UInt16
            private let securityFlags: UInt8
            private var _requestedOplockLevel: UInt8
            var requestedOplockLevel: OplockLevel {
                get {
                    return OplockLevel(rawValue: _requestedOplockLevel)!
                }
                set {
                    _requestedOplockLevel = newValue.rawValue
                }
            }
            private var _impersonationLevel: UInt32
            var impersonationLevel: ImpersonationLevel {
                get {
                    return ImpersonationLevel(rawValue: _impersonationLevel)!
                }
                set {
                    _impersonationLevel = newValue.rawValue
                }
            }
            private let flags: UInt64
            private let reserved: UInt64
            let access: FileAccessMask
            let fileAttributes: FileAttributes
            let shareAccess: ShareAccess
            private var _desposition: UInt32
            var desposition: CreateDisposition {
                get {
                    return CreateDisposition(rawValue: _desposition)!
                }
                set {
                    _desposition = newValue.rawValue
                }
            }
            let options: CreateOptions
            var nameOffset: UInt16
            var nameLength: UInt16
            var contextOffset: UInt32
            var contextLength: UInt32
            
            init(requestedOplockLevel: OplockLevel = .NONE, impersonationLevel: ImpersonationLevel = .Anonymous, access: FileAccessMask = [.GENERIC_ALL], fileAttributes: FileAttributes = [], shareAccess: ShareAccess = [.READ], desposition: CreateDisposition = .OPEN_IF, options: CreateOptions = []) {
                self.size = 57
                self.securityFlags = 0
                self._requestedOplockLevel = requestedOplockLevel.rawValue
                self._impersonationLevel = impersonationLevel.rawValue
                self.flags = 0
                self.reserved = 0
                self.access = access
                self.fileAttributes = fileAttributes
                self.shareAccess = shareAccess
                self._desposition = desposition.rawValue
                self.options = options
                self.nameOffset = 0
                self.nameLength = 0
                self.contextOffset = 0
                self.contextLength = 0
            }
        }
        
        struct CreateOptions: OptionSetType {
            let rawValue: UInt32
            
            init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            static let DIRECTORY_FILE               = CreateOptions(rawValue: 0x00000001)
            static let WRITE_THROUGH                = CreateOptions(rawValue: 0x00000002)
            static let SEQUENTIAL_ONLY              = CreateOptions(rawValue: 0x00000004)
            static let NO_INTERMEDIATE_BUFFERING    = CreateOptions(rawValue: 0x00000008)
            static let NON_DIRECTORY_FILE           = CreateOptions(rawValue: 0x00000040)
            static let NO_EA_KNOWLEDGE              = CreateOptions(rawValue: 0x00000200)
            static let RANDOM_ACCESS                = CreateOptions(rawValue: 0x00000800)
            static let DELETE_ON_CLOSE              = CreateOptions(rawValue: 0x00001000)
            static let OPEN_BY_FILE_ID              = CreateOptions(rawValue: 0x00002000)
            static let OPEN_FOR_BACKUP_INTENT       = CreateOptions(rawValue: 0x00004000)
            static let NO_COMPRESSION               = CreateOptions(rawValue: 0x00008000)
            static let OPEN_REPARSE_POINT           = CreateOptions(rawValue: 0x00200000)
            static let OPEN_NO_RECALL               = CreateOptions(rawValue: 0x00400000)
            private static let SYNCHRONOUS_IO_ALERT         = CreateOptions(rawValue: 0x00000010)
            private static let SYNCHRONOUS_IO_NONALERT      = CreateOptions(rawValue: 0x00000020)
            private static let COMPLETE_IF_OPLOCKED         = CreateOptions(rawValue: 0x00000100)
            private static let REMOTE_INSTANCE              = CreateOptions(rawValue: 0x00000400)
            private static let OPEN_FOR_FREE_SPACE_QUERY    = CreateOptions(rawValue: 0x00800000)
            private static let OPEN_REQUIRING_OPLOCK        = CreateOptions(rawValue: 0x00010000)
            private static let DISALLOW_EXCLUSIVE           = CreateOptions(rawValue: 0x00020000)
            private static let RESERVE_OPFILTER             = CreateOptions(rawValue: 0x00100000)
        }
        
        enum CreateDisposition: UInt32 {
            /// If the file already exists, supersede it. Otherwise, create the file.
            case SUPERSEDE      = 0x00000000
            /// If the file already exists, return success; otherwise, fail the operation.
            case OPEN           = 0x00000001
            /// If the file already exists, fail the operation; otherwise, create the file.
            case CREATE         = 0x00000002
            /// Open the file if it already exists; otherwise, create the file.
            case OPEN_IF        = 0x00000003
            /// Overwrite the file if it already exists; otherwise, fail the operation.
            case OVERWRITE      = 0x00000004
            /// Overwrite the file if it already exists; otherwise, create the file.
            case OVERWRITE_IF   = 0x00000005
        }
        
        enum ImpersonationLevel: UInt32 {
            case Anonymous = 0x00000000
            case Identification = 0x00000001
            case Impersonation = 0x00000002
            case Delegate = 0x00000003
        }
    }
    
    struct CreateResponse: SMBResponse {
        struct Header {
            let size: UInt16
            private let _oplockLevel: UInt8
            var oplockLevel: OplockLevel {
                return OplockLevel(rawValue: _oplockLevel)!
            }
            private let reserved: UInt32
            let creationTime: SMBTime
            let lastAccessTime: SMBTime
            let lastWriteTime: SMBTime
            let changeTime: SMBTime
            let allocationSize: UInt64
            let endOfFile: UInt64
            let fileAttributes: FileAttributes
            private let reserved2: UInt32
            let fileId: FileId
            let contextsOffset: UInt32
            let ContextsLength: UInt32
        }
        
        let header: CreateResponse.Header
        let contexts: [CreateContext]
        
        init? (data: NSData) {
            guard data.length >= sizeof(CreateResponse.Header.self) else {
                return nil
            }
            self.header = decode(data)
            if self.header.contextsOffset > 0 {
                var contexts = [CreateContext]()
                var contextOffset = Int(self.header.contextsOffset) - sizeof(SMB2.Header.self)
                while contextOffset > 0 {
                    guard contextOffset < data.length else {
                        self.contexts = contexts
                        return
                    }
                    let contextDataHeader = data.subdataWithRange(NSRange(location: contextOffset, length: sizeof(CreateContext.Header.self)))
                    if let lastContextHeader = CreateContext(data: contextDataHeader) {
                        let lastContextLen = Int(lastContextHeader.header.dataOffset) + Int(lastContextHeader.header.dataLength) - contextOffset
                        let lastContextData = data.subdataWithRange(NSRange(location: contextOffset, length: lastContextLen))
                        if let newContext = CreateContext(data: lastContextData) {
                            contexts.append(newContext)
                        }
                        contextOffset = Int(lastContextHeader.header.next) - sizeof(SMB2.Header.self)
                    }
                }
                self.contexts = contexts
            } else {
                self.contexts = []
            }
        }
    }
    
    struct CreateContext {
        struct Header {
            var next: UInt32
            let nameOffset: UInt16
            let nameLength: UInt16
            private let reserved: UInt16
            let dataOffset: UInt16
            let dataLength: UInt32
        }
        
        var header: CreateContext.Header
        let buffer: NSData
        
        init(name: ContextNames, data: NSData) {
            let nameData = NSMutableData(data: (name.rawValue).dataUsingEncoding(NSUTF8StringEncoding)!)
            self.header = CreateContext.Header(next: 0, nameOffset: 32, nameLength: UInt16(nameData.length), reserved: 0, dataOffset: UInt16(nameData.length), dataLength: UInt32(data.length))
            self.buffer = data
        }
        
        init(name: NSUUID, data: NSData) {
            var uuid = uuid_t(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
            name.getUUIDBytes(&uuid.0)
            let nameData = NSMutableData(bytes: &uuid, length: 16)
            self.header = CreateContext.Header(next: 0, nameOffset: 32, nameLength: UInt16(nameData.length), reserved: 0, dataOffset: UInt16(nameData.length), dataLength: UInt32(data.length))
            self.buffer = data
        }
        
        init? (data: NSData) {
            let headersize = sizeof(Header)
            guard data.length > headersize else {
                return nil
            }
            self.header = decode(data)
            self.buffer = data.subdataWithRange(NSRange(location: headersize, length: data.length - headersize))
        }
        
        func data() -> NSData {
            let result = NSMutableData(data: encode(header))
            result.appendData(buffer)
            return result
        }
        
        enum ContextNames: String {
            /// Request Create Context: Extended attributes
            case EA_BUFFER = "ExtA"
            /// Request Create Context: Security descriptor
            case SD_BUFFER = "SecD"
            /// Request & Response Create Context: Open to be durable
            case DURABLE_HANDLE = "DHnQ"
            case DURABLE_HANDLE_RESPONSE_V2 = "DH2Q"
            /// Request Create Context: Reconnect to a durable open after being disconnected
            case DURABLE_HANDLE_RECONNECT = "DHnC"
            /// Request Create Context: Required allocation size of the newly created file
            case ALLOCATION_SIZE = "AISi"
            /// Request & Response Create Context: Maximal access information
            case QUERY_MAXIMAL_ACCESS = "MxAc"
            case TIMEWARP_TOKEN = "TWrp"
            /// Response Create Context: DiskID of the open file in a volume.
            case QUERY_ON_DISK_ID = "QFid"
            /// Response Create Context: A lease. This value is only supported for the SMB 2.1 and 3.x dialect family.
            case LEASE = "RqLs"
        }
    }
    
    enum OplockLevel: UInt8 {
        case NONE = 0x00
        case LEVEL_II = 0x01
        case EXCLUSIVE = 0x08
        case BATCH = 0x09
        case LEASE = 0xFF
    }
    
    struct ShareAccess: OptionSetType {
        let rawValue: UInt32
        
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        static let READ     = ShareAccess(rawValue: 0x00000001)
        static let WRITE    = ShareAccess(rawValue: 0x00000002)
        static let DELETE   = ShareAccess(rawValue: 0x00000004)
    }
    
    struct FileAccessMask: OptionSetType {
        let rawValue: UInt32
        
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        // File and Printer/Pipe Accesses
        static let FILE_READ_DATA = FileAccessMask(rawValue: 0x00000001)
        static let FILE_WRITE_DATA = FileAccessMask(rawValue: 0x00000002)
        static let FILE_APPEND_DATA = FileAccessMask(rawValue: 0x00000004)
        static let FILE_EXECUTE = FileAccessMask(rawValue: 0x00000020)
        // Directory
        static let FILE_LIST_DIRECTORY = FileAccessMask(rawValue: 0x00000001)
        static let FILE_ADD_FILE = FileAccessMask(rawValue: 0x00000002)
        static let FILE_ADD_SUBDIRECTORY = FileAccessMask(rawValue: 0x00000004)
        static let FILE_TRAVERSE = FileAccessMask(rawValue: 0x00000020)
        // Generic
        static let FILE_READ_EA = FileAccessMask(rawValue: 0x00000008)
        static let FILE_WRITE_EA = FileAccessMask(rawValue: 0x00000010)
        static let FILE_DELETE_CHILD = FileAccessMask(rawValue: 0x00000040)
        static let FILE_READ_ATTRIBUTES = FileAccessMask(rawValue: 0x00000080)
        static let FILE_WRITE_ATTRIBUTES = FileAccessMask(rawValue: 0x00000100)
        static let DELETE = FileAccessMask(rawValue: 0x00010000)
        static let READ_CONTROL = FileAccessMask(rawValue: 0x00020000)
        static let WRITE_DAC = FileAccessMask(rawValue: 0x00040000)
        static let WRITE_OWNER = FileAccessMask(rawValue: 0x00080000)
        static let SYNCHRONIZE = FileAccessMask(rawValue: 0x00100000)
        static let ACCESS_SYSTEM_SECURITY = FileAccessMask(rawValue: 0x01000000)
        static let MAXIMUM_ALLOWED = FileAccessMask(rawValue: 0x02000000)
        static let GENERIC_ALL = FileAccessMask(rawValue: 0x10000000)
        static let GENERIC_EXECUTE = FileAccessMask(rawValue: 0x20000000)
        static let GENERIC_WRITE = FileAccessMask(rawValue: 0x40000000)
        static let GENERIC_READ = FileAccessMask(rawValue: 0x80000000)
    }
    
    struct FileAttributes: OptionSetType {
        let rawValue: UInt32
        
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        static let READONLY             = FileAttributes(rawValue: 0x00000001)
        static let HIDDEN               = FileAttributes(rawValue: 0x00000002)
        static let SYSTEM               = FileAttributes(rawValue: 0x00000004)
        static let DIRECTORY            = FileAttributes(rawValue: 0x00000010)
        static let ARCHIVE              = FileAttributes(rawValue: 0x00000020)
        static let NORMAL               = FileAttributes(rawValue: 0x00000080)
        static let TEMPORARY            = FileAttributes(rawValue: 0x00000100)
        static let SPARSE_FILE          = FileAttributes(rawValue: 0x00000200)
        static let REPARSE_POINT        = FileAttributes(rawValue: 0x00000400)
        static let COMPRESSED           = FileAttributes(rawValue: 0x00000800)
        static let OFFLINE              = FileAttributes(rawValue: 0x00001000)
        static let NOT_CONTENT_INDEXED  = FileAttributes(rawValue: 0x00002000)
        static let ENCRYPTED            = FileAttributes(rawValue: 0x00004000)
        static let INTEGRITY_STREAM     = FileAttributes(rawValue: 0x00008000)
        static let NO_SCRUB_DATA        = FileAttributes(rawValue: 0x00020000)
    }
    
    struct FileId {
        let persistent: UInt64
        let volatile: UInt64
    }
    
    // MARK: SMB2 Close
    
    struct CloseRequest: SMBRequest {
        let size: UInt16
        let flags: CloseFlags
        private let reserved2: UInt32
        let filePersistantId: UInt64
        let fileVolatileId: UInt64
        
        init(filePersistantId: UInt64, fileVolatileId: UInt64) {
            self.size = 24
            self.filePersistantId = filePersistantId
            self.fileVolatileId = fileVolatileId
            self.flags = []
            self.reserved2 = 0
        }
        
        func data() -> NSData {
            return encode(self)
        }
    }
    
    struct CloseResponse: SMBResponse {
        let size: UInt16
        let flags: CloseFlags
        private let reserved: UInt32
        let creationTime: SMBTime
        let lastAccessTime: SMBTime
        let lastWriteTime: SMBTime
        let changeTime: SMBTime
        let allocationSize: UInt64
        let endOfFile: UInt64
        let fileAttributes: FileAttributes
        
        init? (data: NSData) {
            self = decode(data)
        }
    }
    
    struct CloseFlags: OptionSetType {
        let rawValue: UInt16
        
        init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        static let POSTQUERY_ATTRIB = Flags(rawValue: 0x0001)
    }
    
    // MARK: SMB2 Flush
    
    struct FlushRequest: SMBRequest {
        let size: UInt16
        private let reserved: UInt16
        private let reserved2: UInt32
        let filePersistantId: UInt64
        let fileVolatileId: UInt64
        
        init(filePersistantId: UInt64, fileVolatileId: UInt64) {
            self.size = 24
            self.filePersistantId = filePersistantId
            self.fileVolatileId = fileVolatileId
            self.reserved = 0
            self.reserved2 = 0
        }
        
        func data() -> NSData {
            return encode(self)
        }
    }
    
    struct FlushResponse: SMBResponse {
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
}