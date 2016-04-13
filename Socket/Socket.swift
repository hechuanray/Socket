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
    private let SEND = Darwin.send
    private let CLOSE = Darwin.close
    private let RECV = Darwin.recv
    private let ERRNO = Darwin.errno
    private let BIND = Darwin.bind
    private let LISTEN = Darwin.listen
    private let ACCEPT = Darwin.accept
#endif


protocol SocketProtocolType {
    static var rawStreamValue: Int32 { get }
    static var rawProtocolValue: Int32  { get }
    init()
}

struct TCP: SocketProtocolType {
    
    static var rawStreamValue: Int32 {
        return SOCK_STREAM
    }
    
    static var rawProtocolValue: Int32 {
        return IPPROTO_TCP
    }
    
}

struct UDP: SocketProtocolType {
    
    static var rawStreamValue: Int32 {
        return SOCK_DGRAM
    }
    
    static var rawProtocolValue: Int32 {
        return IPPROTO_UDP
    }
    
}

protocol SocketType: Readable, Writable, Closable {

    var fd: FileDescriptorType { get }
    
}

enum SocketError: ErrorType {
    case NativeError(Int32, String)
    case UnkownProtocolType()

    static func errno() -> SocketError {
        return SocketError.NativeError(ERRNO, String.fromCString(strerror(ERRNO)) ?? "")
    }
}

typealias TCPSocket4 = Socket<IPv4, TCP>
typealias UDPSocket4 = Socket<IPv4, UDP>
typealias TCPSocket6 = Socket<IPv6, TCP>
typealias UDPSocket6 = Socket<IPv6, UDP>

class Socket<T: IPType, P: SocketProtocolType>: SocketType {
    
    var fd: FileDescriptorType
    
    init() {
        self.fd = FileDescriptor(socket(T.rawFamilyValue, P.rawStreamValue, P.rawProtocolValue))
    }
    
    init(fd: FileDescriptor) {
        self.fd = fd
    }
    
    init(fdRaw: FileDescriptorRawType) {
        self.fd = FileDescriptor(fdRaw)
    }
    
    deinit {
        do {
           try close()
        }catch {
            // close error
        }
    }

}

extension Socket: Readable {
    
    func read(size: Int) throws -> [Byte] {
        return try recv(size)
    }
    
    func recv(size: Int, flags: Int = 0) throws -> [Byte] {
        let buffer = UnsafeMutablePointer<Byte>.alloc(size)
        defer {
            buffer.dealloc(size)
        }
        let res = RECV(fd.raw, buffer, size, Int32(flags))
        guard res >= 0 else {
            throw SocketError.errno()
        }
        var data = [Byte](count: size, repeatedValue: 0)
        memcpy(&data, buffer, data.count)
        return data
    }
    
}

extension Socket: Writable {
    
    func write(buffer: [Byte]) throws {
        try send(buffer)
    }
    
    func send(buffer: [Byte], flags: Int = 0) throws {
        let res = SEND(fd.raw, buffer, buffer.count, Int32(flags))
        guard res >= 0 else {
            throw SocketError.errno()
        }
    }

}

extension Socket: Closable {
    
    func close() throws {
        CLOSE(fd.raw)
        fd = FileDescriptor(nilLiteral: ())
    }
    
}


extension Socket {
    
    func bind(ip: T) throws {
        var sockAddr = ip.sockAddr.general
        let res = BIND(fd.raw, &sockAddr, socklen_t(sizeofValue(sockAddr)))
        guard res >= 0 else {
            throw SocketError.errno()
        }
    }
    
    func listen(backlog: Int = Int(SOMAXCONN)) throws {
        let res = LISTEN(fd.raw, Int32(backlog))
        guard res >= 0 else {
            throw SocketError.errno()
        }
    }
    
    func accept() throws -> Socket {
        var addr: sockaddr?
        var socklen = socklen_t(sizeofValue(addr))
        let res = withUnsafePointers(&addr, &socklen) {
            return ACCEPT(fd.raw, UnsafeMutablePointer($0), UnsafeMutablePointer($1))
        }
        guard res >= 0 else {
            throw SocketError.errno()
        }
        return Socket(fdRaw: res)
    }
    
}
