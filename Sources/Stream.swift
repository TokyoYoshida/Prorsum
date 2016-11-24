//
//  Stream.swift
//  Prorsum
//
//  Created by Yuki Takei on 2016/11/25.
//
//

#if os(Linux)
    import Glibc
let sys_off_t = Glibc.off_t()
#else
    import Darwin.C
let sys_off_t = Darwin.off_t()
#endif

import Foundation
import Dispatch

let ioStreamQueue = DispatchQueue(label: "io.stream.prorsum", attributes: .concurrent)

public protocol ReadableStream: class {
    var socket: Socket { get }
    var io: DispatchIO { get }
    var isClosed: Bool { get set }
    func read() throws -> Bytes
}

public enum StreamResult<T> {
    case success(T)
    case end
    case error(Error)
}

extension ReadableStream {
    
    public func read() throws -> Bytes {
        let dataChan = Channel<Bytes>.make(capacity: 1)
        let doneChan = Channel<Void>.make(capacity: 1)
        let errorChan = Channel<Error>.make(capacity: 1)
        
        readAsync {
            switch $0 {
            case .success(let bytes):
                try! dataChan.send(bytes)
            case .error(let error):
                try! errorChan.send(error)
            case .end:
                try! doneChan.send()
            }
        }
        
        var bytes = Bytes()
        var error: Error?
        
        forSelect { [unowned self] done in
            when(dataChan) {
                bytes.append(contentsOf: $0)
            }
            
            when(doneChan) {
                self.isClosed = true
                done()
            }
            
            when(errorChan) {
                error = $0
                done()
            }
            
            if self.isClosed {
                done()
            }
        }
        
        if let error = error {
            throw error
        }
        
        return bytes
    }
    
    public func readAsync(upTo numOfBytes: Int = 1024,  _ completion: @escaping (StreamResult<Bytes>) -> Void) {
        let reader = DispatchIO(type: .stream, io: io, queue: .main) { _errorno in
            if let error = SystemError(errorNumber: _errorno) {
                completion(.error(error))
            }
        }
        
        reader.read(offset: sys_off_t, length: numOfBytes, queue: .main) { done, data, result in
            if let error = SystemError(errorNumber: result) {
                return completion(.error(error))
            }
            
            if let data = data, !data.isEmpty {
                data.enumerateBytes { buf, _, _ in
                    completion(.success(Array(buf)))
                }
            }
            
            if done, result == 0 {
                completion(.end)
            }
        }
    }
}

public protocol WritableStream {
    var io: DispatchIO { get }
    var isClosed: Bool { get }
    func write(_ bytes: Bytes) throws
}
