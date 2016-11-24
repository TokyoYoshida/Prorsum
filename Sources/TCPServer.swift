//
//  TCPServer.swift
//  Prorsum
//
//  Created by Yuki Takei on 2016/11/25.
//
//

import Dispatch

public class TCPServer {
    let socket: TCP
    
    let handler: (TCP) -> Void
    
    var watcher: DispatchSourceRead?
    
    var isClosed: Bool {
        return socket.isClosed
    }
    
    public init(_ handler: @escaping (TCP) -> Void) throws {
        socket = try TCP()
        self.handler = handler
    }
    
    public func bind(host: String, port: UInt) throws {
        var reuseAddr = 1
        let r = setsockopt(
            socket.socket.fd,
            SOL_SOCKET,
            SO_REUSEADDR,
            &reuseAddr,
            socklen_t(MemoryLayout<Int>.stride)
        )
        
        if let error = SystemError(errorNumber: r) {
            throw error
        }
        
        try socket.bind(host: host, port: port)
    }
    
    public func listen(backlog: Int = 1024) throws {
        try socket.listen(backlog: backlog)
        
        watcher = DispatchSource.makeReadSource(fileDescriptor: socket.socket.fd, queue: .main)
        
        watcher?.setEventHandler { [unowned self] in
            var client: TCP?
            do {
                client = try self.socket.accept()
            } catch {
                print("\(error)")
                return
            }
            
            go {
                self.handler(client!)
            }
        }
        
        watcher?.resume()
        runLoop()
    }
    
    public func terminate(){
        watcher?.cancel()
        socket.close()
    }
}
