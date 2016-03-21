//
//  Socket.swift
//  Socket
//
//  Created by LEI on 3/21/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#if os(Linux)
    import Glibc
    private let CLOSE = Glibc.close
    private let READ = Glibc.read
#else
    import Darwin
    private let CLOSE = Darwin.close
    private let READ = Darwin.read
    private let WRITE = Darwin.write
#endif

enum SocketFamily {
    case IPv4
    case IPv6
    
    var raw: Int32 {
        switch self {
        case .IPv4:
            return AF_INET
        case .IPv6:
            return AF_INET6
        }
    }
}

public enum SocketProtocol {
    case TCP
    case UDP
    
    var rawStreamValue: Int32 {
        switch self {
        case .TCP:
            return SOCK_STREAM
        case .UDP:
            return SOCK_DGRAM
        }
    }
    
    var rawProtocolValue: Int32 {
        switch self {
        case .TCP:
            return IPPROTO_TCP
        case .UDP:
            return IPPROTO_UDP
        }
    }
}


protocol SocketType {

    var fd: FileDescriptor { get }
    
}

enum SocketError: ErrorType {
    case NativeError(Int32, String)
    
    static func fromErrno() -> SocketError {
        return SocketError.NativeError(errno, String.fromCString(strerror(errno)) ?? "")
    }
}


class Socket: SocketType {
    
    var fd: FileDescriptor
    let family: SocketFamily
    let proto: SocketProtocol
    
    init(family: SocketFamily, proto: SocketProtocol) {
        self.family = family
        self.proto = proto
        self.fd = FileDescriptor(socket(self.family.raw, self.proto.rawStreamValue, self.proto.rawProtocolValue))
    }

}

extension Socket: Readable {
    
    func read(size: Int) throws -> [Byte] {
        let buffer = UnsafeMutablePointer<Byte>.alloc(size)
        defer {
            buffer.dealloc(size)
        }
        let res = READ(fd.raw, buffer, size)
        guard res >= 0 else {
            throw SocketError.fromErrno()
        }
        var data = [Byte](count: size, repeatedValue: 0)
        memcpy(&data, buffer, data.count)
        return data
    }
    
}

extension Socket: Writable {
    
    func write(buffer: [Byte]) throws {
        let res = WRITE(fd.raw, buffer, buffer.count)
        guard res >= 0 else {
            throw SocketError.fromErrno()
        }
    }

}

extension Socket: Closable {
    
    func close() throws {
        CLOSE(fd.raw)
        fd = nil
    }
    
}
