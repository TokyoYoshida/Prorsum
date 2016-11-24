//
//  TCP.swift
//  Prorsum
//
//  Created by Yuki Takei on 2016/11/25.
//
//


#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Dispatch

public class TCP: ReadableStream {
    
    public let socket: Socket
    
    public var isClosed = false
    
    public let io: DispatchIO
    
    public init(socket: Socket) throws {
        self.socket = socket
        try socket.setNonBlocking()
        io = DispatchIO(type: .stream, fileDescriptor: socket.fd, queue: ioStreamQueue) { _errorno in
            if let error = SystemError(errorNumber: _errorno) {
                fatalError("\(error)")
            }
        }
    }
    
    public convenience init(addressFamily: AddressFamily = .inet) throws {
        try self.init(socket: Socket(addressFamily: addressFamily, sockType: .stream))
    }
    
    public func accept() throws -> TCP {
        var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let addr = UnsafeMutablePointer<sockaddr_storage>.allocate(capacity: 1)
        let addrSockAddr = UnsafeMutablePointer<sockaddr>(OpaquePointer(addr))
        defer {
            addr.deallocate(capacity: 1)
        }
        
        let fd = sys_accept(socket.fd, addrSockAddr, &length)
        guard fd > -1 else {
            throw SystemError.lastOperationError!
        }
        
        let client = Socket(fd: fd, addressFamily: socket.addressFamily, sockType: socket.sockType)
        return try TCP(socket: client)
    }
    
    public func bind(host: String, port: UInt) throws {
        var addrInfoRef: UnsafeMutablePointer<addrinfo>?
        var hints = addrinfo(
            ai_flags: AI_PASSIVE,
            ai_family: socket.addressFamily.rawValue,
            ai_socktype: socket.sockType.rawValue,
            ai_protocol: IPPROTO_TCP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )
        
        if let error = SystemError(errorNumber: getaddrinfo(host, String(port), &hints, &addrInfoRef)) {
            throw error
        }
        
        guard let addrInfo = addrInfoRef?.pointee else {
            fatalError("addrInfo is empty")
        }
        
        let r = sys_bind(socket.fd, addrInfo.ai_addr, socklen_t(MemoryLayout<sockaddr>.size))
        freeaddrinfo(addrInfoRef)
        
        if r != 0 {
            throw SystemError.lastOperationError!
        }
    }
    
    public func listen(backlog: Int = 1024) throws {
        let r = sys_listen(socket.fd, Int32(backlog))
        if r != 0 {
            throw SystemError.lastOperationError!
        }
    }
    
    public func close(){
        io.close()
        socket.close()
        self.isClosed = true
    }
}
