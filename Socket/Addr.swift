//
//  Addr.swift
//  Socket
//
//  Created by LEI on 3/22/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

typealias Port = UInt16

protocol SockAddrType {
    var general: sockaddr { get }
}

extension sockaddr_in: SockAddrType {
    var general: sockaddr {
        var addr: sockaddr_in = self
        return withUnsafePointer(&addr) {
            return UnsafePointer<sockaddr>($0).memory
        }
    }

}

extension sockaddr_in6: SockAddrType {
    var general: sockaddr {
        var addr: sockaddr_in6 = self
        return withUnsafePointer(&addr) {
            return UnsafePointer<sockaddr>($0).memory
        }
    }
}

extension sockaddr: SockAddrType {
    var general: sockaddr {
        return self
    }
}

protocol SockInAddrType {
    init()
}

extension in_addr: SockInAddrType {
    
}

extension in6_addr: SockInAddrType {
    
}

enum AddrError: ErrorType {
    case InetNtopError
}

protocol IPType {
    var host: String { get }
    var port: Port { get }
    static var rawFamilyValue: Int32 { get }
    static var sockInAddrType: SockInAddrType.Type { get }
}

extension IPType {
    
    var sockAddr: SockAddrType! {
        switch Self.rawFamilyValue {
        case AF_INET:
            var sin = sockaddr_in()
            sin.sin_family = UInt8(Self.rawFamilyValue)
            sin.sin_port = htons(port)
            sin.sin_addr = pton(self.dynamicType, host: host) as! in_addr
            return sin
        case AF_INET6:
            var sin = sockaddr_in6()
            sin.sin6_family = UInt8(Self.rawFamilyValue)
            sin.sin6_port = htons(port)
            sin.sin6_addr = pton(self.dynamicType, host: host) as! in6_addr
            return sin
        default:
            return nil
        }
    }

    
}

struct IPv4: IPType {
    
    var host: String
    
    var port: Port = 0
    
    static let rawFamilyValue: Int32 = AF_INET
    
    static let sockInAddrType: SockInAddrType.Type = in_addr.self
    
    init(host: String, port: Port) {
        self.host = host
        self.port = port
    }
}

struct IPv6: IPType {
    
    var host: String
    
    var port: Port = 0
    
    static let rawFamilyValue: Int32 = AF_INET6
    
    static let sockInAddrType: SockInAddrType.Type = in6_addr.self

    init(host: String, port: Port) {
        self.host = host
        self.port = port
    }
}

struct Addr<T: IPType> {
    
    var ip: T
    var port: Port
    
    init(ip: T, port: Port) {
        self.ip = ip
        self.port = port
    }
    
}


// ByteOrder

let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian

public let htons  = isLittleEndian ? _OSSwapInt16 : { $0 }
public let htonl  = isLittleEndian ? _OSSwapInt32 : { $0 }
public let htonll = isLittleEndian ? _OSSwapInt64 : { $0 }
public let ntohs  = isLittleEndian ? _OSSwapInt16 : { $0 }
public let ntohl  = isLittleEndian ? _OSSwapInt32 : { $0 }
public let ntohll = isLittleEndian ? _OSSwapInt64 : { $0 }

// Utils

func pton<T: IPType>(type: T.Type, host: String) -> SockInAddrType {
    var inAddr: SockInAddrType = T.sockInAddrType.init()
    let addrPtr: UnsafeMutablePointer<Void> = withUnsafePointer(&inAddr) {
        return UnsafeMutablePointer($0)
    }
    if host.withCString({ cstring in inet_pton(T.rawFamilyValue, cstring, addrPtr) }) == 1 {
        // ip address
    }else{
        // TODO: network interface
    }
    return inAddr
}

func ntop<T: IPType>(type: T.Type, addr: SockAddrType) throws -> String {
    var addressString = [CChar](count:Int(INET_ADDRSTRLEN), repeatedValue: 0)
    var sockAddr = addr
    let res = withUnsafePointer(&sockAddr) {
        return inet_ntop(Int32(T.rawFamilyValue), UnsafePointer<Void>($0), &addressString, socklen_t(INET_ADDRSTRLEN))
    }
    guard res != nil else {
        throw AddrError.InetNtopError
    }
    guard let host = String.fromCString(addressString) else {
        throw AddrError.InetNtopError
    }
    return host
}
