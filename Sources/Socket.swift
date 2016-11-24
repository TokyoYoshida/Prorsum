//
//  Socket.swift
//  Prorsum
//
//  Created by Yuki Takei on 2016/11/24.
//
//

#if os(Linux)
    import Glibc
    public let sys_bind = Glibc.bind
    public let sys_accept = Glibc.accept
    public let sys_listen = Glibc.listen
    public let sys_connect = Glibc.connect
    public let sys_close = Glibc.close
    public let sys_socket = Glibc.socket
    
    public let SOCK_STREAM = Int32(Glibc.SOCK_STREAM.rawValue)
    public let SOCK_DGRAM = Int32(Glibc.SOCK_DGRAM.rawValue)
    public let SOCK_SEQPACKET = Int32(Glibc.SOCK_SEQPACKET.rawValue)
    public let SOCK_RAW = Int32(Glibc.SOCK_RAW.rawValue)
    public let SOCK_RDM = Int32(Glibc.SOCK_RDM.rawValue)
    public let SOCK_MAXADDRLEN: Int32 = 255
    public let IPPROTO_TCP = Int32(Glibc.IPPROTO_TCP)
#else
    import Darwin
    public let sys_bind = Darwin.bind
    public let sys_accept = Darwin.accept
    public let sys_listen = Darwin.listen
    public let sys_connect = Darwin.connect
    public let sys_close = Darwin.close
    public let sys_socket = Darwin.socket
    
    public let SOCK_STREAM = Darwin.SOCK_STREAM
    public let SOCK_DGRAM = Darwin.SOCK_DGRAM
    public let SOCK_SEQPACKET = Darwin.SOCK_SEQPACKET
    public let SOCK_RAW = Darwin.SOCK_RAW
    public let SOCK_RDM = Darwin.SOCK_RDM
    public let IPPROTO_TCP = Darwin.IPPROTO_TCP
    public let SOCK_MAXADDRLEN = Darwin.SOCK_MAXADDRLEN
#endif

import Foundation
import Dispatch

public typealias Byte = UInt8
public typealias Bytes = [Byte]

public enum SockType {
    case stream
    case dgram
    case seqPacket
    case raw
    case rdm
}

extension SockType {
    var rawValue: Int32 {
        switch self {
        case .stream:
            return SOCK_STREAM
        case .dgram:
            return SOCK_DGRAM
        case .seqPacket:
            return SOCK_SEQPACKET
        case .raw:
            return SOCK_RAW
        case .rdm:
            return SOCK_RDM
        }
    }
}

public enum AddressFamily {
    case unix
    case inet
    case inet6
    case ipx
    case netlink
}

extension AddressFamily {
    var rawValue: Int32 {
        switch self {
        case .unix:
            return AF_UNIX
        case .inet:
            return AF_INET
        case .inet6:
            return AF_INET6
        case .ipx:
            return AF_IPX
        case .netlink:
            return AF_APPLETALK
        }
    }
}

public class Socket {
    
    public let fd: Int32
    
    public let addressFamily: AddressFamily
    
    public let sockType: SockType
    
    public init(fd: Int32, addressFamily: AddressFamily, sockType: SockType){
        self.addressFamily = addressFamily
        self.sockType = sockType
        self.fd = fd
    }
    
    public init(addressFamily: AddressFamily, sockType: SockType) throws {
        self.addressFamily = addressFamily
        self.sockType = sockType
        fd = sys_socket(addressFamily.rawValue, sockType.rawValue, 0)
        guard fd >= 0 else {
            throw SystemError.lastOperationError!
        }
    }
    
    public func setNonBlocking() throws {
        let flags = fcntl(fd, F_GETFL, 0)
        let r = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
        if r < 0 {
            throw SystemError(errorNumber: r) ?? SystemError.other(errorNumber: r)
        }
    }
    
    public func close(){
        _ = sys_close(fd) // no error
    }
    
}
