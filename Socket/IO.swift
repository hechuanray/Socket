//
//  IO.swift
//  Socket
//
//  Created by LEI on 3/21/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

typealias Byte = UInt8

protocol Readable {
    func read(size: Int) throws -> [Byte]
}

protocol Writable {
    func write(buffer: [Byte]) throws
}

protocol Closable {
    func close() throws
}
